class TappingDevice
  module Trackable
    [:tap_on!, :tap_assoc!].each do |method|
      define_method method do |object, options = {}, &block|
        new_device(options, &block).send(method, object)
      end
    end

    def tap_init!(object, options = {}, &block)
      TappingDevice::Trackers::InitializationTracker.new(options, &block).start_tracking(object)
    end

    def tap_passed!(object, options = {}, &block)
      TappingDevice::Trackers::PassedTracker.new(options, &block).start_tracking(object)
    end

    def print_traces(target, options = {})
      options[:event_type] = :call
      inspect = options.delete(:inspect)
      colorize = options.fetch(:colorize, true)

      device_1 = tap_on!(target, options).and_print do |output_payload|
        "Called #{output_payload.method_name_and_location(inspect: inspect, colorize: colorize)}"
      end
      device_2 = tap_passed!(target, options).and_print do |output_payload|
        output_payload.passed_at(inspect: inspect, colorize: colorize)
      end
      CollectionProxy.new([device_1, device_2])
    end

    def print_calls(target, options = {})
      inspect = options.delete(:inspect)
      colorize = options.fetch(:colorize, true)

      tap_on!(target, options).and_print do |output_payload|
        output_payload.detail_call_info(inspect: inspect, colorize: colorize)
      end
    end

    def new_device(options, &block)
      TappingDevice.new(options, &block)
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
