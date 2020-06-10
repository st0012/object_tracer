require "pry" # for using Method#source

class TappingDevice
  module Trackers
    class MutationTracker < TappingDevice
      def initialize(options, &block)
        super
        @snapshot_stack = []
      end

      def track(object)
        super
        hijack_attr_writers
        insert_snapshot_taking_trace_point
        self
      end

      def stop!
        super
        @ivar_snapshot_trace_point.disable
      end

      private

      # we need to snapshot instance variables at the beginning of every method call
      # so we can get a correct state for the later comparison
      def insert_snapshot_taking_trace_point
        @ivar_snapshot_trace_point = build_minimum_trace_point(event_type: :call) do
          snapshot_instance_variables
        end

        @ivar_snapshot_trace_point.enable unless TappingDevice.suspend_new
      end

      def filter_condition_satisfied?(tp)
        return false unless is_from_target?(tp)

        if snapshot_capturing_event?(tp)
          true
        else
          @latest_instance_variables = target_instance_variables
          @instance_variables_snapshot = @snapshot_stack.pop

          @latest_instance_variables != @instance_variables_snapshot
        end
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

        if change_capturing_event?(tp)
          payload[:ivar_changes] = capture_ivar_changes
        end

        payload
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
        @snapshot_stack.push(target_instance_variables)
      end

      def target_instance_variables
        target.instance_variables.each_with_object({}) do |ivar, hash|
          hash[ivar] = target.instance_variable_get(ivar)
        end
      end

      def snapshot_capturing_event?(tp)
        tp.event == :call
      end

      def change_capturing_event?(tp)
        !snapshot_capturing_event?(tp)
      end

      # belows are debugging helpers
      # I'll leave them for a while in case there's a bug in the tracker
      def print_snapshot_stack(tp)
        puts("===== STACK - #{tp.callee_id} (#{tp.event}) =====")
        puts(@snapshot_stack)
        puts("================ END STACK =================")
      end

      def print_state_comparison
        puts("###############")
        puts(@latest_instance_variables)
        puts(@instance_variables_snapshot)
        puts("###############")
      end
    end
  end
end
