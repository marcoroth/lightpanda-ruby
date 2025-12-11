# frozen_string_literal: true

require "capybara"

module Lightpanda
  module Capybara
    class Driver < ::Capybara::Driver::Base
      attr_reader :app, :options

      def initialize(app, options = {})
        @app = app
        @options = options
        @browser = nil
      end

      def browser
        @browser ||= Lightpanda::Browser.new(@options)
      end

      def visit(url)
        browser.go_to(url)
      end

      def current_url
        browser.current_url
      end

      def html
        browser.body
      end
      alias body html

      def title
        browser.title
      end

      def find_xpath(selector)
        nodes = browser.evaluate(<<~JS)
          (function() {
            var result = document.evaluate(
              #{selector.inspect},
              document,
              null,
              XPathResult.ORDERED_NODE_SNAPSHOT_TYPE,
              null
            );
            var nodes = [];
            for (var i = 0; i < result.snapshotLength; i++) {
              nodes.push(result.snapshotItem(i));
            }
            return nodes;
          })()
        JS

        wrap_nodes(nodes || [])
      end

      def find_css(selector)
        count = browser.evaluate("document.querySelectorAll(#{selector.inspect}).length")

        return [] if count.nil? || count.zero?

        (0...count).map do |index|
          Node.new(self, { selector: selector, index: index }, index)
        end
      end

      def evaluate_script(script, *_args)
        browser.evaluate(script)
      end

      def execute_script(script, *_args)
        browser.execute(script)
        nil
      end

      def reset!
        browser.go_to("about:blank")
      rescue StandardError
        nil
      end

      def quit
        @browser&.quit
        @browser = nil
      end

      def needs_server?
        true
      end

      def wait?
        true
      end

      def invalid_element_errors
        [Lightpanda::NodeNotFoundError, Lightpanda::NoExecutionContextError]
      end

      private

      def wrap_nodes(nodes)
        return [] unless nodes.is_a?(Array)

        nodes.map.with_index do |node_data, index|
          Node.new(self, node_data, index)
        end
      end
    end
  end
end
