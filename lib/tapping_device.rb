require "active_record"
require "tapping_device/version"
require "tapping_device/manageable"
require "tapping_device/payload"
require "tapping_device/trackable"
require "tapping_device/exceptions"
require "tapping_device/sql_tapping_methods"

class TappingDevice

  CALLER_START_POINT = 3
  C_CALLER_START_POINT = 2

  attr_reader :options, :calls, :trace_point, :target

  @devices = []
  @suspend_new = false

  include SqlTappingMethods
  extend Manageable

  def initialize(options = {}, &block)
    @block = block
    @output_block = nil
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

  def tap_passed!(object)
    track(object, condition: :tap_passed?)
  end

  def tap_assoc!(record)
    raise "argument should be an instance of ActiveRecord::Base" unless record.is_a?(ActiveRecord::Base)
    track(record, condition: :tap_associations?)
  end

  def and_print(payload_method)
    @output_block = -> (payload) { puts(payload.send(payload_method)) }
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
    new_device.instance_variable_set(:@target, @target)
    self.descendants << new_device
    new_device
  end

  def root_device
    options[:root_device]
  end

  def descendants
    options[:descendants]
  end

  private

  def track(object, condition:)
    @target = object
    @trace_point = TracePoint.new(:return) do |tp|
      if send(condition, object, tp)
        filepath, line_number = get_call_location(tp)

        next if should_be_skipped_by_paths?(filepath)

        payload = build_payload(tp: tp, filepath: filepath, line_number: line_number)

        record_call!(payload)

        stop_if_condition_fulfilled(payload)
      end
    end

    @trace_point.enable unless self.class.suspend_new

    self
  end

  def get_call_location(tp, padding: 0)
    caller(get_trace_index(tp) + padding).first.split(":")[0..1]
  end

  def get_trace_index(tp)
    if tp.event == :c_call
      C_CALLER_START_POINT
    else
      CALLER_START_POINT
    end
  end

  def get_traces(tp)
    if with_trace_to = options[:with_trace_to]
      trace_index = get_trace_index(tp)
      caller[trace_index..(trace_index + with_trace_to)]
    else
      []
    end
  end

  # this needs to be placed upfront so we can exclude noise before doing more work
  def should_be_skipped_by_paths?(filepath)
    options[:exclude_by_paths].any? { |pattern| pattern.match?(filepath) } ||
      (options[:filter_by_paths].present? && !options[:filter_by_paths].any? { |pattern| pattern.match?(filepath) })
  end

  def build_payload(tp:, filepath:, line_number:)
    arguments = {}
    tp.binding.local_variables.each { |name| arguments[name] = tp.binding.local_variable_get(name) }

    Payload.init({
      target: @target,
      receiver: tp.self,
      method_name: tp.callee_id,
      method_object: get_method_object_from(tp.self, tp.callee_id),
      arguments: arguments,
      return_value: (tp.return_value rescue nil),
      filepath: filepath,
      line_number: line_number,
      defined_class: tp.defined_class,
      trace: get_traces(tp),
      tp: tp
    })
  end

  def tap_init?(klass, tp)
    receiver = tp.self
    method_name = tp.callee_id

    if klass.ancestors.include?(ActiveRecord::Base)
      method_name == :new && receiver.ancestors.include?(klass)
    else
      method_name == :initialize && receiver.is_a?(klass)
    end
  end

  def tap_on?(object, tp)
    is_from_target?(object, tp)
  end

  def tap_associations?(object, tp)
    return false unless tap_on?(object, tp)

    model_class = object.class
    associations = model_class.reflections
    associations.keys.include?(tp.callee_id.to_s)
  end

  def tap_passed?(object, tp)
    # we don't care about calls from the device instance or helper methods
    return false if is_from_target?(self, tp)
    return false if tp.defined_class == TappingDevice::Trackable || tp.defined_class == TappingDevice

    method_object = get_method_object_from(tp.self, tp.callee_id)
    return false unless method_object.is_a?(Method)
    # if a no-arugment method is called, tp.binding.local_variables will be those local variables in the same scope
    # so we need to make sure the method takes arguments, then we can be sure that the locals are arguments
    return false unless method_object && method_object.arity.to_i > 0

    argument_values = tp.binding.local_variables.map { |name| tp.binding.local_variable_get(name) }

    argument_values.any? do |value|
      # during comparison, Ruby might perform data type conversion like calling `to_sym` on the value
      # but not every value supports every conversion methods
      object == value rescue false
    end
  rescue
    false
  end

  def get_method_object_from(target, method_name)
    target.method(method_name)
  rescue ArgumentError
    method_method = Object.method(:method).unbind
    method_method.bind(target).call(method_name)
  rescue NameError
    # if any part of the program uses Refinement to extend its methods
    # we might still get NoMethodError when trying to get that method outside the scope
    nil
  end

  def process_options(options)
    options[:filter_by_paths] ||= []
    options[:exclude_by_paths] ||= []
    options[:with_trace_to] ||= 50
    options[:root_device] ||= self
    options[:descendants] ||= []
    options[:track_as_records] ||= false
    options
  end

  def stop_if_condition_fulfilled(payload)
    if @stop_when&.call(payload)
      stop!
      root_device.stop!
    end
  end

  def is_from_target?(object, tp)
    comparsion = tp.self
    is_the_same_record?(object, comparsion) || object.__id__ == comparsion.__id__
  end

  def is_the_same_record?(target, comparsion)
    return false unless options[:track_as_records]
    if target.is_a?(ActiveRecord::Base) && comparsion.is_a?(target.class)
      primary_key = target.class.primary_key
      target.send(primary_key) && target.send(primary_key) == comparsion.send(primary_key)
    end
  end

  def record_call!(payload)
    return if @disabled

    @output_block.call(payload) if @output_block

    if @block
      root_device.calls << @block.call(payload)
    else
      root_device.calls << payload
    end
  end
end
