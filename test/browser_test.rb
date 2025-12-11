# frozen_string_literal: true

require_relative "test_helper"

class BrowserTest < Minitest::Spec
  def setup
    @browser = Lightpanda::Browser.new
  end

  def teardown
    @browser.quit
  end

  it "navigates to a URL" do
    @browser.go_to("https://example.com")

    assert_equal "https://example.com/", @browser.current_url
  end

  it "returns the page title" do
    @browser.go_to("https://example.com")

    assert_equal "Example Domain", @browser.title
  end

  it "returns the page HTML" do
    @browser.go_to("https://example.com")

    assert_includes @browser.body, "<h1>Example Domain</h1>"
  end

  it "evaluates JavaScript and returns the result" do
    @browser.go_to("https://example.com")

    result = @browser.evaluate("1 + 1")

    assert_equal 2, result
  end

  it "can query the DOM with JavaScript" do
    @browser.go_to("https://example.com")

    result = @browser.evaluate("document.querySelector('h1').textContent")

    assert_equal "Example Domain", result
  end

  it "sends CDP commands" do
    version = @browser.command("Browser.getVersion")

    assert_equal "1.3", version["protocolVersion"]
    assert_includes version["product"], "Chrome"
  end
end
