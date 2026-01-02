# frozen_string_literal: true

require_relative "lightpanda/version"
require_relative "lightpanda/errors"
require_relative "lightpanda/options"
require_relative "lightpanda/binary"
require_relative "lightpanda/process"
require_relative "lightpanda/client"
require_relative "lightpanda/network"
require_relative "lightpanda/cookies"
require_relative "lightpanda/browser"

module Lightpanda
  class << self
    def new(**)
      Browser.new(**)
    end
  end
end
