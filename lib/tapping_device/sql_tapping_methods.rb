require "tapping_device/sql_listener"

class TappingDevice
  module SqlTappingMethods
    @@sql_listeners = []

    ActiveSupport::Notifications.subscribe('sql.active_record') do |_1, _2, _3, _4, payload|
      if !["SCHEMA", "TRANSACTION"].include? payload[:name]
        @@sql_listeners.each do |listener|
          listener.payload[:sql] = payload[:sql]
          listener.payload[:binds] = payload[:binds]
          listener.device.record_call!(listener.payload)
        end
      end
    end

    def tap_sql!(object)
      @call_stack = []
      @trace_point = TracePoint.new(:call, :b_call, :c_call) do |start_tp|
        method = start_tp.callee_id

        if is_from_target?(object, start_tp)
          filepath, line_number = get_call_location(start_tp)

          next if should_be_skip_by_paths?(filepath)

          yield_parameters = build_yield_parameters(tp: start_tp, filepath: filepath, line_number: line_number)

          # usually, AR's query methods (like `first`) will end up calling `find_by_sql`
          # then to TappingDevice, both `first` and `find_by_sql` generates the sql
          # but the results are duplicated, we should only consider the `first` call
          # so @in_call is used to determine if we're already in a middle of a call
          # it's not an optimal solution and should be updated
          next unless @call_stack.empty?

          @call_stack.push(method)

          sql_listener = SqlListenser.new(method, yield_parameters, self)

          @@sql_listeners << sql_listener

          # return of the method call
          TracePoint.trace(:return) do |return_tp|
            if is_from_target?(object, return_tp)
              # if it's a query method, end the sql tapping
              if return_tp.callee_id == method
                # if the method creates another Relation object
                if return_tp.defined_class == ActiveRecord::QueryMethods
                  create_child_device.tap_sql!(return_tp.return_value)
                end

                @@sql_listeners.delete(sql_listener)
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
