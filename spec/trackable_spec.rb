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

      Student.new("Stan", 25)

      expect(count).to eq(1)
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
end
