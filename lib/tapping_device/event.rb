require "tapping_device/payload_helper"
require "terminal-table"

class TappingDevice
  class Event < ActiveRecord::Base
    include PayloadHelper

    self.logger = nil

    self.establish_connection TappingDevice::Queryable::CONFIGURATION
    self.table_name = TappingDevice::Queryable::DEFAULT_TABLE_NAME

    def self.print_events_in_table(attributes = nil)
      puts(build_table(attributes))
    end

    def self.build_table(attributes = nil)
      attributes ||= [:method_name, :arguments, :return_value, :location]

      rows = all.map do |event|
        attributes.map { |attr| event.send(attr) }
      end

      Terminal::Table.new headings: attributes, rows: rows
    end
  end
end
