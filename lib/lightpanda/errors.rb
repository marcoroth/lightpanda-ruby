# frozen_string_literal: true

module Lightpanda
  class Error < StandardError; end

  class ProcessTimeoutError < Error; end
  class BinaryNotFoundError < Error; end
  class BinaryError < Error; end
  class UnsupportedPlatformError < Error; end

  class DeadBrowserError < Error; end
  class TimeoutError < Error; end

  class BrowserError < Error
    attr_reader :response

    def initialize(response)
      @response = response
      super(response["message"])
    end
  end

  class JavaScriptError < Error
    attr_reader :class_name, :message

    def initialize(response)
      @class_name = response.dig("exceptionDetails", "exception", "className")
      @message = response.dig("exceptionDetails", "exception",
                              "description") || response.dig("exceptionDetails", "text")

      super(@message)
    end
  end

  class NodeNotFoundError < Error; end
  class NoExecutionContextError < Error; end

  class NoSuchPageError < Error; end
  class StatusError < Error; end
end
