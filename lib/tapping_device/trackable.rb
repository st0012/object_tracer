require "active_record"

module TappingDevice
  module Trackable
    TAPPING_DEVICE = :@tapping_device
    CALLER_START_POINT = 2

    def tap_initialization_of!(klass, options = {}, &block)
      raise "argument should be a class, got #{klass}" unless klass.is_a?(Class)
      track(klass, condition: :tap_init?, block: block, **options)
    end

    def tap_association_calls!(record, options = {}, &block)
      raise "argument should be an instance of ActiveRecord::Base" unless record.is_a?(ActiveRecord::Base)
      track(record, condition: :tap_associations?, block: block, **options)
    end

    def tap_calls_on!(object, options = {}, &block)
      track(object, condition: :tap_on?, block: block, **options)
    end

    def stop_tapping!(object)
      get_tapping_device(object)&.each { |tp| tp.disable }
    end

    alias :tap_init! :tap_initialization_of!
    alias :tap_assoc! :tap_association_calls!
    alias :tap_on! :tap_calls_on!
    alias :untap! :stop_tapping!

    private

    def track(object, condition:, block:, with_trace_to: nil, exclude_by_paths: [], filter_by_paths: nil)
      trace_point = TracePoint.trace(:return) do |tp|
        filepath, line_number = caller(CALLER_START_POINT).first.split(":")[0..1]

        # this needs to be placed upfront so we can exclude noise before doing more work
        next if exclude_by_paths.any? { |pattern| pattern.match?(filepath) }

        if filter_by_paths
          next unless filter_by_paths.any? { |pattern| pattern.match?(filepath) }
        end

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

        block.call(yield_parameters) if send(condition, object, yield_parameters)
      end

      add_tapping_device(object, trace_point)
      trace_point
    end

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
