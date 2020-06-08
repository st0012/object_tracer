require "pry" # for using Method#source

class TappingDevice
  module Trackers
    class MutationTracker < TappingDevice
      def track(object)
        super
        snapshot_instance_variables
        hijack_attr_writers
        self
      end

      private

      def filter_condition_satisfied?(tp)
        return false unless is_from_target?(tp)

        @latest_instance_variables = target_instance_variables
        @latest_instance_variables != @instance_variables_snapshot
      end

      def hijack_attr_writers
        writer_methods = target.methods.grep(/\w+=/)
        writer_methods.each do |method_name|
          if target.method(method_name).source.match?(/attr_writer|attr_accessor/)
            ivar_name = "@#{method_name.to_s.sub("=", "")}"

            # need to use instance_eval to make the call site location consistent with normal methods
            target.instance_eval(
              <<~CODE
                def #{method_name}(val)
                  #{ivar_name} = val
                end
              CODE
            )
          end
        end
      end

      def build_payload(tp:, filepath:, line_number:)
        payload = super
        payload[:ivar_changes] = capture_ivar_changes
        payload
      end

      def record_call!(payload)
        super
        @instance_variables_snapshot = @latest_instance_variables
      end

      def capture_ivar_changes
        changes = {}

        additional_keys = @latest_instance_variables.keys - @instance_variables_snapshot.keys
        additional_keys.each do |key|
          changes[key] = {before: OutputPayload::UNDEFINED, after: @latest_instance_variables[key]}
        end

        removed_keys = @instance_variables_snapshot.keys - @latest_instance_variables.keys
        removed_keys.each do |key|
          changes[key] = {before: @instance_variables_snapshot[key], after: OutputPayload::UNDEFINED}
        end

        remained_keys = @latest_instance_variables.keys - additional_keys
        remained_keys.each do |key|
          next if @latest_instance_variables[key] == @instance_variables_snapshot[key]
          changes[key] = {before: @instance_variables_snapshot[key], after: @latest_instance_variables[key]}
        end

        changes
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
