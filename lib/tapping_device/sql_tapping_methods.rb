require "tapping_device/sql_listener"

class TappingDevice
  module SqlTappingMethods
    @@sql_listeners = []

    ActiveSupport::Notifications.subscribe('sql.active_record') do |_1, _2, _3, _4, payload|
      if !["SCHEMA", "TRANSACTION"].include? payload[:name]
        @@sql_listeners.each do |listener|
          listener.payload[:sql] = payload[:sql]
          listener.payload[:binds] = payload[:binds]
          listener.block.call(listener.payload)
        end
      end
    end

    def tap_sql!(object)
      TracePoint.trace(:call) do |start_tp|
        method = start_tp.callee_id

        if is_from_target?(object, start_tp)
          call_location = caller(CALLER_START_POINT).first

          yield_parameters = build_yield_parameters(
            tp: start_tp,
            call_location: call_location,
            exclude_by_paths: @options[:exclude_by_paths] || [],
            filter_by_paths: @options[:filter_by_paths]
          )

          next unless yield_parameters

          yield_parameters[:trace] = caller[CALLER_START_POINT..(CALLER_START_POINT + @options[:with_trace_to])] if @options[:with_trace_to]

          # usually, AR's query methods (like `first`) will end up calling `find_by_sql`
          # then to TappingDevice, both `first` and `find_by_sql` generates the sql
          # but the results are duplicated, we should only consider the `first` call
          # so @in_call is used to determine if we're already in a middle of a call
          # it's not an optimal solution and should be updated
          next if @in_call

          @in_call = true

          sql_listener = SqlListenser.new(method, yield_parameters, @block)

          @@sql_listeners << sql_listener

          # return of the method call
          TracePoint.trace(:return) do |return_tp|
            if is_from_target?(object, return_tp)
              # if the method creates another Relation object
              if return_tp.defined_class == ActiveRecord::QueryMethods
                tap_sql!(return_tp.return_value)
              end

              # if it's a query method, end the sql tapping
              if return_tp.callee_id == method
                @@sql_listeners.delete(sql_listener)
                return_tp.disable
                @in_call = false
              end
            end
          end
        end
      end
    end
  end
end
