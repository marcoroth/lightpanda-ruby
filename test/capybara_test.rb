# frozen_string_literal: true

require_relative "test_helper"
require "capybara/dsl"
require "lightpanda/capybara"

class CapybaraTest < Minitest::Spec
  include Capybara::DSL

  def setup
    @port = find_available_port

    Capybara.register_driver(:lightpanda_test) do |app|
      Lightpanda::Capybara::Driver.new(app, port: @port)
    end

    Capybara.default_driver = :lightpanda_test
  end

  def teardown
    page.driver.quit if page.driver.respond_to?(:quit)
    Capybara.reset_sessions!
    Capybara.use_default_driver
  end

  it "visits a page and gets the current URL" do
    visit "https://example.com"

    assert_equal "https://example.com/", current_url
  end

  it "finds elements by CSS" do
    visit "https://example.com"

    h1 = find("h1")

    assert_equal "Example Domain", h1.text
  end

  it "checks element visibility" do
    visit "https://example.com"

    h1 = find("h1")

    assert h1.visible?
  end

  it "finds multiple elements" do
    visit "https://example.com"

    paragraphs = all("p")

    assert_equal 2, paragraphs.count
  end

  it "gets element attributes" do
    visit "https://example.com"

    link = find("a")

    assert_includes link[:href], "iana.org/domains/example"
  end

  it "gets page HTML" do
    visit "https://example.com"

    assert_includes page.html, "Example Domain"
  end

  it "checks for CSS selectors with has_css?" do
    visit "https://example.com"

    assert has_css?("h1")
    refute has_css?("h2")
  end
end
