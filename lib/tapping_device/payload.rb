require "awesome_print"
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

    def detail_call_info(awesome_print: false)
      arguments_output = arguments.inspect
      return_value_output = return_value.inspect

      if awesome_print
        arguments_output = arguments.ai(ruby19_syntax: true, multiline: false)
        return_value_output = return_value.ai(ruby19_syntax: true, multiline: false)
      end

      <<~MSG
      #{method_name_and_defined_class}
          from: #{location}
          <= #{arguments_output}
          => #{return_value_output}

      MSG
    end
  end
end
