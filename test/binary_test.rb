# frozen_string_literal: true

require_relative "test_helper"

class BinaryTest < Minitest::Spec
  it "returns the binary path" do
    path = Lightpanda::Binary.path

    assert path.end_with?("lightpanda")
    assert File.executable?(path)
  end

  it "returns the version" do
    version = Lightpanda::Binary.version

    refute_empty version
  end

  it "runs commands and returns a result" do
    result = Lightpanda::Binary.run("version")

    assert_kind_of Lightpanda::Binary::Result, result
    assert result.success?
    assert_equal 0, result.exit_code
  end

  it "fetches a URL and returns HTML" do
    html = Lightpanda::Binary.fetch("https://example.com")

    assert_includes html, "<!DOCTYPE html>"
    assert_includes html, "Example Domain"
  end

  it "provides output helper for result" do
    result = Lightpanda::Binary.run("version")

    refute_empty result.output
  end

  it "raises BinaryError on fetch failure" do
    assert_raises(Lightpanda::BinaryError) do
      Lightpanda::Binary.fetch("not-a-valid-url")
    end
  end
end
