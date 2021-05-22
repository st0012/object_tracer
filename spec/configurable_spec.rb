require "spec_helper"

RSpec.describe ObjectTracer do
  include ObjectTracer::Trackable

  around do |example|
    example.run

    ObjectTracer::Configuration::DEFAULTS.each do |key, value|
      ObjectTracer.config[key] = value
    end
  end

  it "has default config values" do
    expect(ObjectTracer.config[:filter_by_paths]).to eq([])
    expect(ObjectTracer.config[:exclude_by_paths]).to eq([])
    expect(ObjectTracer.config[:with_trace_to]).to eq(50)
    expect(ObjectTracer.config[:event_type]).to eq(:return)
    expect(ObjectTracer.config[:hijack_attr_methods]).to eq(false)
    expect(ObjectTracer.config[:track_as_records]).to eq(false)
  end

  it "passes the values to individual devices" do
    ObjectTracer.config[:event_type] = :call

    device = tap_on!(Student.new("Stan", 26))

    expect(device.options[:event_type]).to eq(:call)
  end
end
