class TappingDevice
  module Trackers
    # PassedTracker tracks calls that use the target object as an argument
    class PassedTracker < TappingDevice
      def start_tracking(object)
        track(object)
      end

      def filter_condition_satisfied?(tp)
        # we don't care about calls from the device instance or helper methods
        return false if is_from_target?(tp)
        return false if tp.defined_class == TappingDevice::Trackable || tp.defined_class == TappingDevice

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
