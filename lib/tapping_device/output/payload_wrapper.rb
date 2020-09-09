require "pastel"

class TappingDevice
  module Output
    class PayloadWrapper
      UNDEFINED = "[undefined]"
      PRIVATE_MARK = " (private)"

      PASTEL = Pastel.new
      PASTEL.alias_color(:orange, :bright_red, :bright_yellow)

      TappingDevice::Payload::ATTRS.each do |attr|
        define_method attr do |options = {}|
          @payload.send(attr)
        end
      end

      alias :is_private_call? :is_private_call

      def method_head
        @payload.method_head
      end

      def location(options = {})
        @payload.location(options)
      end

      alias :raw_arguments :arguments
      alias :raw_return_value :return_value

      def initialize(payload)
        @payload = payload
      end

      def method_name(options = {})
        name = ":#{@payload.method_name}"

        name += " [#{tag}]" if tag
        name += PRIVATE_MARK if is_private_call?

        name
      end

      def arguments(options = {})
        generate_string_result(raw_arguments, options[:inspect])
      end

      def return_value(options = {})
        generate_string_result(raw_return_value, options[:inspect])
      end

      PAYLOAD_ATTRIBUTES = {
        method_name: {symbol: "", color: :bright_blue},
        location: {symbol: "from:", color: :green},
        return_value: {symbol: "=>", color: :magenta},
        arguments: {symbol: "<=", color: :orange},
        ivar_changes: {symbol: "changes:\n", color: :blue},
        defined_class: {symbol: "#", color: :yellow}
      }

      PAYLOAD_ATTRIBUTES.each do |attribute, attribute_options|
        color = attribute_options[:color]

        alias_method "original_#{attribute}".to_sym, attribute

        # regenerate attributes with `colorize: true` support
        define_method attribute do |options = {}|
          call_result = send("original_#{attribute}", options)

          if options[:colorize]
            PASTEL.send(color, call_result)
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
        arg_name = PASTEL.orange(arg_name) if options[:colorize]
        msg = "Passed as #{arg_name} in '#{defined_class(options)}##{method_name(options)}' at #{location(options)}\n"
        msg += "  > #{method_head}\n" if with_method_head
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
        @payload.ivar_changes.map do |ivar, value_changes|
          before = generate_string_result(value_changes[:before], options[:inspect])
          after = generate_string_result(value_changes[:after], options[:inspect])

          if options[:colorize]
            ivar = PASTEL.orange(ivar)
            before = PASTEL.bright_blue(before.to_s)
            after = PASTEL.bright_blue(after.to_s)
          end

          "      #{ivar}: #{before} => #{after}"
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
end
