class TappingDevice
  class OutputPayload < Payload
    alias :raw_arguments :arguments
    alias :raw_return_value :return_value

    def method_name(options = {})
      ":#{super(options)}"
    end

    def arguments(options = {})
      generate_string_result(raw_arguments, options[:inspect])
    end

    def return_value(options = {})
      generate_string_result(raw_return_value, options[:inspect])
    end

    COLORS = {
      yellow: "\u001b[33;1m",
      megenta: "\u001b[35;1m",
      cyan: "\u001b[36;1m",
      reset: "\u001b[0m"
    }

    PAYLOAD_ATTRIBUTES = {
      method_name: {symbol: "", color: COLORS[:yellow]},
      location: {symbol: "from:", color: ""},
      sql: {symbol: "QUERIES", color: ""},
      return_value: {symbol: "=>", color: COLORS[:megenta]},
      arguments: {symbol: "<=", color: COLORS[:cyan]},
      defined_class: {symbol: "#", color: ""}
    }

    PAYLOAD_ATTRIBUTES.each do |attribute, attribute_options|
      color = attribute_options[:color]

      alias_method "original_#{attribute}".to_sym, attribute

      define_method attribute do |options = {}|
        call_result = send("original_#{attribute}", options)

        if options[:colorize]
          "#{color}#{call_result}#{COLORS[:reset]}"
        else
          call_result
        end
      end

      define_method "#{attribute}_with_color" do |options = {}|
        send(attribute, options.merge(colorize: true))
      end

      PAYLOAD_ATTRIBUTES.each do |and_attribute, and_attribute_options|
        next if and_attribute == attribute

        define_method "#{attribute}_and_#{and_attribute}" do |options = {}|
          "#{send(attribute, options)} #{and_attribute_options[:symbol]} #{send(and_attribute, options)}"
        end

        define_method "#{attribute}_and_#{and_attribute}_with_color" do |options = {}|
          send("#{attribute}_and_#{and_attribute}", options.merge(colorize: true))
        end
      end
    end

    def passed_at(with_method_head: false)
      arg_name = raw_arguments.keys.detect { |k| raw_arguments[k] == target }
      return unless arg_name
      msg = "Passed as '#{arg_name}' in '#{defined_class}##{method_name}' at #{location}"
      msg += "\n  > #{method_head.strip}" if with_method_head
      msg
    end

    def detail_call_info(options = {})
      <<~MSG
      #{method_name_and_defined_class(options)}
          from: #{location(options)}
          <= #{arguments(options)}
          => #{return_value(options)}

      MSG
    end

    private

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
