require "active_record"
require "tapping_device/version"
require "tapping_device/trackable"
require "tapping_device/exceptions"
require "tapping_device/sql_tapping_methods"

class TappingDevice

  CALLER_START_POINT = 3
  C_CALLER_START_POINT = 2

  attr_reader :options, :calls, :trace_point

  @@devices = []
  @@suspend_new = false

  include SqlTappingMethods

  def self.suspend_new
    @@suspend_new
  end

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
    @options = process_options(options)
    @calls = []
    @disabled = false
    self.class.devices << self
  end

  def tap_init!(klass)
    raise "argument should be a class, got #{klass}" unless klass.is_a?(Class)
    track(klass, condition: :tap_init?)
  end

  def tap_on!(object)
    track(object, condition: :tap_on?)
  end

  def tap_assoc!(record)
    raise "argument should be an instance of ActiveRecord::Base" unless record.is_a?(ActiveRecord::Base)
    track(record, condition: :tap_associations?)
  end

  def set_block(&block)
    @block = block
  end

  def stop!
    @disabled = true
    self.class.delete_device(self)
  end

  def stop_when(&block)
    @stop_when = block
  end

  def create_child_device
    new_device = self.class.new(@options.merge(root_device: root_device), &@block)
    new_device.stop_when(&@stop_when)
    self.descendants << new_device
    new_device
  end

  def root_device
    options[:root_device]
  end

  def descendants
    options[:descendants]
  end

  def record_call!(yield_parameters)
    return if @disabled

    if @block
      root_device.calls << @block.call(yield_parameters)
    else
      root_device.calls << yield_parameters
    end
  end

  private

  def track(object, condition:)
    @trace_point = TracePoint.new(:return) do |tp|
      validation_params = {
        receiver: tp.self,
        method_name: tp.callee_id
      }

      if send(condition, object, validation_params)
        filepath, line_number = get_call_location(tp)

        next if should_be_skip_by_paths?(filepath)

        yield_parameters = build_yield_parameters(tp: tp, filepath: filepath, line_number: line_number)

        record_call!(yield_parameters)

        stop_if_condition_fulfilled(yield_parameters)
      end
    end

    @trace_point.enable unless @@suspend_new

    self
  end

  def get_call_location(tp)
    if tp.event == :c_call
      caller(C_CALLER_START_POINT)
    else
      caller(CALLER_START_POINT)
    end.first.split(":")[0..1]
  end

  # this needs to be placed upfront so we can exclude noise before doing more work
  def should_be_skip_by_paths?(filepath)
    options[:exclude_by_paths].any? { |pattern| pattern.match?(filepath) } ||
      (options[:filter_by_paths].present? && !options[:filter_by_paths].any? { |pattern| pattern.match?(filepath) })
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
      trace: caller[CALLER_START_POINT..(CALLER_START_POINT + options[:with_trace_to])],
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

  def process_options(options)
    options[:filter_by_paths] ||= []
    options[:exclude_by_paths] ||= []
    options[:with_trace_to] ||= 50
    options[:root_device] ||= self
    options[:descendants] ||= []
    options
  end

  def stop_if_condition_fulfilled(yield_parameters)
    if @stop_when&.call(yield_parameters)
      stop!
      root_device.stop!
    end
  end

  def is_from_target?(object, tp)
    object.__id__ == tp.self.__id__
  end
end
