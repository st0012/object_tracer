require "spec_helper"

RSpec.describe TappingDevice::Payload do
  subject do
    device = TappingDevice.new
    device.tap_init!(Student)
    Student.new("Stan", 25)
    device.calls.first
  end

  it "supports payload attributes as methods" do
    expect(subject.receiver).to be_is_a(Student)
    expect(subject.arguments).to eq([[:name, "Stan"], [:age, 25]])
    expect(subject.keys).to eq(
      [
        :receiver,
        :method_name,
        :arguments,
        :return_value,
        :filepath,
        :line_number,
        :defined_class,
        :trace,
        :tp
      ]
    )
  end

  describe "#what_and_where" do
    it "returns method's name and where it's called" do
      expect(subject.what_and_where).to match(/Method: :initialize, line: .+\/tapping_device\/spec\/payload_spec.rb:\d/)
    end
  end
end
