# typed: false
require "spec_helper"

RSpec.describe TappingDevice do
  include TappingDevice::Trackable

  around do |example|
    example.run

    TappingDevice::Configurable::DEFAULTS.each do |key, value|
      TappingDevice.config[key] = value
    end
  end

  it "has default config values" do
    expect(TappingDevice.config[:filter_by_paths]).to eq([])
    expect(TappingDevice.config[:exclude_by_paths]).to eq([])
    expect(TappingDevice.config[:with_trace_to]).to eq(50)
    expect(TappingDevice.config[:event_type]).to eq(:return)
    expect(TappingDevice.config[:hijack_attr_methods]).to eq(false)
    expect(TappingDevice.config[:track_as_records]).to eq(false)
  end

  it "passes the values to individual devices" do
    TappingDevice.config[:event_type] = :call

    device = tap_on!(Student.new("Stan", 26))

    expect(device.options[:event_type]).to eq(:call)
  end
end
