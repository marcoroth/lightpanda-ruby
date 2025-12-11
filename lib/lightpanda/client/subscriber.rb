# frozen_string_literal: true

module Lightpanda
  class Client
    class Subscriber
      def initialize
        @subscriptions = Hash.new { |h, k| h[k] = [] }
        @mutex = Mutex.new
      end

      def subscribe(event, &block)
        @mutex.synchronize do
          @subscriptions[event] << block
        end
      end

      def unsubscribe(event, block = nil)
        @mutex.synchronize do
          if block
            @subscriptions[event].delete(block)
          else
            @subscriptions.delete(event)
          end
        end
      end

      def dispatch(event, params)
        callbacks = @mutex.synchronize { @subscriptions[event].dup }

        callbacks.each { |callback| callback.call(params) }
      end

      def subscribed?(event)
        @mutex.synchronize { @subscriptions.key?(event) && @subscriptions[event].any? }
      end

      def clear
        @mutex.synchronize { @subscriptions.clear }
      end
    end
  end
end
