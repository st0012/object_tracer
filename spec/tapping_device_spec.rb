require "spec_helper"

RSpec.describe TappingDevice::Device do
  describe "#tap_init!" do
    let(:device) { TappingDevice::Device.new }

    after do
      device.stop!
    end

    it "tracks Student's initialization" do
      device.tap_init!(Student)

      Student.new("Stan", 18)
      Student.new("Jane", 23)

      expect(device.calls.count).to eq(2)
    end
    it "can track subclass's initialization as well" do
      device.tap_init!(HighSchoolStudent)

      HighSchoolStudent.new("Stan", 18)

      expect(device.calls.count).to eq(1)
    end
    it "doesn't track School's initialization" do
      device.tap_init!(Student)

      School.new("A school")

      expect(device.calls.count).to eq(0)
    end
    it "doesn't track non-initialization method calls" do
      device.tap_init!(Student)

      Student.foo

      expect(device.calls.count).to eq(0)
    end
  end
end
