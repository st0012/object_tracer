class TappingDevice
  module Trackable
    [:tap_on!, :tap_init!, :tap_assoc!, :tap_sql!, :tap_passed!].each do |method|
      define_method method do |object, options = {}, &block|
        new_device(options, &block).send(method, object)
      end
    end

    def new_device(options, &block)
      TappingDevice.new(options, &block)
    end
  end
end
