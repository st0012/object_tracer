require "active_record"

module TappingDevice
  module Trackable
    TAPPING_DEVICE = :@tapping_device
    CALLER_START_POINT = 2

    def tap_init!(klass, options = {}, &block)
      Device.new(options, &block).tap_init!(klass)
    end

    def tap_assoc!(record, options = {}, &block)
      Device.new(options, &block).tap_assoc!(record)
    end

    def tap_on!(object, options = {}, &block)
      Device.new(options, &block).tap_on!(object)
    end

    private

    def tap_init?(klass, parameters)
      receiver = parameters[:receiver]
      method_name = parameters[:method_name]

      if klass.ancestors.include?(ActiveRecord::Base)
        method_name == :new && receiver.ancestors.include?(klass)
      else
        method_name == :initialize && receiver.is_a?(klass)
      end
    end

    def tap_on?(object, parameters)
      parameters[:receiver].object_id == object.object_id
    end

    def tap_associations?(object, parameters)
      return false unless tap_on?(object, parameters)

      model_class = object.class
      associations = model_class.reflections
      associations.keys.include?(parameters[:method_name].to_s)
    end

    def get_tapping_device(object)
      object.instance_variable_get(TAPPING_DEVICE)
    end

    def add_tapping_device(object, trace_point)
      object.instance_variable_set(TAPPING_DEVICE, []) unless get_tapping_device(object)
      object.instance_variable_get(TAPPING_DEVICE) << trace_point
    end
  end
end
