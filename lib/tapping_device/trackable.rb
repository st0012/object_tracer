module TappingDevice
  module Trackable
    TAPPING_DEVICE = :@tapping_device
    CALLER_START_POINT = 2

    def tap_initialization_of!(klass, options = {}, &block)
      raise "argument should be a class, got #{klass}" unless klass.is_a?(Class)
      options[:condition] = -> (arguments) { arguments[:method_name] == :initialize && arguments[:defined_class] == klass }
      options[:block] = block
      track(klass, **options)
    end

    def tap_calls_on!(object, options = {}, &block)
      options[:condition] = -> (arguments) { arguments[:receiver].object_id == object.object_id }
      options[:block] = block
      track(object, **options)
    end

    def stop_tapping!(object)
      get_tapping_device(object)&.each { |tp| tp.disable }
    end

    alias :tap_init! :tap_initialization_of!
    alias :tap_on! :tap_calls_on!
    alias :untap! :stop_tapping!

    private

    def track(object, condition:, block:, with_trace_to: nil, exclude_from_paths: [])
      trace_point = TracePoint.trace(:return) do |tp|
        filepath, line_number = caller(CALLER_START_POINT).first.split(":")[0..1]

        # this needs to be placed upfront so we can exclude noise before doing more work
        next if exclude_from_paths.any? { |pattern| pattern.match?(filepath) }

        arguments = tp.binding.local_variables.map { |n| [n, tp.binding.local_variable_get(n)] }

        yield_parameters = {
          receiver: tp.self,
          method_name: tp.callee_id,
          arguments: arguments,
          return_value: (tp.return_value rescue nil),
          filepath: filepath,
          line_number: line_number,
          defined_class: tp.defined_class,
          trace: [],
          tp: tp
        }

        yield_parameters[:trace] = caller[CALLER_START_POINT..(CALLER_START_POINT + with_trace_to)] if with_trace_to

        block.call(yield_parameters) if condition.call(yield_parameters)
      end

      add_tapping_device(object, trace_point)
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
