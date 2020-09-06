# typed: true
class TappingDevice
  module Trackers
    class AssociactionCallTracker < TappingDevice
      extend T::Sig

      sig{void}
      def validate_target!
        raise NotAnActiveRecordInstanceError.new(target) unless target.is_a?(ActiveRecord::Base)
      end

      sig {params(tp: TracePoint).returns(T::Boolean)}
      def filter_condition_satisfied?(tp)
        return false unless is_from_target?(tp)

        model_class = target.class
        associations = model_class.reflections
        associations.keys.include?(tp.callee_id.to_s)
      end
    end
  end
end
