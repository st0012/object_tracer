require "spec_helper"
require 'benchmark'

RSpec.describe TappingDevice::Device do
  let(:devices) do
    devices = []
    100.times { devices << TappingDevice::Device.new }
    devices
  end

  after do
    devices.each(&:stop!)
  end

  context "without stop_when" do
    it "takes long time when tapping multiple devices" do
      time = Benchmark.realtime do
        devices.each do |device|
          s = Student.new("foo", 10)
          device.tap_on!(s)
          10.times { s.name }

          expect(device.calls.count).to eq(10)
        end
      end
      devices.each { |d| d.stop! }
      expect(time).to be_between(4, 10)
    end
  end

  context "with stop_when" do
    it "takes very short time when tapping multiple devices" do
      time = Benchmark.realtime do
        devices.each do |device|
          device.stop_when do
            device.calls.count == 10
          end

          s = Student.new("foo", 10)
          device.tap_on!(s)
          10.times { s.name }

          expect(device.calls.count).to eq(10)
        end
      end

      devices.each { |d| d.stop! }
      expect(time).to be_between(0, 1)
    end
  end
end
