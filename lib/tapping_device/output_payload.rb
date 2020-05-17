class TappingDevice
  class OutputPayload < Payload
    def method_name
      ":#{super}"
    end

    def passed_at(with_method_head: false)
      arg_name = arguments.keys.detect { |k| arguments[k] == target }
      return unless arg_name
      msg = "Passed as '#{arg_name}' in '#{defined_class}##{method_name}' at #{location}"
      msg += "\n  > #{method_head.strip}" if with_method_head
      msg
    end

    PAYLOAD_ATTRIBUTES = {
      method_name: {symbol: "", color: "\u001b[33;1m"},
      location: {symbol: "from:", color: ""},
      sql: {symbol: "QUERIES", color: ""},
      return_value: {symbol: "=>", color: "\u001b[35;1m"},
      arguments: {symbol: "<=", color: "\u001b[32;1m"},
      defined_class: {symbol: "#", color: ""}
    }

    PAYLOAD_ATTRIBUTES.each do |attribute, options|
      color = options[:color]
      color_reset = "\u001b[0m"

      define_method "#{attribute}_with_color" do
        "#{color}#{send(attribute)}#{color_reset}"
      end

      PAYLOAD_ATTRIBUTES.each do |and_attribute, and_options|
        next if and_attribute == attribute
        and_symbol = and_options[:symbol]
        and_color = and_options[:color]

        define_method "#{attribute}_and_#{and_attribute}" do
          "#{send(attribute)} #{and_symbol} #{send(and_attribute)}"
        end

        define_method "#{attribute}_and_#{and_attribute}_with_color" do
          "#{color}#{send(attribute)}#{color_reset} #{and_color}#{and_symbol} #{send(and_attribute)}#{color_reset}"
        end
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
