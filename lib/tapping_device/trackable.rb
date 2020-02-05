class TappingDevice
  module Trackable
    [:tap_on!, :tap_init!, :tap_assoc!, :tap_sql!, :tap_passed!].each do |method|
      define_method method do |object, options = {}, &block|
        new_device(options, &block).send(method, object)
      end
    end

    def print_traces(target, options = {})
      options[:event_type] = :call

      device_1 = tap_on!(target, options) do |payload|
        puts("Called #{payload.method_name_and_location}")
      end
      device_2 = tap_passed!(target, options) do |payload|
        arg_name = payload.arguments.keys.detect { |k| payload.arguments[k] == target }
        next unless arg_name
        puts("Passed as '#{arg_name}' in '#{payload.defined_class}##{payload.method_name}' at #{payload.location}")
      end
      [device_1, device_2]
    end

    def print_calls_in_detail(target, options = {})
      awesome_print = options.delete(:awesome_print)

      tap_on!(target, options) do |payload|
        puts(payload.detail_call_info(awesome_print: awesome_print))
      end
    end

    def new_device(options, &block)
      TappingDevice.new(options, &block)
    end
  end
end

include TappingDevice::Trackable
