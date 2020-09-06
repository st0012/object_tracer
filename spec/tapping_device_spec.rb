# typed: false
require "spec_helper"

RSpec.describe TappingDevice do
  include TappingDevice::Trackable

  it "supports multiple tappings" do
    stan = Student.new("Stan", 18)

    count_1 = 0
    count_2 = 0

    tap_on!(stan) { count_1 += 1 }
    tap_on!(stan) { count_2 -= 1 }

    stan.name

    expect(count_1).to eq(1)
    expect(count_2).to eq(-1)
  end

  describe "arguments recording" do
    class Foo
      def foo(a = 10)
        b = 100
        a = 1000
      end
    end
    context "when event_type is call" do
      it "records arguments correctly (doesn't include other local vars)" do
        f = Foo.new
        arguments = nil

        tap_on!(f, event_type: :call) do |payload|
          arguments = payload.arguments
        end

        f.foo

        expect(arguments).to eq({a: 10})
      end
    end
    # TODO: Make this work
    # context "when event_type is return" do
    #   it "records arguments correctly (not the overriden value)" do
    #     f = Foo.new
    #     arguments = nil

    #     described_class.new(event_type: :return) do |payload|
    #       arguments = payload.arguments
    #     end.tap_on!(f)

    #     f.foo

    #     expect(arguments).to eq({a: 10})
    #   end
    # end
  end
  describe "#and_print" do
    it "outputs payload with given payload method" do
      stan = Student.new("Stan", 18)
      tap_on!(stan).and_print(:method_name_and_arguments)

      expect do
        stan.name
      end.to output(":name <= {}\n").to_stdout
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

      device = tap_init!(Student)

      Student.new("stan", 0)

      expect(device.calls.count).to eq(0)
    end
  end
end
