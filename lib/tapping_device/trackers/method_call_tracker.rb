# typed: true
class TappingDevice
  module Trackers
    class MethodCallTracker < TappingDevice
      extend T::Sig

      sig {params(tp: TracePoint).returns(T::Boolean)}
      def filter_condition_satisfied?(tp)
        is_from_target?(tp)
      end
    end
  end
end
