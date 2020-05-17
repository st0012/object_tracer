require "spec_helper"

RSpec.describe TappingDevice::OutputPayload do
  let(:stan) { Student.new("Stan", 25) }
  subject do
    TappingDevice::OutputPayload.init({
      method_name: :foo,
      defined_class: Student,
      arguments: [stan],
      return_value: {arg: stan},
      filepath: "location",
      line_number: 5
    })
  end

  describe "#detail_call_info" do
    it "returns method_name, arugments, return_value, and filepath" do
      expect(subject.detail_call_info).to match(
        <<~MSG
       :foo # Student
           from: location:5
           <= [#{stan}]
           => {arg: #{stan.to_s}}

MSG
      )
    end
    describe "inspect:" do
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

  describe "#method_name_and_location" do
    it "returns method's name and where it's called" do
      expect(subject.method_name_and_location).to match(/:foo from: location:5/)
    end
  end
  describe "#method_name_and_arguments" do
    it "returns method's name and its arguments" do
      expect(subject.method_name_and_arguments).to match(/:foo <= \[#<Student.*>\]/)
    end
  end
  describe "#passed_at" do
    subject do
      name = "Stan"
      device = TappingDevice.new
      device.tap_passed!(name)
      Student.new(name, 25)
      described_class.init(device.calls.first)
    end

    it "returns nil if the payload is not from `tap_passed!`" do
      new_device = TappingDevice.new
      new_device.tap_init!(Student)
      Student.new("Stan", 25)

      subject = described_class.init(new_device.calls.first)
      expect(subject.passed_at).to eq(nil)
    end

    it "returns the argument name, method name and location" do
      expect(subject.passed_at).to eq(
        "Passed as 'name' in 'Student#:initialize' at #{__FILE__}:73"
      )
    end

    context "with_method_head: true" do
      it "returns method definition's head as well" do
        expect(subject.passed_at(with_method_head: true)).to eq(
          <<~MSG.chomp
          Passed as 'name' in 'Student#:initialize' at #{__FILE__}:73
            > def initialize(name, age)
          MSG
        )
      end
    end
  end
end
