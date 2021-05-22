require "spec_helper"

RSpec.describe ObjectTracer::Payload do
  include ObjectTracer::Trackable

  let(:stan) { Student.new("Stan", 25) }
  subject do
    device = tap_init!(Student)
    stan
    device.calls.first
  end

  describe "#method_object" do
    it "returns correct method object" do
      expect(subject.method_object.name).to eq(:initialize)
      expect(subject.method_object.owner).to eq(Student)
    end
  end
end
