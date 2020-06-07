class TappingDevice
  module Trackers
    class InitializationTracker < TappingDevice
      def start_tracking(klass)
        track(klass, condition: :tap_init?) do |payload|
          payload[:return_value] = payload[:receiver]
          payload[:receiver] = klass
        end
      end

      def validate_target!
        raise NotAClassError.new(target) unless target.is_a?(Class)
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
