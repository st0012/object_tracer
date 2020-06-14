require "active_record"
require "active_support/core_ext/module/introspection"
require "pry" # for using Method#source

require "tapping_device/version"
require "tapping_device/manageable"
require "tapping_device/payload"
require "tapping_device/output/payload"
require "tapping_device/trackable"
require "tapping_device/exceptions"
require "tapping_device/method_hijacker"
require "tapping_device/trackers/initialization_tracker"
require "tapping_device/trackers/passed_tracker"
require "tapping_device/trackers/association_call_tracker"
require "tapping_device/trackers/method_call_tracker"
require "tapping_device/trackers/mutation_tracker"

class TappingDevice

  CALLER_START_POINT = 3
  C_CALLER_START_POINT = 2

  attr_reader :options, :calls, :trace_point, :target

  @devices = []
  @suspend_new = false

  extend Manageable

  def initialize(options = {}, &block)
    @block = block
    @output_block = nil
    @options = process_options(options)
    @calls = []
    @disabled = false
    @with_condition = nil
    TappingDevice.devices << self
  end

  def and_print(payload_method = nil, &block)
    @output_block =
      if block
        -> (output_payload) { puts(block.call(output_payload)) }
      elsif payload_method
        -> (output_payload) { puts(output_payload.send(payload_method)) }
      else
        raise "need to provide either a payload method name or a block"
      end

    self
  end

  def with(&block)
    @with_condition = block
  end

  def set_block(&block)
    @block = block
  end

  def stop!
    @disabled = true
    TappingDevice.delete_device(self)
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

  def track(object)
    @target = object
    validate_target!

    MethodHijacker.new(@target).hijack_methods! if options[:hijack_attr_methods]

    @trace_point = build_minimum_trace_point(event_type: options[:event_type]) do |payload|
      record_call!(payload)

      stop_if_condition_fulfilled!(payload)
    end

    @trace_point.enable unless TappingDevice.suspend_new

    self
  end

  private

  def build_minimum_trace_point(event_type:)
    TracePoint.new(event_type) do |tp|
      next unless filter_condition_satisfied?(tp)
      next if is_tapping_device_call?(tp)

      filepath, line_number = get_call_location(tp)
      payload = build_payload(tp: tp, filepath: filepath, line_number: line_number)

      next if should_be_skipped_by_paths?(filepath)
      next unless with_condition_satisfied?(payload)

      yield(payload)
    end
  end

  def validate_target!; end

  def filter_condition_satisfied?(tp)
    false
  end

  # this needs to be placed upfront so we can exclude noise before doing more work
  def should_be_skipped_by_paths?(filepath)
    options[:exclude_by_paths].any? { |pattern| pattern.match?(filepath) } ||
      (options[:filter_by_paths].present? && !options[:filter_by_paths].any? { |pattern| pattern.match?(filepath) })
  end

  def is_tapping_device_call?(tp)
    if tp.defined_class == TappingDevice::Trackable || tp.defined_class == TappingDevice
      return true
    end

    if Module.respond_to?(:module_parents)
      tp.defined_class.module_parents.include?(TappingDevice)
    elsif Module.respond_to?(:parents)
      tp.defined_class.parents.include?(TappingDevice)
    end
  end

  def with_condition_satisfied?(payload)
    @with_condition.blank? || @with_condition.call(payload)
  end

  def build_payload(tp:, filepath:, line_number:)
    Payload.init({
      target: @target,
      receiver: tp.self,
      method_name: tp.callee_id,
      method_object: get_method_object_from(tp.self, tp.callee_id),
      arguments: collect_arguments(tp),
      return_value: (tp.return_value rescue nil),
      filepath: filepath,
      line_number: line_number,
      defined_class: tp.defined_class,
      trace: get_traces(tp),
      tp: tp
    })
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

  def collect_arguments(tp)
    parameters =
      if RUBY_VERSION.to_f >= 2.6
        tp.parameters
      else
        get_method_object_from(tp.self, tp.callee_id)&.parameters || []
      end.map { |parameter| parameter[1] }

    tp.binding.local_variables.each_with_object({}) do |name, args|
      args[name] = tp.binding.local_variable_get(name) if parameters.include?(name)
    end
  end

  def process_options(options)
    options[:filter_by_paths] ||= []
    options[:exclude_by_paths] ||= []
    options[:with_trace_to] ||= 50
    options[:root_device] ||= self
    options[:event_type] ||= :return
    options[:descendants] ||= []
    options[:hijack_attr_method] ||= false
    options[:track_as_records] ||= false
    options
  end

  def is_from_target?(tp)
    comparsion = tp.self
    is_the_same_record?(comparsion) || target.__id__ == comparsion.__id__
  end

  def is_the_same_record?(comparsion)
    return false unless options[:track_as_records]
    if target.is_a?(ActiveRecord::Base) && comparsion.is_a?(target.class)
      primary_key = target.class.primary_key
      target.send(primary_key) && target.send(primary_key) == comparsion.send(primary_key)
    end
  end

  def record_call!(payload)
    return if @disabled

    @output_block.call(Output::Payload.init(payload)) if @output_block

    if @block
      root_device.calls << @block.call(payload)
    else
      root_device.calls << payload
    end
  end

  def stop_if_condition_fulfilled!(payload)
    if @stop_when&.call(payload)
      stop!
      root_device.stop!
    end
  end
end
