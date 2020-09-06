# typed: true
class TappingDevice
  module Trackers
    class MutationTracker < TappingDevice
      extend T::Sig

      def initialize(options, &block)
        options[:hijack_attr_methods] = true
        super
        @snapshot_stack = []
      end

      sig{params(object: T.untyped).returns(TappingDevice)}
      def track(object)
        super
        insert_snapshot_taking_trace_point
        self
      end

      sig{void}
      def stop!
        super
        @ivar_snapshot_trace_point.disable
      end

      private

      # we need to snapshot instance variables at the beginning of every method call
      # so we can get a correct state for the later comparison
      sig{void}
      def insert_snapshot_taking_trace_point
        @ivar_snapshot_trace_point = build_minimum_trace_point([:call]) do
          snapshot_instance_variables
        end

        @ivar_snapshot_trace_point.enable unless TappingDevice.suspend_new
      end

      sig {params(tp: TracePoint).returns(T::Boolean)}
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

      sig {params(tp: TracePoint, call_site: Types::CallSite).returns(Payload)}
      def build_payload(tp:, call_site:)
        payload = super

        if change_capturing_event?(tp)
          payload[:ivar_changes] = capture_ivar_changes
        end

        payload
      end

      sig{returns(Hash)}
      def capture_ivar_changes
        changes = {}

        additional_keys = @latest_instance_variables.keys - @instance_variables_snapshot.keys
        additional_keys.each do |key|
          changes[key] = {before: Output::Payload::UNDEFINED_MARK, after: @latest_instance_variables[key]}
        end

        removed_keys = @instance_variables_snapshot.keys - @latest_instance_variables.keys
        removed_keys.each do |key|
          changes[key] = {before: @instance_variables_snapshot[key], after: Output::Payload::UNDEFINED_MARK}
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

      sig {params(tp: TracePoint).returns(T::Boolean)}
      def snapshot_capturing_event?(tp)
        tp.event == :call
      end

      sig {params(tp: TracePoint).returns(T::Boolean)}
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
