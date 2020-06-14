class TappingDevice
  module Trackable
    def tap_init!(object, options = {}, &block)
      TappingDevice::Trackers::InitializationTracker.new(options, &block).track(object)
    end

    def tap_passed!(object, options = {}, &block)
      TappingDevice::Trackers::PassedTracker.new(options, &block).track(object)
    end

    def tap_assoc!(object, options = {}, &block)
      TappingDevice::Trackers::AssociactionCallTracker.new(options, &block).track(object)
    end

    def tap_on!(object, options = {}, &block)
      TappingDevice::Trackers::MethodCallTracker.new(options, &block).track(object)
    end

    def tap_mutation!(object, options = {}, &block)
      TappingDevice::Trackers::MutationTracker.new(options, &block).track(object)
    end

    def print_traces(target, options = {})
      output_options = extract_output_options(options)
      options[:event_type] = :call

      device_1 = tap_on!(target, options).and_print do |output_payload|
        "Called #{output_payload.method_name_and_location(output_options)}\n"
      end
      device_2 = tap_passed!(target, options).and_print do |output_payload|
        output_payload.passed_at(output_options)
      end
      CollectionProxy.new([device_1, device_2])
    end

    def write_traces(target, options = {})
      output_options = extract_output_options(options)
      options[:event_type] = :call

      device_1 = tap_on!(target, options).and_write do |output_payload|
        "Called #{output_payload.method_name_and_location(output_options)}\n"
      end
      device_2 = tap_passed!(target, options).and_write do |output_payload|
        output_payload.passed_at(output_options)
      end
      CollectionProxy.new([device_1, device_2])
    end

    def print_calls(target, options = {})
      output_options = extract_output_options(options)

      tap_on!(target, options).and_print do |output_payload|
        output_payload.detail_call_info(output_options)
      end
    end

    def write_calls(target, options = {})
      output_options = extract_output_options(options)

      tap_on!(target, options).and_write do |output_payload|
        output_payload.detail_call_info(output_options)
      end
    end

    def print_mutations(target, options = {})
      output_options = extract_output_options(options)

      tap_mutation!(target, options).and_print do |output_payload|
        output_payload.call_info_with_ivar_changes(output_options)
      end
    end

    def write_mutations(target, options = {})
      output_options = extract_output_options(options)

      tap_mutation!(target, options).and_write do |output_payload|
        output_payload.call_info_with_ivar_changes(output_options)
      end
    end

    private

    def extract_output_options(options)
      {inspect: options.delete(:inspect), colorize: options.fetch(:colorize, true)}
    end

    class CollectionProxy
      def initialize(devices)
        @devices = devices
      end

      [:stop!, :stop_when, :with].each do |method|
        define_method method do |&block|
          @devices.each do |device|
            device.send(method, &block)
          end
        end
      end
    end
  end
end

include TappingDevice::Trackable
