require "spec_helper"

class Student
  def initialize(name, age)
    @name = name
    @age = age
  end

  def self.foo; end

  def name
    @name
  end

  def age
    @age
  end

  def age=(age)
    @age = age
  end
end

class School
  def initialize(name)
    @name = name
  end

  def name
    @name
  end
end

RSpec.describe TappingDevice::Trackable do
  include described_class

  describe "#tap_initialization_of!" do
    before do
      stop_tapping!(Student)
    end

    after do
      stop_tapping!(Student)
    end

    it "tracks Student's initialization" do
      count = 0
      tap_initialization_of!(Student) do |options|
        count += 1
      end

      Student.new("Stan", 18)
      Student.new("Jane", 23)

      expect(count).to eq(2)
    end
    it "doesn't track School's initialization" do
      count = 0
      tap_initialization_of!(Student) do |options|
        count += 1
      end

      School.new("A school")

      expect(count).to eq(0)
    end
    it "doesn't track non-initialization method calls" do
      count = 0
      tap_initialization_of!(Student) do |options|
        count += 1
      end

      Student.foo

      expect(count).to eq(0)
    end
  end

  describe "#tap_calls_on!" do
    it "tracks method calls on the tapped object" do
      stan = Student.new("Stan", 18)
      jane = Student.new("Jane", 23)

      calls = []
      tap_calls_on!(stan) do |payload|
        calls << [payload[:receiver].object_id, payload[:method_name], payload[:return_value]]
      end

      stan.name
      stan.age
      jane.name
      jane.age

      expect(calls).to match_array(
        [
          [stan.object_id, :name, "Stan"],
          [stan.object_id, :age, 18]
        ]
      )
    end
    it "detects correct arguments" do
      stan = Student.new("Stan", 18)

      calls = []
      tap_calls_on!(stan) do |payload|
        calls << [
          payload[:receiver].object_id,
          payload[:method_name],
          payload[:return_value],
          payload[:arguments]
        ]
      end

      stan.age = (25)

      expect(calls).to match_array(
        [
          [stan.object_id, :age=, 25, [[:age, 25]]]
        ]
      )
    end
  end

  describe "#stop_tapping!" do
    it "stopps tapping" do
      count = 0
      tap_initialization_of!(Student) do |options|
        count += 1
      end

      Student.new("Stan", 18)

      stop_tapping!(Student)

      Student.new("Jane", 23)

      expect(count).to eq(1)
    end
  end
end
