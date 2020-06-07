class TappingDevice
  module Trackers
    class MutationTracker < TappingDevice
      def track(object)
        super
        snapshot_instance_variables
        self
      end

      private

      def filter_condition_satisfied?(tp)
        return false unless is_from_target?(tp)

        @latest_instance_variables = target_instance_variables
        @latest_instance_variables != @instance_variables_snapshot
      end

      def record_call!(payload)
        super
        @instance_variables_snapshot = @latest_instance_variables
      end

      def snapshot_instance_variables
        @instance_variables_snapshot = target_instance_variables
      end

      def target_instance_variables
        target.instance_variables.each_with_object({}) do |ivar, hash|
          hash[ivar] = target.instance_variable_get(ivar)
        end
      end
    end
  end
end
