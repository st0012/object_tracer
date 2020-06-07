class TappingDevice
  module Trackers
    class InitializationTracker < TappingDevice
      def start_tracking(klass)
        raise "argument should be a class, got #{klass}" unless klass.is_a?(Class)
        track(klass, condition: :tap_init?) do |payload|
          payload[:return_value] = payload[:receiver]
          payload[:receiver] = klass
        end
      end

      def tap_init?(klass, tp)
        receiver = tp.self
        method_name = tp.callee_id

        if klass.ancestors.include?(ActiveRecord::Base)
          method_name == :new && receiver.ancestors.include?(klass)
        else
          method_name == :initialize && receiver.is_a?(klass)
        end
      end
    end
  end
end
