require "spec_helper"

RSpec.describe TappingDevice::Device do
  describe "#tap_initialization_of!" do
    it "tracks Student's initialization" do
      count = 0

      device = TappingDevice::Device.new do
        count += 1
      end

      device.tap_init!(Student)

      Student.new("Stan", 18)
      Student.new("Jane", 23)

      expect(count).to eq(2)

      device.stop!
    end
    it "can track subclass's initialization as well" do
      count = 0

      device = TappingDevice::Device.new do
        count += 1
      end

      device.tap_init!(HighSchoolStudent)

      HighSchoolStudent.new("Stan", 18)

      expect(count).to eq(1)
      device.stop!
    end
    it "doesn't track School's initialization" do
      count = 0

      device = TappingDevice::Device.new do
        count += 1
      end

      device.tap_init!(Student)

      School.new("A school")

      expect(count).to eq(0)
      device.stop!
    end
    it "doesn't track non-initialization method calls" do
      count = 0

      device = TappingDevice::Device.new do
        count += 1
      end

      device.tap_init!(Student)

      Student.foo

      expect(count).to eq(0)
      device.stop!
    end
  end
end
