class TappingDevice
  module SqlTappingMethods
    CALL_STACK_SKIPPABLE_METHODS = [:transaction, :tap]

    class SQLListener
      def call(name, start, finish, message_id, values)
      end
    end

    @@sql_listener = SQLListener.new

    ActiveSupport::Notifications.subscribe("sql.active_record", @@sql_listener)

    def tap_sql!(object)
      @call_stack = []
      @trace_point = with_trace_point_on_target(object, event: [:call, :c_call]) do |start_tp|
        method = start_tp.callee_id
        # we need extra padding because of `with_trace_point_on_target`
        filepath, line_number = get_call_location(start_tp, padding: 1)

        next if should_be_skipped_by_paths?(filepath) || already_recording?

        yield_parameters = build_yield_parameters(tp: start_tp, filepath: filepath, line_number: line_number)

        device = nil
        unless CALL_STACK_SKIPPABLE_METHODS.include?(method)
          @call_stack.push(method)

          device = TappingDevice.new do |payload|
            arguments = payload.arguments
            values = arguments[:values]
            next if ["SCHEMA", "TRANSACTION", nil].include? values[:name]
            yield_parameters[:sql] = values[:sql]
            record_call!(yield_parameters)
          end
          device.tap_on!(@@sql_listener)
        end

        with_trace_point_on_target(object, event: :return) do |return_tp|
          # if it's a query method, end the sql tapping
          if return_tp.callee_id == method
            # if the method creates another Relation object
            if return_tp.defined_class == ActiveRecord::QueryMethods
              create_child_device.tap_sql!(return_tp.return_value)
            end

            device&.stop!

            return_tp.disable
            @call_stack.pop

            stop_if_condition_fulfilled(yield_parameters)
          end
        end.enable
      end

      @trace_point.enable unless self.class.suspend_new

      self
    end
  end

  private

  # usually, AR's query methods (like `first`) will end up calling `find_by_sql`
  # then to TappingDevice, both `first` and `find_by_sql` generates the sql
  # but the results are duplicated, we should only consider the `first` call
  def already_recording?
    !@call_stack.empty?
  end

  def with_trace_point_on_target(object, event:)
    TracePoint.new(*event) do |tp|
      if is_from_target?(object, tp)
        yield(tp)
      end
    end
  end
end
