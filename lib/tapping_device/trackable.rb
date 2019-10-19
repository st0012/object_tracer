require "pry"
module TappingDevice
  module Trackable
    TAPPING_DEVICE = :@tapping_device

    CALL = :call
    INITIALIZATION = :initialization
    TYPES = [CALL, INITIALIZATION]


    def tap_initialization_of!(klass, &block)
      raise "argument should be a class, got #{klass}" unless klass.is_a?(Class)

      condition = -> (arguments) { arguments[:method_name] == :initialize && arguments[:defined_class] == klass }
      track(klass, type: INITIALIZATION, condition: condition, block: block)
    end

    def tap_calls_on!(object, &block)
      condition = -> (arguments) { arguments[:receiver].object_id == object.object_id }
      track(object, type: CALL, condition: condition, block: block)
    end

    def stop_tapping!(object, type: nil)
      tapping_devices = get_tapping_device(object)
      return unless tapping_devices

      if type
        tapping_devices[type].disable
      else
        tapping_devices.values.each { |tp| tp.disable }
      end
    end

    private

    def track(object, type:, condition:, block:)
      trace_point = TracePoint.new(:return) do |tp|
        arguments = tp.binding.local_variables.map { |n| [n, tp.binding.local_variable_get(n)] }
        yield_parameters = {
          receiver: tp.self,
          method_name: tp.method_id,
          arguments: arguments,
          return_value: (tp.return_value rescue nil),
          filepath: tp.path,
          line_number: tp.lineno,
          defined_class: tp.defined_class
        }

        if !condition
          block.call(yield_parameters)
        elsif condition.call(yield_parameters)
          block.call(yield_parameters)
        end
      end

      unless get_tapping_device(object)
        object.instance_variable_set(TAPPING_DEVICE, {})
      end

      set_tapping_device(object, type, trace_point)
      trace_point.enable
    end

    def get_tapping_device(object)
      object.instance_variable_get(TAPPING_DEVICE)
    end

    def set_tapping_device(object, type, trace_point)
      object.instance_variable_get(TAPPING_DEVICE)[type] = trace_point
    end
  end
end
