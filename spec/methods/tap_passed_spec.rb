require "spec_helper"
require "shared_examples/stoppable_examples"
require "shared_examples/optionable_examples"

RSpec.describe "tap_passed!" do
  subject { :tap_passed! }

  let(:target) { Student.new("Stan", 18) }
  let(:trigger_action) do
    -> (target) { foo(target) }
  end

  it_behaves_like "stoppable"
  it_behaves_like "optionable"

  def foo(obj)
    obj
  end

  def bar(obj)
    obj
  end

  private

  def private_foo(obj)
    obj
  end
  it "records all arguments usages of the object" do
    s = Student.new("Stan", 18)
    device = tap_passed!(s)

    foo(s); line_1 = __LINE__
    s.name
    bar(s); line_2 = __LINE__
    foo("123")

    expect(device.calls.count).to eq(2)

    call = device.calls.first
    expect(call.target).to eq(s)
    expect(call.method_name).to eq(:foo)
    expect(call.line_number).to eq(line_1.to_s)

    call = device.calls.second
    expect(call.target).to eq(s)
    expect(call.method_name).to eq(:bar)
    expect(call.line_number).to eq(line_2.to_s)
  end
  it "records private calls as well" do
    s = Student.new("Stan", 18)
    device = tap_passed!(s)

    send(:private_foo, s); line_1 = __LINE__

    expect(device.calls.count).to eq(1)

    call = device.calls.first
    expect(call.method_name).to eq(:private_foo)
    expect(call.line_number).to eq(line_1.to_s)
  end
  it "works even if the object's `method` method has been overriden" do
    class Baz
      def method

      end

      def foo(obj)
        obj
      end
    end

    s = Student.new("Stan", 18)
    device = tap_passed!(s)

    Baz.new.foo(s); line_1 = __LINE__

    expect(device.calls.count).to eq(1)

    call = device.calls.first
    expect(call.method_name).to eq(:foo)
    expect(call.line_number).to eq(line_1.to_s)
  end
  it "works even if the object's `method` method has been overriden (2)" do
    class Baz
      def method

      end

      private

      def foo(obj)
        obj
      end
    end

    s = Student.new("Stan", 18)
    device = tap_passed!(s)

    Baz.new.send(:foo, s); line_1 = __LINE__

    expect(device.calls.count).to eq(1)

    call = device.calls.first
    expect(call.method_name).to eq(:foo)
    expect(call.line_number).to eq(line_1.to_s)
  end
end
