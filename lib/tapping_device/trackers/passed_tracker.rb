# typed: true
class TappingDevice
  module Trackers
    # PassedTracker tracks calls that use the target object as an argument
    class PassedTracker < TappingDevice
      extend T::Sig

      sig {params(tp: TracePoint).returns(T::Boolean)}
      def filter_condition_satisfied?(tp)
        collect_arguments(tp).values.any? do |value|
          # during comparison, Ruby might perform data type conversion like calling `to_sym` on the value
          # but not every value supports every conversion methods
          target == value rescue false
        end
      rescue
        false
      end
    end
  end
end
