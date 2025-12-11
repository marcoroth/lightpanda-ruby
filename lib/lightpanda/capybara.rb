# frozen_string_literal: true

require "capybara"
require "lightpanda"

require_relative "capybara/driver"
require_relative "capybara/node"

module Lightpanda
  module Capybara
    class << self
      def configure
        yield(configuration) if block_given?
      end

      def configuration
        @configuration ||= Configuration.new
      end
    end

    class Configuration
      attr_accessor :host, :port, :timeout, :headless, :browser_path

      def initialize
        @host = "127.0.0.1"
        @port = 9222
        @timeout = 5
        @headless = true
        @browser_path = nil
      end

      def to_h
        {
          host: host,
          port: port,
          timeout: timeout,
          browser_path: browser_path
        }
      end
    end
  end
end

Capybara.register_driver(:lightpanda) do |app|
  Lightpanda::Capybara::Driver.new(app, Lightpanda::Capybara.configuration.to_h)
end
