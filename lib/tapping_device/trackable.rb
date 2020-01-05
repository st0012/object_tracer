class TappingDevice
  module Trackable
    [:tap_on!, :tap_init!, :tap_assoc!, :tap_sql!, :tap_passed!].each do |method|
      define_method method do |object, options = {}, &block|
        new_device(options, &block).send(method, object)
      end
    end

    def print_traces(target)
      device_1 = tap_on!(target, event_type: :call) do |payload|
        puts("Called #{payload.method_name_and_location}")
      end
      device_2 = tap_passed!(target, event_type: :call) do |payload|
        arg_name = payload.arguments.keys.detect { |k| payload.arguments[k] == target }
        next unless arg_name
        puts("Passed as '#{arg_name}' in '#{payload.defined_class}##{payload.method_name}' at #{payload.location}")
      end
      [device_1, device_2]
    end

    def print_calls_in_detail(target)
      tap_on!(target).and_print(:detail_call_info)
    end

    def new_device(options, &block)
      TappingDevice.new(options, &block)
    end
  end
end
