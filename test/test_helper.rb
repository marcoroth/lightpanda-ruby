# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require "lightpanda"
require "maxitest/autorun"

system("pkill -f lightpanda 2>/dev/null")
sleep 0.5
