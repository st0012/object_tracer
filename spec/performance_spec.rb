require "spec_helper"
require 'benchmark'

RSpec.describe TappingDevice do
  let(:devices) do
    devices = []
    100.times { devices << described_class.new }
    devices
  end

  it "takes very short time even with multiple tapping enabled" do
    time = Benchmark.realtime do
      devices.each do |device|
        s = Student.new("foo", 10)
        device.tap_on!(s)
        10.times { s.name }

        expect(device.calls.count).to eq(10)
      end
    end
    devices.each { |d| d.stop! }
    expect(time).to be <= 1
  end
end
