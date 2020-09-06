# typed: false
require "spec_helper"
require "shared_examples/stoppable_examples"
require "shared_examples/optionable_examples"

RSpec.describe "tap_on!" do
  let(:subject) { :tap_on! }

  it_behaves_like "stoppable" do
    let(:target) { Student.new("Stan", 18) }
    let(:trigger_action) do
      -> (target) { target.name }
    end
  end

  it_behaves_like "optionable" do
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
  it "doesn't track the calls from tapping_device" do
    device = tap_on!(self)
    device.stop!

    expect(device.calls.count).to eq(0)
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

  context "with options[:hijack_attr_methods] = true" do
    it "tracks attr_writers" do
      c = Class.new(Student)
      c.class_eval do
        attr_writer :name
      end
      stan = c.new("Stan", 18)

      device = tap_on!(stan, hijack_attr_methods: true)

      stan.name = "Sean"

      expect(device.calls.first.method_name).to eq(:name=)
    end
    it "tracks attr_readers" do
      c = Class.new(Student)
      c.class_eval do
        attr_reader :name
      end
      stan = c.new("Stan", 18)
      device = tap_on!(stan, hijack_attr_methods: true)

      stan.name

      expect(device.calls.first.method_name).to eq(:name)
    end
  end

  describe "private method options" do
    let(:c) do
      c = Class.new(Student)
      c.class_eval do
        def number
          private_number + 10
        end

        private

        def private_number
          10
        end
      end
      c
    end
    let(:stan) do
      c.new("Stan", 18)
    end

    context "with options[:ignore_private]" do
      context "when true" do
        it "ignores private method calls" do
          device = tap_on!(stan, ignore_private: true)

          stan.number

          expect(device.calls.count).to eq(1)
          expect(device.calls.first.method_name).to eq(:number)
        end
      end
      context "when false (default)" do
        it "records private method calls" do
          device = tap_on!(stan)

          stan.number

          expect(device.calls.count).to eq(2)
          expect(device.calls.first.method_name).to eq(:private_number)
          expect(device.calls.last.method_name).to eq(:number)
        end
      end
    end
    context "with options[:only_private]" do
      context "when true" do
        it "ignores private method calls" do
          device = tap_on!(stan, only_private: true)

          stan.number

          expect(device.calls.count).to eq(1)
          expect(device.calls.first.method_name).to eq(:private_number)
        end
      end
      context "when false (default)" do
        it "records private method calls" do
          device = tap_on!(stan)

          stan.number

          expect(device.calls.count).to eq(2)
          expect(device.calls.first.method_name).to eq(:private_number)
          expect(device.calls.last.method_name).to eq(:number)
        end
      end
    end
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
end
