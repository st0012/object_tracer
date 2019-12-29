require "spec_helper"

RSpec.describe TappingDevice do
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
  describe "#and_print" do
    let(:device) { described_class.new }

    it "outputs payload with given payload method" do
      stan = Student.new("Stan", 18)
      device.tap_on!(stan).and_print(:method_name_and_arguments)

      expect do
        stan.name
      end.to output("name <= {}\n").to_stdout
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
