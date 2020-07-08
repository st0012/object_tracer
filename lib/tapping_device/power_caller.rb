require "pry"
require "pry-stack_explorer"
require "tapping_device/output/payload"

class TappingDevice
  class PowerCallerStack
    include Enumerable

    def initialize
      frame_manager = PryStackExplorer.frame_manager(Pry.new)
      frames = frame_manager.bindings
      power_caller_index = frames.index { |b| b.frame_description&.to_sym == :power_caller }
      @entries = frames[power_caller_index+2..].map do |b|
        case b.frame_type
        when :method
          MethodEntry.new(b)
        when :block
          BlockEntry.new(b)
        end
      end
    end

    def each(&block)
      @entries.each(&block)
    end

    def to_s
      @entries.compact.map(&:to_s).join("\n")
    end
  end

  class PowerEntry
    attr_reader :frame, :filepath, :line_number, :receiver

    def initialize(frame)
      @frame = frame
      @filepath = frame.eval("__FILE__")
      @line_number = frame.eval("__LINE__")
      @receiver = frame.receiver
    end

    def to_payload
      Output::Payload.init({
        target: nil,
        receiver: @receiver,
        method_name: method_name,
        method_object: method,
        arguments: arguments,
        return_value: nil,
        filepath: @filepath,
        line_number: @line_number,
        defined_class: defined_class,
        trace: [],
        is_private_call?: is_private_call?,
        tp: nil
      })
    end

    def to_s
      to_payload.caller_entry
    end
  end

  class MethodEntry < PowerEntry
    def method_name
      @frame.frame_description
    end

    def method
      @method ||= Object.instance_method(:method).bind(@receiver).call(method_name)
    end

    def arguments
      @arguments ||= frame.local_variables.each_with_object({}) do |name, args|
        args[name] = frame.local_variable_get(name) if method_parameters.include?(name)
      end
    end

    def method_parameters
      method.parameters.map { |parameter| parameter[1] }
    end

    def defined_class
      method.owner
    end

    def is_private_call?
      method.owner.private_method_defined?(method_name)
    end
  end

  class BlockEntry < PowerEntry
    def method_name
      "block in #{frame.eval("__method__")}"
    end

    def method
    end

    def arguments
      @arguments ||= frame.local_variables.each_with_object({}) do |name, args|
        args[name] = frame.local_variable_get(name)
      end
    end

    def defined_class
    end

    def is_private_call?
      false
    end
  end
end
