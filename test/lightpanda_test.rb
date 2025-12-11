# frozen_string_literal: true

require_relative "test_helper"

class LightpandaTest < Minitest::Spec
  it "has a version number" do
    refute_nil Lightpanda::VERSION
  end
end
