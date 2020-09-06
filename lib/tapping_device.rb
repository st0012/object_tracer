# typed: true
require 'sorbet-runtime'
require "active_record"
require "active_support/core_ext/module/introspection"
require "pry" # for using Method#source

require "tapping_device/types/call_site"
require "tapping_device/version"
require "tapping_device/manageable"
require "tapping_device/payload"
require "tapping_device/output"
require "tapping_device/trackable"
require "tapping_device/configurable"
require "tapping_device/exceptions"
require "tapping_device/method_hijacker"
require "tapping_device/trackers/initialization_tracker"
require "tapping_device/trackers/passed_tracker"
require "tapping_device/trackers/association_call_tracker"
require "tapping_device/trackers/method_call_tracker"
require "tapping_device/trackers/mutation_tracker"

class TappingDevice
  extend T::Sig

  CALLER_START_POINT = 6
  C_CALLER_START_POINT = 5

  attr_reader :options, :calls, :trace_point, :target

  @devices = []
  @suspend_new = false

  extend Manageable

  include Configurable
  include Output::Helpers

  sig{params(options: Hash, block: T.nilable(Proc)).void}
  def initialize(options = {}, &block)
    @block = T.let(block, T.nilable(Proc))
    @output_block = T.let(nil, T.nilable(Proc))
    @options = T.let(process_options(options.dup), T::Hash[Symbol, T.untyped])
    @calls = T.let([], T::Array[Payload])
    @disabled = T.let(false, T::Boolean)
    @with_condition = T.let(nil, T.nilable(Proc))
    TappingDevice.devices << self
  end

  sig{params(block: T.nilable(Proc)).void}
  def with(&block)
    @with_condition = block
  end

  sig{params(block: T.nilable(Proc)).void}
  def set_block(&block)
    @block = block
  end

  sig{void}
  def stop!
    @disabled = true
    TappingDevice.delete_device(self)
  end

  sig{params(block: T.nilable(Proc)).void}
  def stop_when(&block)
    @stop_when = block
  end

  sig{returns(TappingDevice)}
  def create_child_device
    new_device = self.class.new(@options.merge(root_device: root_device), &@block)
    new_device.stop_when(&@stop_when)
    new_device.instance_variable_set(:@target, @target)
    self.descendants << new_device
    new_device
  end

  sig{returns(TappingDevice)}
  def root_device
    options[:root_device]
  end

  sig{returns(T::Array[TappingDevice])}
  def descendants
    options[:descendants]
  end

  sig{params(object: T.untyped).returns(TappingDevice)}
  def track(object)
    @target = object
    validate_target!

    MethodHijacker.new(@target).hijack_methods! if options[:hijack_attr_methods]

    @trace_point = build_minimum_trace_point(Array(options[:event_type])) do |payload|
      record_call!(payload)

      stop_if_condition_fulfilled!(payload)
    end

    @trace_point.enable unless TappingDevice.suspend_new

    self
  end

  private

  sig{params(event_types: T::Array[Symbol]).returns(TracePoint)}
  def build_minimum_trace_point(event_types)
    # sorbet doesn't accept splat arguments
    # see https://sorbet.org/docs/error-reference#7019
    T.unsafe(TracePoint).new(*event_types) do |tp|
      next unless filter_condition_satisfied?(tp)

      call_site = get_call_location(tp)
      payload = build_payload(tp: tp, call_site: call_site)

      unless @options[:force_recording]
        next if is_tapping_device_call?(tp)
        next if should_be_skipped_by_paths?(call_site.filepath)
        next unless with_condition_satisfied?(payload)
        next if payload.is_private_call? && @options[:ignore_private]
        next if !payload.is_private_call? && @options[:only_private]
      end

      yield(payload)
    end
  end

  sig{void}
  def validate_target!; end

  sig {params(tp: TracePoint).returns(T::Boolean)}
  def filter_condition_satisfied?(tp)
    false
  end

  # this needs to be placed upfront so we can exclude noise before doing more work
  sig {params(filepath: String).returns(T::Boolean)}
  def should_be_skipped_by_paths?(filepath)
    options[:exclude_by_paths].any? { |pattern| pattern.match?(filepath) } ||
      (options[:filter_by_paths].present? && !options[:filter_by_paths].any? { |pattern| pattern.match?(filepath) })
  end

  sig {params(tp: TracePoint).returns(T::Boolean)}
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

  sig {params(payload: Payload).returns(T::Boolean)}
  def with_condition_satisfied?(payload)
    @with_condition.blank? || @with_condition.call(payload)
  end

  sig {params(tp: TracePoint, call_site: Types::CallSite).returns(Payload)}
  def build_payload(tp:, call_site:)
    Payload.init({
      target: @target,
      receiver: tp.self,
      method_name: tp.callee_id,
      method_object: get_method_object_from(tp.self, tp.callee_id),
      arguments: collect_arguments(tp),
      return_value: (tp.return_value rescue nil),
      filepath: call_site.filepath,
      line_number: call_site.line_number,
      defined_class: tp.defined_class,
      trace: get_traces(tp),
      is_private_call?: tp.defined_class.private_method_defined?(tp.callee_id),
      tag: options[:tag],
      tp: tp
    })
  end

  sig {params(target: T.untyped, method_name: Symbol).returns(T.nilable(Method))}
  def get_method_object_from(target, method_name)
    Object.instance_method(:method).bind(target).call(method_name)
  rescue NameError
    # if any part of the program uses Refinement to extend its methods
    # we might still get NoMethodError when trying to get that method outside the scope
    nil
  end

  sig {params(tp: TracePoint, padding: Integer).returns(Types::CallSite)}
  def get_call_location(tp, padding: 0)
    traces = caller(get_trace_index(tp) + padding) || []
    target_trace = traces.first || ""
    filepath, line_number = target_trace.split(":")
    Types::CallSite.new(filepath: filepath || "", line_number: line_number || "")
  end

  sig {params(tp: TracePoint).returns(Integer)}
  def get_trace_index(tp)
    if tp.event == :c_call
      C_CALLER_START_POINT
    else
      CALLER_START_POINT
    end
  end

  sig {params(tp: TracePoint).returns(T::Array[String])}
  def get_traces(tp)
    if with_trace_to = options[:with_trace_to]
      trace_index = get_trace_index(tp)
      Array(caller[trace_index..(trace_index + with_trace_to)])
    else
      []
    end
  end

  sig {params(tp: TracePoint).returns(T::Hash[Symbol, T.untyped])}
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

  sig {params(options: T::Hash[Symbol, T.untyped]).returns(T::Hash[Symbol, T.untyped])}
  def process_options(options)
    options[:filter_by_paths] ||= config[:filter_by_paths]
    options[:exclude_by_paths] ||= config[:exclude_by_paths]
    options[:with_trace_to] ||= config[:with_trace_to]
    options[:event_type] ||= config[:event_type]
    options[:hijack_attr_methods] ||= config[:hijack_attr_methods]
    options[:track_as_records] ||= config[:track_as_records]
    options[:ignore_private] ||= config[:ignore_private]
    options[:only_private] ||= config[:only_private]
    # for debugging the gem more easily
    options[:force_recording] ||= false

    options[:descendants] ||= []
    options[:root_device] ||= self

    options[:exclude_by_paths] << /sorbet-runtime/
    options
  end

  sig {params(tp: TracePoint).returns(T::Boolean)}
  def is_from_target?(tp)
    comparsion = tp.self
    is_the_same_record?(comparsion) || target.__id__ == comparsion.__id__
  end

  sig {params(comparsion: T.untyped).returns(T::Boolean)}
  def is_the_same_record?(comparsion)
    return false unless options[:track_as_records]

    if target.is_a?(ActiveRecord::Base) && comparsion.is_a?(target.class)
      primary_key = target.class.primary_key
      target.send(primary_key) && target.send(primary_key) == comparsion.send(primary_key)
    else
      false
    end
  end

  sig {params(payload: Payload).void}
  def record_call!(payload)
    return if @disabled

    write_output!(payload) if @output_writer

    if @block
      root_device.calls << @block.call(payload)
    else
      root_device.calls << payload
    end
  end

  sig {params(payload: Payload).void}
  def write_output!(payload)
    @output_writer.write!(payload)
  end

  sig {params(payload: Payload).void}
  def stop_if_condition_fulfilled!(payload)
    if @stop_when&.call(payload)
      stop!
      root_device.stop!
    end
  end

  sig {returns(T::Hash[Symbol, T.untyped])}
  def config
    TappingDevice.config
  end
end
