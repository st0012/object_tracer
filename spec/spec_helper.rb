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

  def assert_query_count(number, print_queries = true)
    queries = []

    ActiveSupport::Notifications.subscribe('sql.active_record') do |_1, _2, _3, _4, payload|
      if !["SCHEMA", "TRANSACTION"].include? payload.name
        queries << payload.sql
      end
    end

    yield

    puts(queries) if print_queries && (number != queries.count)

    expect(queries.count).to eq(number), "Expect #{number} queries, got #{queries.count}"
  end
end
