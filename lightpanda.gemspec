# frozen_string_literal: true

require_relative "lib/lightpanda/version"

Gem::Specification.new do |spec|
  spec.name = "lightpanda"
  spec.version = Lightpanda::VERSION
  spec.authors = ["Marco Roth"]
  spec.email = ["marco.roth@intergga.ch"]

  spec.summary = "Ruby client for the Lightpanda headless browser via Chrome DevTools Protocol."
  spec.description = <<~DESC.tr("\n", " ").strip
    High-level Ruby API to control the Lightpanda browser. Lightpanda is a fast,
    lightweight headless browser built for web automation, AI agents, and scraping.
    This gem provides CDP-based browser control similar to Ferrum.
  DESC

  spec.homepage = "https://github.com/marcoroth/lightpanda-ruby"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/marcoroth/lightpanda-ruby"
  spec.metadata["changelog_uri"] = "https://github.com/marcoroth/lightpanda-ruby/releases"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir[
    "lib/**/*.rb",
    "LICENSE.txt",
    "README.md"
  ]
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "addressable", "~> 2.8"
  spec.add_dependency "concurrent-ruby", "~> 1.3"
  spec.add_dependency "websocket-driver", "~> 0.8"
end
