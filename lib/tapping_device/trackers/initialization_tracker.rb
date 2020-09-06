# typed: true
class TappingDevice
  module Trackers
    class InitializationTracker < TappingDevice
      extend T::Sig

      def initialize(options = {}, &block)
        super
        event_type = @options[:event_type]
        # if a class doesn't override the 'initialize' method
        # Class.new will only trigger c_return or c_call
        @options[:event_type] = [event_type, "c_#{event_type}"]
      end

      sig{params(object: T.untyped).returns(TappingDevice)}
      def track(object)
        super
        @is_active_record_model = target.ancestors.include?(ActiveRecord::Base)
        self
      end

      sig {params(tp: TracePoint, call_site: Types::CallSite).returns(Payload)}
      def build_payload(tp:, call_site:)
        payload = super

        return payload if @is_active_record_model

        payload[:return_value] = payload[:receiver]
        payload[:receiver] = target
        payload
      end

      sig{void}
      def validate_target!
        raise NotAClassError.new(target) unless target.is_a?(Class)
      end

      sig {params(tp: TracePoint).returns(T::Boolean)}
      def filter_condition_satisfied?(tp)
        receiver = tp.self
        method_name = tp.callee_id

        if @is_active_record_model
          # ActiveRecord redefines model classes' .new method,
          # so instead of calling Model#initialize, it'll actually call Model.new
          # see https://github.com/rails/rails/blob/master/activerecord/lib/active_record/inheritance.rb#L50
          method_name == :new &&
            receiver.is_a?(Class) &&
            # this checks if the model class is the target class or a subclass of it
            receiver.ancestors.include?(target) &&
            # Model.new triggers both c_return and return events. so we should only return in 1 type of the events
            # otherwise the callback will be triggered twice
            tp.event == :return
        else
          method_name == :initialize && receiver.is_a?(target)
        end
      end
    end
  end
end
