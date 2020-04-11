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

    SYMBOLS = {
      location: "from:",
      sql: "QUERIES",
      return_value: "=>",
      arguments: "<=",
      defined_class: "#"
    }

    SYMBOLS.each do |name, symbol|
      define_method "method_name_and_#{name}" do
        ":#{method_name} #{symbol} #{send(name)}"
      end
    end

    def detail_call_info(inspect: false)
      arguments_output = generate_string_result(arguments, inspect)
      return_value_output = generate_string_result(return_value, inspect)

      <<~MSG
      #{method_name_and_defined_class}
          from: #{location}
          <= #{arguments_output}
          => #{return_value_output}

      MSG
    end

    def generate_string_result(obj, inspect)
      case obj
      when Array
        array_to_string(obj, inspect)
      when Hash
        hash_to_string(obj, inspect)
      when String
        "\"#{obj}\""
      else
        inspect ? obj.inspect : obj.to_s
      end
    end

    def array_to_string(array, inspect)
      elements_string = array.map do |elem|
        generate_string_result(elem, inspect)
      end.join(", ")
      "[#{elements_string}]"
    end

    def hash_to_string(hash, inspect)
      elements_string = hash.map do |key, value|
        "#{key.to_s}: #{generate_string_result(value, inspect)}"
      end.join(", ")
      "{#{elements_string}}"
    end

    def obj_to_string(element, inspect)
      to_string_method = inspect ? :inspect : :to_s

      if !inspect && element.is_a?(String)
        "\"#{element}\""
      else
        element.send(to_string_method)
      end
    end
  end
end
