require "pry"
module TappingDevice
  module Trackable
    TAPPING_DEVICE = :@tapping_device

    def tap_initialization_of!(klass, with_trace: false, &block)
      raise "argument should be a class, got #{klass}" unless klass.is_a?(Class)

      condition = -> (arguments) { arguments[:method_name] == :initialize && arguments[:defined_class] == klass }
      track(klass, with_trace: with_trace, condition: condition, block: block)
    end

    def tap_calls_on!(object, with_trace: false, &block)
      condition = -> (arguments) { arguments[:receiver].object_id == object.object_id }
      track(object, with_trace: with_trace, condition: condition, block: block)
    end

    def stop_tapping!(object)
      get_tapping_device(object)&.each { |tp| tp.disable }
    end

    private

    def track(object, with_trace:, condition:, block:)
      trace_point = TracePoint.new(:return) do |tp|
        arguments = tp.binding.local_variables.map { |n| [n, tp.binding.local_variable_get(n)] }
        yield_parameters = {
          receiver: tp.self,
          method_name: tp.callee_id,
          arguments: arguments,
          return_value: (tp.return_value rescue nil),
          filepath: tp.path,
          line_number: tp.lineno,
          defined_class: tp.defined_class,
          trace: []
        }

        yield_parameters[:trace] = caller[0..50] if with_trace

        if !condition
          block.call(yield_parameters)
        elsif condition.call(yield_parameters)
          block.call(yield_parameters)
        end
      end

      unless get_tapping_device(object)
        object.instance_variable_set(TAPPING_DEVICE, [])
      end

      trace_point.enable
      add_tapping_device(object, trace_point)
    end

    def get_tapping_device(object)
      object.instance_variable_get(TAPPING_DEVICE)
    end

    def add_tapping_device(object, trace_point)
      object.instance_variable_get(TAPPING_DEVICE) << trace_point
    end
  end
end
