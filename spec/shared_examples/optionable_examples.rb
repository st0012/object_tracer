RSpec.shared_examples "optionable" do
  context "with options - with_trace_to: 5" do
    it "stores trace until given index" do
      device = send(subject, target, with_trace_to: 5)

      trigger_action.call(target)

      expect(device.calls.first.trace.length).to eq(6)
    end
  end
  context "with options - exclude_by_paths: [/path/]" do
    it "skips calls that matches the pattern" do
      device = send(subject, target, exclude_by_paths: [/spec/])

      trigger_action.call(target)

      expect(device.calls.count).to eq(0)
    end
  end
  context "with options - filter_by_paths: [/path/]" do
    it "skips calls that doesn't match the pattern" do
      count = 0

      send(subject, target, filter_by_paths: [/lib/]) { count += 1 }

      trigger_action.call(target)
      expect(count).to eq(0)

      send(subject, target, filter_by_paths: [/spec/]) { count += 1 }

      trigger_action.call(target)
      expect(count).to eq(1)
    end
  end
  context "with options - force_recording: true" do
    it "skips all other filtering options" do
      device = send(subject, target, filter_by_paths: [/lib/], force_recording: true)

      trigger_action.call(target)

      expect(device.calls.count).to be >= 1
    end
  end
end
