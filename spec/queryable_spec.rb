require "spec_helper"

RSpec.describe TappingDevice do
  describe ".create_events_table" do
    it "creates events table" do
      # during the test setup, we establish another connection to create fixture data
      # so we need to reconnect to the original connection
      described_class.connection.reconnect!
      described_class.connection.drop_table("events", if_exists: true)

      described_class.create_events_table

      expect(described_class.connection.table_exists?("events")).to eq(true)
    end
  end
  describe ".drop_events_table" do
    it "drops events table" do
      described_class.create_events_table
      expect(described_class.connection.table_exists?("events")).to eq(true)

      described_class.drop_events_table

      expect(described_class.connection.table_exists?("events")).to eq(false)
    end
    it "does nothing if there's no events table" do
      expect(described_class.connection.table_exists?("events")).to eq(false)

      described_class.drop_events_table

      expect(described_class.connection.table_exists?("events")).to eq(false)
    end
  end
end

RSpec.describe TappingDevice::Event do
  # TODO: find out why DatabaseCleaner doesn't work here
  after do
    described_class.destroy_all
  end
  describe "queryable: true" do
    it "recreates events table if there's none" do
      connection = TappingDevice.connection
      connection.reconnect!
      connection.drop_table("events", if_exists: true)

      s = Student.new("Stan", 25)
      tap_on!(s, queryable: true)

      expect(described_class.connection.table_exists?("events")).to eq(true)
    end
    it "uses correct database and table names" do
      expect(described_class.connection_config[:database]).to eq("/tmp/tapping_device.db")
      expect(described_class.table_name).to eq("events")
    end
    it "stores events into database" do
      s = Student.new("Stan", 25)
      tap_on!(s, queryable: true)

      s.name
      s.age

      expect(described_class.count).to eq(2)
    end
    it "stores correct event info" do
      s = Student.new("Stan", 25)
      tap_on!(s, queryable: true)

      s.name; line = __LINE__

      event = described_class.last
      expect(event.event_type).to eq("return")
      expect(event.target).to match(/Student/)
      expect(event.receiver).to match(/Student/)
      expect(event.target_object_id).to eq(s.object_id.to_s)
      expect(event.method_name).to eq("name")
      expect(event.arguments).to match("{}")
      expect(event.return_value).to match("Stan")
      expect(event.location).to match("tapping_device/spec/queryable_spec.rb:#{line}")
      expect(event.defined_class).to eq("Student")
    end
  end
end
