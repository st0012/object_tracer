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

    [:calls, :traces, :mutations].each do |subject|
      [:print, :write].each do |output_action|
        helper_method_name = "#{output_action}_#{subject}"

        define_method helper_method_name do |target, options = {}|
          send("output_#{subject}", target, options, output_action: "and_#{output_action}")
        end

        define_method "with_#{helper_method_name}" do |options = {}|
          send(helper_method_name, self, options)
          self
        end

        define_method "#{output_action}_instance_#{subject}" do |target_klass, options = {}|
          collection_proxy = AsyncCollectionProxy.new

          tap_init!(target_klass, options) do |payload|
            collection_proxy << send(helper_method_name, payload.return_value, options)
          end

          collection_proxy
        end
      end
    end

    private

    def output_calls(target, options = {}, output_action:)
      device_options, output_options = separate_options(options)

      tap_on!(target, device_options).send(output_action, options: output_options) do |output_payload, output_options|
        output_payload.detail_call_info(output_options)
      end
    end

    def output_traces(target, options = {}, output_action:)
      device_options, output_options = separate_options(options)
      device_options[:event_type] = :call

      device_1 = tap_on!(target, device_options).send(output_action, options: output_options) do |output_payload, output_options|
        "Called #{output_payload.method_name_and_location(output_options)}\n"
      end
      device_2 = tap_passed!(target, device_options).send(output_action, options: output_options) do |output_payload, output_options|
        output_payload.passed_at(output_options)
      end
      CollectionProxy.new([device_1, device_2])
    end

    def output_mutations(target, options = {}, output_action:)
      device_options, output_options = separate_options(options)

      tap_mutation!(target, device_options).send(output_action, options: output_options) do |output_payload, output_options|
        output_payload.call_info_with_ivar_changes(output_options)
      end
    end

    def separate_options(options)
      output_options = Output::DEFAULT_OPTIONS.keys.each_with_object({}) do |key, hash|
        hash[key] = options.fetch(key, TappingDevice.config[key])
        options.delete(key)
      end

      [options, output_options]
    end

    # CollectionProxy delegates chained actions to multiple devices
    class CollectionProxy
      CHAINABLE_ACTIONS = [:stop!, :stop_when, :with]

      def initialize(devices)
        @devices = devices
      end

      CHAINABLE_ACTIONS.each do |method|
        define_method method do |&block|
          @devices.each do |device|
            device.send(method, &block)
          end
        end
      end
    end

    # AsyncCollectionProxy delegates chained actions to multiple device "asyncronously"
    # when we use tapping methods like `tap_init!` to create sub-devices
    # we need to find a way to pass the chained actions to every sub-device that's created
    # and this can only happen asyncronously as we won't know when'll that happen
    class AsyncCollectionProxy < CollectionProxy
      def initialize(devices = [])
        super
        @blocks = {}
      end

      CHAINABLE_ACTIONS.each do |method|
        define_method method do |&block|
          super(&block)
          @blocks[method] = block
        end
      end

      def <<(device)
        @devices << device

        @blocks.each do |method, block|
          device.send(method, &block)
        end
      end
    end
  end
end

include TappingDevice::Trackable
