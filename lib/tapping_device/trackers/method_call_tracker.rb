class TappingDevice
  module Trackers
    class MethodCallTracker < TappingDevice
      def start_tracking(object)
        track(object, condition: :tap_on?)
      end

      def tap_on?(object, tp)
        is_from_target?(object, tp)
      end
    end
  end
end