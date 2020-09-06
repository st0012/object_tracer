# typed: false
require "spec_helper"
require "shared_examples/stoppable_examples"
require "shared_examples/optionable_examples"

RSpec.describe "tap_init!" do
  subject { :tap_init! }
  let(:target) { Student }
  let(:trigger_action) do
    -> (target) { target.new("Stan", 18) }
  end

  it_behaves_like "stoppable"
  it_behaves_like "optionable"

  it "raises error if the object is not a calss" do
    expect { tap_init!(1) }.to raise_error(TappingDevice::NotAClassError)
  end

  it "tracks class that doesn't define the initialize method (c_call or c_return)" do
    class Foo; end

    device = tap_init!(Foo)

    Foo.new

    expect(device.calls.count).to eq(1)
  end

  it "tracks Student's initialization" do
    device = tap_init!(Student)

    Student.new("Stan", 18)
    Student.new("Jane", 23)

    expect(device.calls.count).to eq(2)
  end

  it "returns the instance object" do
   device = tap_init!(Student)

   stan = Student.new("Stan", 18)

   expect(device.calls.first.return_value).to eq(stan)
   expect(device.calls.first.receiver).to eq(Student)
  end

  it "returns the instance object for ActiveRecord models" do
   device = tap_init!(Post)

   post = Post.new

   expect(device.calls.count).to eq(1)
   expect(device.calls.first.return_value).to eq(post)
   expect(device.calls.first.receiver).to eq(Post)
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
end
