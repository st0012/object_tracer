class TappingDevice
  module Trackers
    class AssociactionCallTracker < TappingDevice
      def start_tracking(record)
        raise "argument should be an instance of ActiveRecord::Base" unless record.is_a?(ActiveRecord::Base)
        track(record, condition: :tap_associations?)
      end

      def tap_associations?(object, tp)
        return false unless tap_on?(object, tp)

        model_class = object.class
        associations = model_class.reflections
        associations.keys.include?(tp.callee_id.to_s)
      end
    end
  end
end
