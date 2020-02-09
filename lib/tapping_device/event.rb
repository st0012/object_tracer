require "tapping_device/payload_helper"

class TappingDevice
  class Event < ActiveRecord::Base
    include PayloadHelper

    self.logger = nil

    self.establish_connection TappingDevice::Queryable::CONFIGURATION
    self.table_name = TappingDevice::Queryable::DEFAULT_TABLE_NAME
  end
end
