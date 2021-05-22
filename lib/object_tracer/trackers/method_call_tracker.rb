class ObjectTracer
  module Trackers
    class MethodCallTracker < ObjectTracer
      def filter_condition_satisfied?(tp)
        is_from_target?(tp)
      end
    end
  end
end
