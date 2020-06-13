class TappingDevice
  class OutputPayload < Payload
    UNDEFINED = "[undefined]"

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

    COLOR_CODES = {
      green: 10,
      yellow: 11,
      blue: 12,
      megenta: 13,
      cyan: 14,
      orange: 214
    }

    COLORS = COLOR_CODES.each_with_object({}) do |(name, code), hash|
      hash[name] = "\u001b[38;5;#{code}m"
    end.merge(
      reset: "\u001b[0m",
      nocolor: ""
    )

    PAYLOAD_ATTRIBUTES = {
      method_name: {symbol: "", color: COLORS[:blue]},
      location: {symbol: "from:", color: COLORS[:green]},
      return_value: {symbol: "=>", color: COLORS[:megenta]},
      arguments: {symbol: "<=", color: COLORS[:orange]},
      ivar_changes: {symbol: "changes:\n", color: COLORS[:blue]},
      defined_class: {symbol: "#", color: COLORS[:yellow]}
    }

    PAYLOAD_ATTRIBUTES.each do |attribute, attribute_options|
      color = attribute_options[:color]

      alias_method "original_#{attribute}".to_sym, attribute

      # regenerate attributes with `colorize: true` support
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

    def passed_at(options = {})
      with_method_head = options.fetch(:with_method_head, false)
      arg_name = raw_arguments.keys.detect { |k| raw_arguments[k] == target }

      return unless arg_name

      arg_name = ":#{arg_name}"
      arg_name = value_with_color(arg_name, :orange) if options[:colorize]
      msg = "Passed as #{arg_name} in '#{defined_class(options)}##{method_name(options)}' at #{location(options)}"
      msg += "\n  > #{method_head}" if with_method_head
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

    def ivar_changes(options = {})
      super.map do |ivar, value_changes|
        before = generate_string_result(value_changes[:before], options[:inspect])
        after = generate_string_result(value_changes[:after], options[:inspect])

        if options[:colorize]
          ivar = "#{COLORS[:orange]}#{ivar}#{COLORS[:reset]}"
          before = "#{COLORS[:blue]}#{before.to_s}#{COLORS[:reset]}"
          after = "#{COLORS[:blue]}#{after.to_s}#{COLORS[:reset]}"
        end

        "      #{ivar}: #{before.to_s} => #{after.to_s}"
      end.join("\n")
    end

    def call_info_with_ivar_changes(options = {})
      <<~MSG
      #{method_name_and_defined_class(options)}
          from: #{location(options)}
          changes:
      #{ivar_changes(options)}

      MSG
    end

    private

    def value_with_color(value, color)
      "#{COLORS[color]}#{value}#{COLORS[:reset]}"
    end

    def generate_string_result(obj, inspect)
      case obj
      when Array
        array_to_string(obj, inspect)
      when Hash
        hash_to_string(obj, inspect)
      when UNDEFINED
        UNDEFINED
      when String
        "\"#{obj}\""
      when nil
        "nil"
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
