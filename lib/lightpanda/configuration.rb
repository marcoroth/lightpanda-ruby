# frozen_string_literal: true

module Lightpanda
  class Configuration
    attr_accessor :binary_path

    def initialize
      @binary_path = nil
    end
  end
end
