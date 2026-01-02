# Lightpanda for Ruby

Ruby client for the [Lightpanda](https://lightpanda.io) headless browser via CDP (Chrome DevTools Protocol).

Lightpanda is a fast, lightweight headless browser built for web automation, AI agents, and scraping. This gem provides a high-level Ruby API to control Lightpanda, similar to [Ferrum](https://github.com/rubycdp/ferrum) for Chrome.

## Features

- High-level browser automation API
- CDP (Chrome DevTools Protocol) client
- Capybara driver included
- Auto-downloads Lightpanda binary if not found
- Ruby 3.2+

## Installation

Add to your Gemfile:

```ruby
gem "lightpanda"
```

Or install directly:

```bash
gem install lightpanda
```

The Lightpanda binary will be automatically downloaded on first use if not found in your `PATH`.

## Usage

### Basic Browser Control

**Create a browser instance**

```ruby
require "lightpanda"

browser = Lightpanda::Browser.new
```

**Navigate to a page**

```ruby
browser.go_to("https://example.com")
```

**Get page info**

```ruby
browser.current_url  # => "https://example.com/"
browser.title        # => "Example Domain"
browser.body         # => "<html>...</html>"
```

**Evaluate JavaScript**

```ruby
browser.evaluate("1 + 1")                                    # => 2
browser.evaluate("document.querySelector('h1').textContent") # => "Example Domain"
```

**Execute JavaScript (no return value)**

```ruby
browser.execute("console.log('Hello from Lightpanda!')")
```

**Send raw CDP commands**

```ruby
browser.command("Browser.getVersion")
# => {"protocolVersion"=>"1.3", "product"=>"Chrome/124.0.6367.29", ...}
```

**Clean up**

```ruby
browser.quit
```

### Configuration Options

```ruby
browser = Lightpanda.new(
  host: "127.0.0.1",        # CDP server host
  port: 9222,               # CDP server port
  timeout: 5,               # Command timeout in seconds
  process_timeout: 10,      # Process startup timeout
  window_size: [1024, 768],
  browser_path: "/path/to/lightpanda"  # Custom binary path
)
```

### Binary Management

**Get binary path (downloads if needed)**

```ruby
Lightpanda::Binary.path  # => "/Users/you/.cache/lightpanda/lightpanda"
```

**Get version**

```ruby
Lightpanda::Binary.version  # => "7c976209"
```

**Run arbitrary commands**

```ruby
result = Lightpanda::Binary.run("--help")
result.stdout   # => ""
result.stderr   # => "usage: lightpanda command [options] [URL]..."
result.success? # => false (help exits with 1)
result.output   # => returns stderr if stdout empty
```

**Fetch a URL directly (no browser instance needed)**

```ruby
html = Lightpanda::Binary.fetch("https://example.com")
# => "<!DOCTYPE html><html>..."
```

### Capybara Integration

**Basic usage**

```ruby
require "lightpanda/capybara"

Capybara.default_driver = :lightpanda

visit "https://example.com"
find("h1").text  # => "Example Domain"
all("p").count   # => 2
```

**Configuration**

```ruby
Lightpanda::Capybara.configure do |config|
  config.host = "127.0.0.1"
  config.port = 9222
  config.timeout = 5
end
```

**In tests**

```ruby
class FeatureTest < Minitest::Spec
  include Capybara::DSL

  def setup
    Capybara.default_driver = :lightpanda
  end

  def teardown
    Capybara.reset_sessions!
  end

  it "shows the homepage" do
    visit "https://example.com"
    assert find("h1").text == "Example Domain"
  end
end
```

## Environment Variables

- `LIGHTPANDA_PATH` - Custom path to Lightpanda binary
- `LIGHTPANDA_DEFAULT_TIMEOUT` - Default command timeout (default: 5)
- `LIGHTPANDA_PROCESS_TIMEOUT` - Process startup timeout (default: 10)

## Limitations

Lightpanda is a lightweight browser with some limitations compared to Chrome:

- Single browser context only (no incognito/multi-context)
- No XPath support (`XPathResult` not implemented)
- Limited CDP command coverage

## Development

```bash
bundle install
bundle exec mtest
```

## License

MIT License. See [LICENSE.txt](LICENSE.txt).
