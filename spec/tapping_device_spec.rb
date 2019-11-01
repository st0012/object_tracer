require "spec_helper"

RSpec.describe TappingDevice do
  describe "#tap_init!" do
    let(:device) { described_class.new }

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

  describe "#tap_on!" do
    let(:device) do
      described_class.new do |payload|
        [payload[:receiver].object_id, payload[:method_name], payload[:return_value]]
      end
    end

    it "tracks method calls on the tapped object" do
      stan = Student.new("Stan", 18)
      jane = Student.new("Jane", 23)

      device.tap_on!(stan)

      stan.name
      stan.age
      jane.name
      jane.age

      expect(device.calls).to match_array(
        [
          [stan.object_id, :name, "Stan"],
          [stan.object_id, :age, 18]
        ]
      )
    end
    it "supports multiple tappings" do
      stan = Student.new("Stan", 18)

      count_1 = 0
      count_2 = 0

      device_1 = described_class.new { count_1 += 1 }
      device_2 = described_class.new { count_2 -= 1 }

      device_1.tap_on!(stan)
      device_2.tap_on!(stan)

      stan.name

      expect(count_1).to eq(1)
      expect(count_2).to eq(-1)
    end
    it "tracks alias" do
      c = Class.new(Student)
      c.class_eval do
        alias :alias_name :name
      end
      stan = c.new("Stan", 18)

      names = []

      device.set_block do |payload|
        names << payload[:method_name]
      end

      device.tap_on!(stan)

      stan.alias_name

      expect(names).to match_array([:alias_name])
    end

    describe "yield parameters" do
      it "detects correct arguments" do
        stan = Student.new("Stan", 18)

        arguments = []

        device.set_block do |payload|
          arguments = payload[:arguments]
        end

        device.tap_on!(stan)

        stan.age = (25)

        expect(arguments).to eq([[:age, 25]])
      end
      it "returns correct filepath and line number" do
        stan = Student.new("Stan", 18)

        filepath = ""
        line_number = 0

        device.set_block do |payload|
          filepath = payload[:filepath]
          line_number = payload[:line_number]
        end

        device.tap_on!(stan)

        line_mark = __LINE__
        stan.age

        expect(filepath).to eq(__FILE__)
        expect(line_number).to eq((line_mark+1).to_s)
      end
    end

    describe "options - exclude_by_paths: [/path/]" do
      it "skips calls that matches the pattern" do
        stan = Student.new("Stan", 18)
        count = 0

        device = described_class.new(exclude_by_paths: [/spec/]) { count += 1 }
        device.tap_on!(stan)

        stan.name

        expect(count).to eq(0)
      end
    end
    describe "options - filter_by_paths: [/path/]" do
      it "skips calls that matches the pattern" do
        stan = Student.new("Stan", 18)
        count = 0

        device_1 = described_class.new(filter_by_paths: [/lib/]) { count += 1 }
        device_1.tap_on!(stan)

        stan.name
        expect(count).to eq(0)

        device_2 = described_class.new(filter_by_paths: [/spec/]) { count += 1 }
        device_2.tap_on!(stan)

        stan.name
        expect(count).to eq(1)
      end
    end
  end

  describe "#stop!" do
    it "stopps tapping" do
      count = 0
      device = described_class.new do |options|
        count += 1
      end
      device.tap_init!(Student)


      Student.new("Stan", 18)

      device.stop!

      Student.new("Jane", 23)

      expect(count).to eq(1)
    end
  end

  describe "#tap_init" do
    let(:device) { described_class.new }
    let(:stan) { Student.new("stan", 25) }

    it "raises error if device has no stop_when set" do
      expect { device.tap_init(Student) }.to raise_error(TappingDevice::Exception)
    end
  end

  describe "#tap_on" do
    let(:device) { described_class.new }
    let(:stan) { Student.new("stan", 25) }

    it "raises error if device has no stop_when set" do
      expect { device.tap_on(stan) }.to raise_error(TappingDevice::Exception)
    end
  end

  describe "#tap_assoc" do
    let(:device) { described_class.new }
    let(:post) { Post.new }

    it "raises error if device has no stop_when set" do
      expect { device.tap_assoc(post) }.to raise_error(TappingDevice::Exception)
    end
  end

  describe "#stop_when" do
    it "stops tapping once fulfill stop_when condition" do
      device = described_class.new
      device.stop_when do |payload|
        device.calls.count == 10
      end

      s = Student.new("foo#", 10)
      device.tap_on!(s)

      100.times do
        s.name
      end

      expect(device.calls.count).to eq(10)
    end
  end

  describe ".devices" do
    it "stores all initialized devices" do
      device_1 = described_class.new
      device_2 = described_class.new
      device_3 = described_class.new

      device_2.stop!

      expect(described_class.devices).to match_array([device_1, device_3])

      described_class.stop_all!

      expect(described_class.devices).to match_array([])
    end
  end

  describe ".suspend_new!" do
    it "stops all devices and won't enable new ones" do
      described_class.suspend_new!

      device_1 = described_class.new
      device_1.tap_init!(Student)

      Student.new("stan", 0)

      expect(device_1.calls.count).to eq(0)
    end
  end
end
