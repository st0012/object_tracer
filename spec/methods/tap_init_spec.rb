require "spec_helper"
require "shared_examples/stoppable_examples"

RSpec.describe TappingDevice::Trackable do
  include described_class

  describe "#tap_init!" do
    let(:calls) { [] }
    subject { :tap_init! }

    it "tracks Student's initialization" do
      device = tap_init!(Student)

      Student.new("Stan", 18)
      Student.new("Jane", 23)

      expect(device.calls.count).to eq(2)
    end
    it "can track subclass's initialization as well" do
      device = tap_init!(HighSchoolStudent)

      HighSchoolStudent.new("Stan", 18)

      expect(device.calls.count).to eq(1)
      expect(device.calls.first.target).to eq(HighSchoolStudent)
    end
    it "doesn't track School's initialization" do
      device = tap_init!(Student)

      School.new("A school")

      expect(device.calls.count).to eq(0)
    end
    it "doesn't track non-initialization method calls" do
      device = tap_init!(Student)

      Student.foo

      expect(device.calls.count).to eq(0)
    end

    it_behaves_like "stoppable" do
      let(:target) { Student }
      let(:trigger_action) do
        -> (target) { target.new("Stan", 18) }
      end
    end
  end
end
