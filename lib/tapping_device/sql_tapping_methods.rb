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
      @trace_point = TracePoint.new(:call, :c_call) do |start_tp|
        method = start_tp.callee_id

        if is_from_target?(object, start_tp)
          filepath, line_number = get_call_location(start_tp)

          next if should_be_skip_by_paths?(filepath)

          yield_parameters = build_yield_parameters(tp: start_tp, filepath: filepath, line_number: line_number)

          # usually, AR's query methods (like `first`) will end up calling `find_by_sql`
          # then to TappingDevice, both `first` and `find_by_sql` generates the sql
          # but the results are duplicated, we should only consider the `first` call
          next unless @call_stack.empty?

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

          # return of the method call
          TracePoint.trace(:return) do |return_tp|
            if is_from_target?(object, return_tp)
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
            end
          end
        end
      end

      @trace_point.enable unless self.class.suspend_new

      self
    end
  end
end
