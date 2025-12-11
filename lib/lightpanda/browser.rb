# frozen_string_literal: true

require "forwardable"

module Lightpanda
  class Browser
    extend Forwardable

    attr_reader :options, :process, :client, :target_id, :session_id

    delegate %i[on off] => :client

    def initialize(options = {})
      @options = Options.new(options)
      @process = nil
      @client = nil
      @target_id = nil
      @session_id = nil
      @started = false
      @page_events_enabled = false

      start
    end

    def start
      return if @started

      if @options.ws_url?
        @client = Client.new(@options.ws_url, @options)
      else
        @process = Process.new(@options)
        @process.start
        @client = Client.new(@process.ws_url, @options)
      end

      create_page

      @started = true
    end

    def create_page
      result = @client.command("Target.createTarget", { url: "about:blank" })
      @target_id = result["targetId"]

      attach_result = @client.command("Target.attachToTarget", { targetId: @target_id, flatten: true })
      @session_id = attach_result["sessionId"]
    end

    def restart
      quit
      start
    end

    def quit
      @client&.close
      @process&.stop
      @client = nil
      @process = nil
      @started = false
    end

    def command(method, **params)
      @client.command(method, params)
    end

    def page_command(method, **params)
      @client.command(method, params, session_id: @session_id)
    end

    def go_to(url, wait: true)
      enable_page_events

      if wait
        loaded = Concurrent::Event.new

        handler = proc { loaded.set }
        @client.on("Page.loadEventFired", &handler)

        result = page_command("Page.navigate", url: url)

        loaded.wait(@options.timeout)

        @client.off("Page.loadEventFired", handler)

        result
      else
        page_command("Page.navigate", url: url)
      end
    end
    alias goto go_to

    def enable_page_events
      return if @page_events_enabled

      page_command("Page.enable")
      @page_events_enabled = true
    end

    def back
      page_command("Page.navigateToHistoryEntry", entryId: current_entry_id - 1)
    end

    def forward
      page_command("Page.navigateToHistoryEntry", entryId: current_entry_id + 1)
    end

    def refresh
      page_command("Page.reload")
    end
    alias reload refresh

    def current_url
      evaluate("window.location.href")
    end

    def title
      evaluate("document.title")
    end

    def body
      evaluate("document.documentElement.outerHTML")
    end
    alias html body

    def evaluate(expression)
      response = page_command("Runtime.evaluate", expression: expression, returnByValue: true, awaitPromise: true)

      handle_evaluate_response(response)
    end

    def execute(expression)
      page_command("Runtime.evaluate", expression: expression, returnByValue: false, awaitPromise: false)
      nil
    end

    def css(selector)
      node_ids = page_command("DOM.querySelectorAll", nodeId: document_node_id, selector: selector)
      node_ids["nodeIds"] || []
    end

    def at_css(selector)
      result = page_command("DOM.querySelector", nodeId: document_node_id, selector: selector)

      result["nodeId"]
    end

    def screenshot(path: nil, format: :png, quality: nil, full_page: false, encoding: :binary)
      params = { format: format.to_s }
      params[:quality] = quality if quality && format == :jpeg

      if full_page
        metrics = page_command("Page.getLayoutMetrics")
        content_size = metrics["contentSize"]

        params[:clip] = {
          x: 0,
          y: 0,
          width: content_size["width"],
          height: content_size["height"],
          scale: 1
        }
      end

      result = page_command("Page.captureScreenshot", **params)
      data = result["data"]

      if encoding == :base64
        data
      else
        decoded = Base64.decode64(data)

        if path
          File.binwrite(path, decoded)
          path
        else
          decoded
        end
      end
    end

    def network
      @network ||= Network.new(self)
    end

    def cookies
      @cookies ||= Cookies.new(self)
    end

    private

    def document_node_id
      result = page_command("DOM.getDocument")

      result.dig("root", "nodeId")
    end

    def current_entry_id
      result = page_command("Page.getNavigationHistory")

      result["currentIndex"]
    end

    def handle_evaluate_response(response)
      raise JavaScriptError, response if response["exceptionDetails"]

      result = response["result"]
      return nil if result["type"] == "undefined"

      result["value"]
    end
  end
end
