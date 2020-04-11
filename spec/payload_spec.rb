require "spec_helper"

RSpec.describe TappingDevice::Payload do
  let(:device) { TappingDevice.new }
  let(:stan) { Student.new("Stan", 25) }
  subject do
    device.tap_init!(Student)
    stan
    device.calls.first
  end

  it "supports payload attributes as methods" do
    expect(subject.receiver).to eq(Student)
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
           from: #{__FILE__}:5
           <= {name: "Stan", age: 25}
           => #{stan.to_s}
       MSG
      )
    end
    describe "inspect:" do
      subject do
        TappingDevice::Payload.init({
          method_name: :foo,
          defined_class: Student,
          arguments: [stan],
          return_value: { arg: stan },
          filepath: "location",
          line_number: 5
        })
      end
      context "when true" do
        it "shows objects with #inspect" do
          expect(subject.detail_call_info(inspect: true)).to eq(
           <<~MSG
           :foo # Student
               from: location:5
               <= [#{stan.inspect}]
               => {arg: #{stan.inspect}}

           MSG
          )
        end
      end
      context "when false (default)" do
        it "shows objects with to_s" do
          expect(subject.detail_call_info(inspect: false)).to match(
           <<~MSG
           :foo # Student
               from: location:5
               <= [#{stan.to_s}]
               => {arg: #{stan.to_s}}

           MSG
          )
        end
      end
    end
  end

  describe "#method_object" do
    it "returns correct method object" do
      expect(subject.method_object.name).to eq(:initialize)
      expect(subject.method_object.owner).to eq(Student)
    end
  end

  describe "#method_name_and_location" do
    it "returns method's name and where it's called" do
      expect(subject.method_name_and_location).to match(/initialize from: .+\/tapping_device\/spec\/payload_spec.rb:\d/)
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
