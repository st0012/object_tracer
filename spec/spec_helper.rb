require "tapping_device"
require "tapping_device/trackable"
require "bundler/setup"
require "pry"
require "matchers/write_to_file_matcher"
require 'simplecov'

SimpleCov.start

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.after do
    TappingDevice.reset!
  end
end

class Student
  attr_writer :name

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

  def id=(id)
    @id = id
  end

  def id
    @id
  end
end

class HighSchoolStudent < Student;end

class School
  def initialize(name)
    @name = name
  end

  def name
    @name
  end
end


