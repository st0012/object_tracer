class TappingDevice
  module Trackers
    class InitializationTracker < TappingDevice
      def initialize(options = {}, &block)
        super
        event_type = @options[:event_type]
        # if a class doesn't override the 'initialize' method
        # Class.new will only trigger c_return or c_call
        @options[:event_type] = [event_type, "c_#{event_type}"]
      end

      def track(object)
        super
        @options[:is_active_record_model] = target.ancestors.include?(ActiveRecord::Base)
        self
      end

      def build_payload(tp:, filepath:, line_number:)
        payload = super

        return payload if @options[:is_active_record_model]

        payload[:return_value] = payload[:receiver]
        payload[:receiver] = target
        payload
      end

      def validate_target!
        raise NotAClassError.new(target) unless target.is_a?(Class)
      end

      def filter_condition_satisfied?(tp)
        receiver = tp.self
        method_name = tp.callee_id

        if @options[:is_active_record_model]
          method_name == :new && receiver.is_a?(Class) && receiver.ancestors.include?(target)
        else
          method_name == :initialize && receiver.is_a?(target)
        end
      end
    end
  end
end
