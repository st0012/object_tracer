require "spec_helper"
require "shared_examples/stoppable_examples"

RSpec.describe TappingDevice::Trackable do
  include described_class

  describe "#tap_on!" do
    subject { :tap_on! }

    it_behaves_like "stoppable" do
      let(:target) { Student.new("Stan", 18) }
      let(:trigger_action) do
        -> (target) { target.name }
      end
    end

    it "tracks method calls on the tapped object" do
      stan = Student.new("Stan", 18)
      jane = Student.new("Jane", 23)

      device = tap_on!(stan)

      stan.name
      stan.age
      jane.name
      jane.age

      call = device.calls.first
      expect(call.receiver.object_id).to eq(stan.object_id)
      expect(call.method_name).to eq(:name)
      expect(call.return_value).to eq("Stan")

      call = device.calls.last
      expect(call.receiver.object_id).to eq(stan.object_id)
      expect(call.method_name).to eq(:age)
      expect(call.return_value).to eq(18)
    end
    it "tracks alias" do
      c = Class.new(Student)
      c.class_eval do
        alias :alias_name :name
      end
      stan = c.new("Stan", 18)

      device = tap_on!(stan)

      stan.alias_name

      expect(device.calls.first.method_name).to eq(:alias_name)
    end

    context "when targets are ActiveRecord::Base instances" do
      context "with track_as_records: true" do
        it "tracks ActiveRecord::Base instances with their ids" do
          post = Post.create!(title: "foo", content: "bar")

          device = tap_on!(post, exclude_by_paths: [/gems/], track_as_records: true)

          Post.last.title

          expect(device.calls.count).to eq(1)
        end
      end
      context "without track_as_records: true" do
        it "treats the record like normal objects" do
          post = Post.create!(title: "foo", content: "bar")

          device = tap_on!(post, exclude_by_paths: [/gems/])

          Post.last.title

          expect(device.calls.count).to eq(0)
        end
      end
    end

    describe "options - with_trace_to: 5" do
      it "stores trace until given index" do
        stan = Student.new("Stan", 18)

        device = tap_on!(stan, with_trace_to: 5)

        stan.name

        expect(device.calls.first.trace.length).to eq(6)
      end
    end
    describe "options - exclude_by_paths: [/path/]" do
      it "skips calls that matches the pattern" do
        stan = Student.new("Stan", 18)

        device = tap_on!(stan, exclude_by_paths: [/spec/])

        stan.name

        expect(device.calls.count).to eq(0)
      end
    end
    describe "options - filter_by_paths: [/path/]" do
      it "skips calls that doesn't match the pattern" do
        stan = Student.new("Stan", 18)
        count = 0

        tap_on!(stan, filter_by_paths: [/lib/]) { count += 1 }

        stan.name
        expect(count).to eq(0)

        tap_on!(stan, filter_by_paths: [/spec/]) { count += 1 }

        stan.name
        expect(count).to eq(1)
      end
    end
  end
end
