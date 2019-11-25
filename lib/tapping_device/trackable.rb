class TappingDevice
  module Trackable
    def tap_init!(klass, options = {}, &block)
      new_device(options, &block).tap_init!(klass)
    end

    def tap_assoc!(record, options = {}, &block)
      new_device(options, &block).tap_assoc!(record)
    end

    def tap_on!(object, options = {}, &block)
      new_device(options, &block).tap_on!(object)
    end

    def tap_sql!(object, options = {}, &block)
      new_device(options, &block).tap_sql!(object)
    end

    def new_device(options, &block)
      TappingDevice.new(options, &block)
    end
  end
end
