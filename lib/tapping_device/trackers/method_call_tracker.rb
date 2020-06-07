class TappingDevice
  module Trackers
    class MethodCallTracker < TappingDevice
      def start_tracking(object)
        track(object)
      end

      def filter_condition_satisfied?(tp)
        is_from_target?(tp)
      end
    end
  end
end
