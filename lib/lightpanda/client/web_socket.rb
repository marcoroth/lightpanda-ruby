# frozen_string_literal: true

require "json"
require "socket"
require "websocket/driver"

module Lightpanda
  class Client
    class WebSocket
      attr_reader :url, :messages

      def initialize(url, options)
        @url = url
        @options = options
        @socket = nil
        @driver = nil
        @thread = nil
        @status = :closed
        @messages = Queue.new

        connect
      end

      def send_message(message)
        raise DeadBrowserError, "WebSocket is not open" unless @status == :open

        @driver.text(message)
      end

      def close
        return if @status == :closed

        @status = :closing
        @driver&.close
        @thread&.kill
        @socket&.close
        @status = :closed
      end

      def closed?
        @status == :closed
      end

      def open?
        @status == :open
      end

      def write(data)
        @socket.write(data)
      rescue Errno::EPIPE, Errno::ECONNRESET, IOError
        @status = :closed
      end

      private

      def connect
        uri = URI.parse(@url)

        @socket = connect_with_retry(uri.host, uri.port)
        @driver = ::WebSocket::Driver.client(self)

        setup_callbacks

        @driver.start

        read_handshake_response
        start_reader_thread
      end

      def connect_with_retry(host, port, retries: 10, delay: 0.1)
        retries.times do |i|
          return TCPSocket.new(host, port)
        rescue Errno::ECONNREFUSED
          raise if i == retries - 1

          sleep delay
        end
      end

      def setup_callbacks
        @driver.on(:open) do
          @status = :open
        end

        @driver.on(:message) do |event|
          message = parse_message(event.data)
          @messages << message if message
        end

        @driver.on(:close) do
          @status = :closed
        end

        @driver.on(:error) do |event|
          @status = :error

          raise DeadBrowserError, "WebSocket error: #{event.message}"
        end
      end

      def start_reader_thread
        @thread = Thread.new do
          Thread.current.abort_on_exception = true

          loop do
            break if @status == :closed || @status == :closing

            begin
              ready = IO.select([@socket], nil, nil, 0.1)

              next unless ready

              data = @socket.readpartial(4096)
              @driver.parse(data)
            rescue EOFError, IOError, Errno::ECONNRESET
              @status = :closed
              break
            end
          end
        end
      end

      def read_handshake_response
        started_at = Time.now

        while @status != :open && Time.now - started_at < @options.timeout
          ready = IO.select([@socket], nil, nil, 0.1)

          next unless ready

          begin
            data = @socket.readpartial(4096)
            @driver.parse(data)
          rescue EOFError
            raise DeadBrowserError, "Connection closed during handshake"
          end
        end

        raise TimeoutError, "WebSocket connection timeout" unless @status == :open
      end

      def parse_message(data)
        JSON.parse(data)
      rescue JSON::ParserError => e
        warn "Failed to parse WebSocket message: #{e.message}"

        nil
      end
    end
  end
end
