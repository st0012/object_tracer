class TappingDevice
  module Queryable
    CONFIGURATION = {
      adapter: 'sqlite3',
      database: '/tmp/tapping_device.db'
    }

    DEFAULT_TABLE_NAME = "events"

    def self.included(base)
      base.extend(ClassMethods)
    end

    def setup_for_queryable
      self.class.create_events_table unless self.class.has_events_table?
    end

    module ClassMethods
      def connection
        TappingDevice::Event.connection
      end

      def create_events_table
        connection.create_table DEFAULT_TABLE_NAME, force: true  do |t|
          t.string :event_type
          t.string :target
          t.string :target_object_id
          t.string :receiver
          t.string :method_name
          t.string :arguments
          t.string :return_value
          t.string :location
          t.string :defined_class
          t.json :trace
          t.timestamps
        end
      end

      def drop_events_table
        connection.drop_table(DEFAULT_TABLE_NAME, if_exists: true)
      end

      def has_events_table?
        connection.table_exists?(DEFAULT_TABLE_NAME)
      end
    end

    def save_event(payload)
      Event.create!(
        event_type: payload.tp.event,
        target: payload.target,
        target_object_id: payload.target.object_id.to_s,
        receiver: payload.receiver,
        method_name: payload.method_name,
        arguments: payload.arguments,
        return_value: payload.return_value,
        location: payload.location,
        defined_class: payload.defined_class,
        trace: payload.trace
      )
    end
  end
end
