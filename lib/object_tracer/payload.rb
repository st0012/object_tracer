class ObjectTracer
  class Payload
    ATTRS = [
      :target, :receiver, :method_name, :method_object, :arguments, :return_value, :filepath, :line_number,
      :defined_class, :trace, :tag, :tp, :ivar_changes, :is_private_call
    ]

    attr_accessor(*ATTRS)

    alias :is_private_call? :is_private_call

    def initialize(
      target:, receiver:, method_name:, method_object:, arguments:, return_value:, filepath:, line_number:,
      defined_class:, trace:, tag:, tp:, is_private_call:
    )
      @target = target
      @receiver = receiver
      @method_name = method_name
      @method_object = method_object
      @arguments = arguments
      @return_value = return_value
      @filepath = filepath
      @line_number = line_number
      @defined_class = defined_class
      @trace = trace
      @tag = tag
      @tp = tp
      @ivar_changes = {}
      @is_private_call = is_private_call
    end

    def method_head
      method_object.source.strip if method_object.source_location
    end

    def location(options = {})
      "#{filepath}:#{line_number}"
    end
  end
end
