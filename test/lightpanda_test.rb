# frozen_string_literal: true

require_relative "test_helper"

class LightpandaTest < Minitest::Spec
  it "has a version number" do
    refute_nil Lightpanda::VERSION
  end

  it "returns a configuration instance" do
    assert_kind_of Lightpanda::Configuration, Lightpanda.configuration
  end

  it "yields configuration in configure block" do
    yielded = nil

    Lightpanda.configure { |config| yielded = config }

    assert_equal Lightpanda.configuration, yielded
  end

  it "allows setting binary_path via configure" do
    original_path = Lightpanda.configuration.binary_path

    Lightpanda.configure do |config|
      config.binary_path = "/custom/path/lightpanda"
    end

    assert_equal "/custom/path/lightpanda", Lightpanda.configuration.binary_path
  ensure
    Lightpanda.configuration.binary_path = original_path
  end

  it "caches binary_path after first discovery" do
    Lightpanda.configuration.binary_path = nil

    path1 = Lightpanda::Binary.path
    path2 = Lightpanda::Binary.path

    assert_equal path1, path2
    assert_equal path1, Lightpanda.configuration.binary_path
  end
end
