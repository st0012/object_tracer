class TappingDevice
  class Event < ActiveRecord::Base
    self.establish_connection TappingDevice::Queryable::CONFIGURATION
    self.table_name = TappingDevice::Queryable::DEFAULT_TABLE_NAME
  end
end
