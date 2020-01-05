require "spec_helper"

RSpec.describe TappingDevice::Payload do
  let(:device) { TappingDevice.new }
  subject do
    device.tap_init!(Student)
    Student.new("Stan", 25)
    device.calls.first
  end

  it "supports payload attributes as methods" do
    expect(subject.receiver).to be_is_a(Student)
    expect(subject.arguments).to eq({ name: "Stan", age: 25 })
    expect(subject.keys).to eq(
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
        :tp
      ]
    )
  end

  describe "#detail_call_info" do
    it "returns method_name, arugments, return_value, and filepath" do
      expect(subject.detail_call_info).to match(
       <<~MSG
       :initialize # Student
         <= {:name=>"Stan", :age=>25}
         => 25
         FROM #{__FILE__}:7
       MSG
      )
    end
  end

  describe "#method_name_and_location" do
    it "returns method's name and where it's called" do
      expect(subject.method_name_and_location).to match(/initialize FROM .+\/tapping_device\/spec\/payload_spec.rb:\d/)
    end
  end
  describe "#method_name_and_arguments" do
    it "returns method's name and its arguments" do
      expect(subject.method_name_and_arguments).to match("initialize <= {:name=>\"Stan\", :age=>25}")
    end
  end
  describe "#passed_at" do
    subject { "Stan" }
    before do
      device.tap_passed!(subject)
    end

    it "returns nil if the payload is not from `tap_passed!`" do
      new_device = TappingDevice.new
      new_device.tap_init!(Student)
      Student.new("Stan", 25)

      expect(new_device.calls.first.passed_at).to eq(nil)
    end

    it "returns the argument name, method name and location" do
      Student.new(subject, 25); line = __LINE__

      payload = device.calls.first
      expect(payload.passed_at).to eq(
        <<~MSG.chomp
        Passed as 'name' in method ':initialize'
          at #{__FILE__}:#{line}
        MSG
      )
    end

    context "with_method_head: true" do
      it "returns method definition's head as well" do
        Student.new(subject, 25); line = __LINE__

        payload = device.calls.first
        expect(payload.passed_at(with_method_head: true)).to eq(
          <<~MSG.chomp
          Passed as 'name' in method ':initialize'
            > def initialize(name, age)
            at #{__FILE__}:#{line}
          MSG
        )
      end
    end
  end
end
