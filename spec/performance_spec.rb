require "spec_helper"
require 'benchmark'

RSpec.describe ObjectTracer do
  include ObjectTracer::Trackable

  it "takes very short time even with multiple tapping enabled" do
    time = Benchmark.realtime do
      100.times do
        s = Student.new("foo", 10)
        device = tap_on!(s)
        10.times { s.name }

        expect(device.calls.count).to eq(10)
        device.stop!
      end
    end
    expect(time).to be <= 1
  end
end
