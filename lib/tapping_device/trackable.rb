class TappingDevice
  module Trackable
    def tap_init!(klass, options = {}, &block)
      Device.new(options, &block).tap_init!(klass)
    end

    def tap_assoc!(record, options = {}, &block)
      Device.new(options, &block).tap_assoc!(record)
    end

    def tap_on!(object, options = {}, &block)
      Device.new(options, &block).tap_on!(object)
    end
  end
end
