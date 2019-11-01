class TappingDevice
  module Trackable
    def tap_init!(klass, options = {}, &block)
      TappingDevice.new(options, &block).tap_init!(klass)
    end

    def tap_assoc!(record, options = {}, &block)
      TappingDevice.new(options, &block).tap_assoc!(record)
    end

    def tap_on!(object, options = {}, &block)
      TappingDevice.new(options, &block).tap_on!(object)
    end
  end
end
