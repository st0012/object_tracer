require "pry"
require "pry-stack_explorer"
require "tapping_device/output/payload"

class TappingDevice
  class PowerCallerStack
    include Enumerable

    def initialize
      frame_manager = PryStackExplorer.frame_manager(Pry.new)
      method_bindings = frame_manager.bindings.select { |method_binding| method_binding.frame_type == :method }
      power_caller_index = method_bindings.index { |b| b.frame_description.to_sym == :power_caller }
      @entries = method_bindings[power_caller_index+1..].map do |b|
        PowerEntry.new(b)
      end
    end

    def each(&block)
      @entries.each(&block)
    end

    def to_s
      @entries.map(&:to_s).join("\n")
    end
  end

  class PowerEntry
    attr_reader :method_name, :method, :receiver, :arguments

    def initialize(method_binding)
      iseq = method_binding.instance_variable_get(:@iseq)
      @filepath = iseq.path
      @line_number = iseq.first_lineno
      @method_name = method_binding.frame_description
      @receiver = method_binding.receiver
      @method = Object.instance_method(:method).bind(@receiver).call(method_name)
      method_parameters = @method.parameters.map { |parameter| parameter[1] }
      @arguments = method_binding.local_variables.each_with_object({}) do |name, args|
        args[name] = method_binding.local_variable_get(name) if method_parameters.include?(name)
      end
    end

    def to_payload
      Output::Payload.init({
        target: nil,
        receiver: @receiver,
        method_name: @method_name,
        method_object: @method,
        arguments: @arguments,
        return_value: nil,
        filepath: @filepath,
        line_number: @line_number,
        defined_class: @method.owner,
        trace: [],
        is_private_call?: @method.owner.private_method_defined?(@method_name),
        tp: nil
      })
    end

    def to_s
      to_payload.detail_call_info
    end
  end
end
