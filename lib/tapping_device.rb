require "active_record"
require "tapping_device/version"
require "tapping_device/trackable"
require "tapping_device/exceptions"
require "tapping_device/sql_tapping_methods"

class TappingDevice
  include SqlTappingMethods

  CALLER_START_POINT = 2

  attr_reader :options, :calls, :trace_point

  @@devices = []
  @@suspend_new = false

  # list all registered devices
  def self.devices
    @@devices
  end

  # disable given device and remove it from registered list
  def self.delete_device(device)
    device.trace_point&.disable
    @@devices -= [device]
  end

  # stops all registered devices and remove them from registered list
  def self.stop_all!
    @@devices.each(&:stop!)
  end

  # suspend enabling new trace points
  # user can still create new Device instances, but they won't be functional
  def self.suspend_new!
    @@suspend_new = true
  end

  # reset everything to clean state and disable all devices
  def self.reset!
    @@suspend_new = false
    stop_all!
  end

  def initialize(options = {}, &block)
    @block = block
    @options = options
    @calls = []
    self.class.devices << self
  end

  def tap_init!(klass)
    raise "argument should be a class, got #{klass}" unless klass.is_a?(Class)
    track(klass, condition: :tap_init?, block: @block, **@options)
  end

  def tap_on!(object)
    track(object, condition: :tap_on?, block: @block, **@options)
  end

  def tap_assoc!(record)
    raise "argument should be an instance of ActiveRecord::Base" unless record.is_a?(ActiveRecord::Base)
    track(record, condition: :tap_associations?, block: @block, **@options)
  end

  def set_block(&block)
    @block = block
  end

  def stop!
    self.class.delete_device(self)
  end

  def stop_when(&block)
    @stop_when = block
  end

  private

  def track(object, condition:, block:, with_trace_to: nil, exclude_by_paths: [], filter_by_paths: nil)
    @trace_point = TracePoint.new(:return) do |tp|
      validation_params = {
        receiver: tp.self,
        method_name: tp.callee_id
      }

      if send(condition, object, validation_params)
        call_location = caller(CALLER_START_POINT).first
        filepath, line_number = split_call_location(call_location)

        next if should_be_skip_by_paths?(filepath, exclude_by_paths, filter_by_paths)

        yield_parameters = build_yield_parameters(
          tp: tp,
          filepath: filepath,
          line_number: line_number
        )
        yield_parameters[:trace] = caller[CALLER_START_POINT..(CALLER_START_POINT + with_trace_to)] if with_trace_to

        if block
          @calls << block.call(yield_parameters)
        else
          @calls << yield_parameters
        end
      end

      stop! if @stop_when&.call(yield_parameters)
    end

    @trace_point.enable unless @@suspend_new

    self
  end

  def split_call_location(call_location)
    call_location.split(":")[0..1]
  end

  # this needs to be placed upfront so we can exclude noise before doing more work
  def should_be_skip_by_paths?(filepath, exclude_by_paths, filter_by_paths)
    return true if exclude_by_paths.any? { |pattern| pattern.match?(filepath) }

    if filter_by_paths
      return true unless filter_by_paths.any? { |pattern| pattern.match?(filepath) }
    end
  end

  def build_yield_parameters(tp:, filepath:, line_number:)
    arguments = tp.binding.local_variables.map { |n| [n, tp.binding.local_variable_get(n)] }

    {
      receiver: tp.self,
      method_name: tp.callee_id,
      arguments: arguments,
      return_value: (tp.return_value rescue nil),
      filepath: filepath,
      line_number: line_number,
      defined_class: tp.defined_class,
      trace: [],
      tp: tp
    }
  end

  def tap_init?(klass, parameters)
    receiver = parameters[:receiver]
    method_name = parameters[:method_name]

    if klass.ancestors.include?(ActiveRecord::Base)
      method_name == :new && receiver.ancestors.include?(klass)
    else
      method_name == :initialize && receiver.is_a?(klass)
    end
  end

  def tap_on?(object, parameters)
    parameters[:receiver].__id__ == object.__id__
  end

  def tap_associations?(object, parameters)
    return false unless tap_on?(object, parameters)

    model_class = object.class
    associations = model_class.reflections
    associations.keys.include?(parameters[:method_name].to_s)
  end

  def is_from_target?(object, tp)
    object.__id__ == tp.self.__id__
  end
end
