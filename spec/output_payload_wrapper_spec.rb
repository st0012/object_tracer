require "spec_helper"

RSpec.describe TappingDevice::Output::PayloadWrapper do
  include TappingDevice::Trackable

  let(:stan) { Student.new("Stan", 25) }
  let(:options) { {colorize: false} }
  subject do
    payload = TappingDevice::Payload.new(
      method_name: :foo,
      defined_class: Student,
      arguments: [stan],
      return_value: {arg: stan},
      filepath: "location",
      line_number: 5,
      target: stan,
      receiver: stan,
      method_object: nil,
      trace: [],
      tag: nil,
      tp: nil,
      is_private_call: false
    )
    described_class.new(payload)
  end

  describe "#detail_call_info" do
    describe "inspect:" do
      context "when true" do
        let(:options) { {colorize: false, inspect: true} }

        it "shows objects with #inspect" do
          expect(subject.detail_call_info(options)).to eq(
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
        let(:options) { {colorize: false, inspect: false} }

        it "shows objects with to_s" do
          expect(subject.detail_call_info(options)).to match(
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
      device = tap_passed!(name)
      Student.new(name, 25)
      described_class.new(device.calls.first)
    end

    it "returns nil if the payload is not from `tap_passed!`" do
      new_device = tap_init!(Student)
      Student.new("Stan", 25)

      subject = described_class.new(new_device.calls.first)
      expect(subject.passed_at).to eq(nil)
    end

    it "returns the argument name, method name and location" do
      expect(subject.passed_at(options)).to match(
        /Passed as :name in 'Student#:initialize \(private\)' at #{__FILE__}:\d+/
      )
    end

    context "with_method_head: true" do
      let(:options) { {colorize: false, with_method_head: true} }

      it "returns method definition's head as well" do
        expect(subject.passed_at(options)).to match(
        /Passed as :name in 'Student#:initialize \(private\)' at #{__FILE__}:\d+
  > def initialize\(name, age\)/
        )
      end
    end
  end
end
