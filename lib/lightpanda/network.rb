# frozen_string_literal: true

module Lightpanda
  class Network
    attr_reader :browser

    def initialize(browser)
      @browser = browser
      @traffic = []
      @enabled = false
    end

    def enable
      return if @enabled

      browser.command("Network.enable")
      subscribe
      @enabled = true
    end

    def disable
      return unless @enabled

      browser.command("Network.disable")
      @enabled = false
    end

    def traffic
      @traffic.dup
    end

    def clear
      @traffic.clear
    end

    def wait_for_idle(timeout: 5, connections: 0)
      started_at = Time.now

      while Time.now - started_at < timeout
        pending = @traffic.count { |t| t[:response].nil? }
        return true if pending <= connections

        sleep 0.1
      end

      false
    end

    private

    def subscribe
      browser.on("Network.requestWillBeSent") do |params|
        @traffic << {
          request_id: params["requestId"],
          url: params.dig("request", "url"),
          method: params.dig("request", "method"),
          timestamp: params["timestamp"],
          response: nil
        }
      end

      browser.on("Network.responseReceived") do |params|
        request = @traffic.find { |t| t[:request_id] == params["requestId"] }

        next unless request

        request[:response] = {
          status: params.dig("response", "status"),
          headers: params.dig("response", "headers"),
          mime_type: params.dig("response", "mimeType")
        }
      end
    end
  end
end
