require "spec_helper"

RSpec.describe TappingDevice::Payload do
  include TappingDevice::Trackable

  let(:stan) { Student.new("Stan", 25) }
  subject do
    device = tap_init!(Student)
    stan
    device.calls.first
  end

  it "supports payload attributes as methods" do
    expect(subject.receiver).to eq(Student)
    expect(subject.arguments).to eq({ name: "Stan", age: 25 })
    expect(subject.keys).to match_array(
      [
        :target,
        :receiver,
        :method_name,
        :method_object,
        :arguments,
        :return_value,
        :filepath,
        :line_number,
        :defined_class,
        :trace,
        :tag,
        :tp,
        :is_private_call?
      ]
    )
  end

  describe "#method_object" do
    it "returns correct method object" do
      expect(subject.method_object.name).to eq(:initialize)
      expect(subject.method_object.owner).to eq(Student)
    end
  end
end
