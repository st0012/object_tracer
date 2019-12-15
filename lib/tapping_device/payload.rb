class TappingDevice
  class Payload < Hash
    ATTRS = [
      :target, :receiver, :method_name, :method_object, :arguments, :return_value, :filepath, :line_number,
      :defined_class, :trace, :tp, :sql
    ]

    ATTRS.each do |attr|
      define_method attr do
        self[attr]
      end
    end

    def self.init(hash)
      h = new
      hash.each do |k, v|
        h[k] = v
      end
      h
    end

    def passed_at(with_method_head: false)
      arg_name = arguments.keys.detect { |k| arguments[k] == target }
      return unless arg_name
      msg = "Passed as '#{arg_name}' in method ':#{method_name}'"
      msg += "\n  > #{method_head.strip}" if with_method_head
      msg += "\n  at #{location}"
      msg
    end

    def method_head
      source_file, source_line = method_object.source_location
      IO.readlines(source_file)[source_line-1]
    end

    def location
      "#{filepath}:#{line_number}"
    end

    def method_name_and_location
      "Method: :#{method_name}, line: #{location}"
    end

    def method_name_and_arguments
      "Method: :#{method_name}, argments: #{arguments.to_s}"
    end
  end
end
