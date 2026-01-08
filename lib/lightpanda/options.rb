# frozen_string_literal: true

module Lightpanda
  class Options
    DEFAULT_TIMEOUT = ENV.fetch("LIGHTPANDA_DEFAULT_TIMEOUT", 5).to_i
    DEFAULT_PROCESS_TIMEOUT = ENV.fetch("LIGHTPANDA_PROCESS_TIMEOUT", 10).to_i
    DEFAULT_HOST = "127.0.0.1"
    DEFAULT_PORT = 9222
    DEFAULT_WINDOW_SIZE = [1024, 768].freeze

    attr_accessor :host, :port, :timeout, :process_timeout, :window_size, :browser_path, :headless
    attr_writer :ws_url

    def initialize(options = {})
      @host = options.fetch(:host, DEFAULT_HOST)
      @port = options.fetch(:port, DEFAULT_PORT)
      @timeout = options.fetch(:timeout, DEFAULT_TIMEOUT)
      @process_timeout = options.fetch(:process_timeout, DEFAULT_PROCESS_TIMEOUT)
      @window_size = options.fetch(:window_size, DEFAULT_WINDOW_SIZE)
      @browser_path = options[:browser_path]
      @headless = options.fetch(:headless, true)
      @ws_url = options[:ws_url]
    end

    def ws_url
      @ws_url || "ws://#{host}:#{port}/"
    end

    def ws_url?
      !@ws_url.nil?
    end

    def to_h
      {
        host: host,
        port: port,
        timeout: timeout,
        process_timeout: process_timeout,
        window_size: window_size,
        browser_path: browser_path,
        headless: headless,
        ws_url: ws_url,
      }
    end
  end
end
