class TappingDevice
  module Trackers
    class AssociactionCallTracker < TappingDevice
      def start_tracking(record)
        track(record, condition: :tap_associations?)
      end

      def validate_target!
        raise NotAnActiveRecordInstanceError.new(target) unless target.is_a?(ActiveRecord::Base)
      end

      def tap_associations?(object, tp)
        return false unless is_from_target?(object, tp)

        model_class = object.class
        associations = model_class.reflections
        associations.keys.include?(tp.callee_id.to_s)
      end
    end
  end
end