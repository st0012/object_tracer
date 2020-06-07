class TappingDevice
  module Trackers
    class MethodCallTracker < TappingDevice
      def filter_condition_satisfied?(tp)
        is_from_target?(tp)
      end
    end
  end
end
