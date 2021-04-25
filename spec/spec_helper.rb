require "tapping_device"
require "tapping_device/trackable"
require "bundler/setup"
require "pry"
require "model"
require "database_cleaner"
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

  DatabaseCleaner.strategy = :truncation

  config.before(:suite) do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with(:truncation)
  end

  config.around(:each) do |example|
    DatabaseCleaner.cleaning do
      example.run
    end
  end

  config.after do
    TappingDevice.reset!
  end
end
