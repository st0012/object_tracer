class TappingDevice
  module Trackers
    class InitializationTracker < TappingDevice
      def start_tracking(klass)
        track(klass) do |payload|
          payload[:return_value] = payload[:receiver]
          payload[:receiver] = klass
        end
      end

      def validate_target!
        raise NotAClassError.new(target) unless target.is_a?(Class)
      end

      def filter_condition_satisfied?(tp)
        receiver = tp.self
        method_name = tp.callee_id

        if target.ancestors.include?(ActiveRecord::Base)
          method_name == :new && receiver.ancestors.include?(target)
        else
          method_name == :initialize && receiver.is_a?(target)
        end
      end
    end
  end
end
