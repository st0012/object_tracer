require "tapping_device/trackable"

module TappingDevice
  class Device
    include Trackable

    attr_reader :options, :calls

    def initialize(options = {}, &block)
      @block = block
      @options = options
      @calls = []
    end

    def tap_init!(klass)
      raise "argument should be a class, got #{klass}" unless klass.is_a?(Class)
      track(klass, condition: :tap_init?, block: @block, **@options)
    end

    def tap_on!(object)
      track(object, condition: :tap_on?, block: @block, **@options)
    end

    def tap_assoc!(record)
      raise "argument should be an instance of ActiveRecord::Base" unless record.is_a?(ActiveRecord::Base)
      track(record, condition: :tap_associations?, block: @block, **@options)
    end

    def set_block(&block)
      @block = block
    end

    def stop!
      @trace_point.disable if @trace_point
    end

    private

    def track(object, condition:, block:, with_trace_to: nil, exclude_by_paths: [], filter_by_paths: nil)
      @trace_point = TracePoint.trace(:return) do |tp|
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

        if send(condition, object, yield_parameters)
          if @block
            @calls << block.call(yield_parameters)
          else
            @calls << yield_parameters
          end
        end
      end
    end
  end
end
