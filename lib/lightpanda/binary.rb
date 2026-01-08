# frozen_string_literal: true

require "fileutils"
require "net/http"
require "open3"
require "rbconfig"
require "uri"

module Lightpanda
  class Binary
    Result = Struct.new(:stdout, :stderr, :status, keyword_init: true) do
      def success?
        status.success?
      end

      def exit_code
        status.exitstatus
      end

      def output
        stdout.empty? ? stderr : stdout
      end
    end

    GITHUB_RELEASE_URL = "https://github.com/lightpanda-io/browser/releases/download/nightly"

    PLATFORMS = {
      ["x86_64", "linux"] => "lightpanda-x86_64-linux",
      ["aarch64", "darwin"] => "lightpanda-aarch64-macos",
      ["arm64", "darwin"] => "lightpanda-aarch64-macos",
    }.freeze

    class << self
      def path
        find_or_download
      end

      def find_or_download
        find || download
      end

      def run(*)
        binary = find_or_download
        stdout, stderr, status = Open3.capture3(binary, *)

        Result.new(stdout: stdout, stderr: stderr, status: status)
      rescue Errno::ENOENT
        raise BinaryNotFoundError, "Lightpanda binary not found"
      end

      def exec(*)
        binary = find_or_download

        Kernel.exec(binary, *)
      end

      def fetch(url)
        result = run("fetch", "--dump", url)
        raise BinaryError, result.stderr unless result.success?

        result.stdout
      end

      def version
        result = run("version")
        result.output.strip
      end

      def find
        env_path = ENV.fetch("LIGHTPANDA_PATH", nil)
        return env_path if env_path && File.executable?(env_path)

        path_binary = find_in_path
        return path_binary if path_binary

        default_path = default_binary_path
        return default_path if File.executable?(default_path)

        nil
      end

      def download
        binary_name = platform_binary
        url = "#{GITHUB_RELEASE_URL}/#{binary_name}"
        destination = default_binary_path

        FileUtils.mkdir_p(File.dirname(destination))

        download_file(url, destination)
        FileUtils.chmod(0o755, destination)

        destination
      end

      def platform_binary
        arch = normalize_arch(RbConfig::CONFIG["host_cpu"])
        os = normalize_os(RbConfig::CONFIG["host_os"])

        PLATFORMS[[arch, os]] || raise(UnsupportedPlatformError, "Unsupported platform: #{arch}-#{os}")
      end

      def default_binary_path
        cache_dir = ENV.fetch("XDG_CACHE_HOME") { File.expand_path("~/.cache") }

        File.join(cache_dir, "lightpanda", "lightpanda")
      end

      private

      def find_in_path
        ENV["PATH"].to_s.split(File::PATH_SEPARATOR).each do |dir|
          path = File.join(dir, "lightpanda")

          return path if File.executable?(path) && native_binary?(path)
        end

        nil
      end

      def native_binary?(path)
        header = File.binread(path, 4)

        return true if elf_binary?(header)
        return true if mach_o_binary?(header)

        false
      rescue StandardError
        false
      end

      def elf_binary?(header)
        header.start_with?("\x7FELF")
      end

      def mach_o_binary?(header)
        header.start_with?("\xCF\xFA\xED\xFE")
      end

      def normalize_arch(arch)
        case arch
        when /x86_64|amd64/i then "x86_64"
        when /aarch64|arm64/i then "aarch64"
        else arch
        end
      end

      def normalize_os(os)
        case os
        when /darwin|mac/i then "darwin"
        when /linux/i then "linux"
        else os
        end
      end

      def download_file(url, destination)
        uri = URI.parse(url)

        follow_redirects(uri, destination)
      end

      def follow_redirects(uri, destination, limit = 10)
        raise BinaryNotFoundError, "Too many redirects" if limit.zero?

        Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https") do |http|
          request = Net::HTTP::Get.new(uri)

          http.request(request) do |response|
            case response
            when Net::HTTPSuccess
              File.open(destination, "wb") do |file|
                response.read_body { |chunk| file.write(chunk) }
              end
            when Net::HTTPRedirection
              follow_redirects(URI.parse(response["location"]), destination, limit - 1)
            else
              raise BinaryNotFoundError, "Failed to download binary: #{response.code} #{response.message}"
            end
          end
        end
      end
    end
  end
end
