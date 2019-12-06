class TappingDevice
  class Payload < Hash
    ATTRS = [:receiver, :method_name, :arguments, :return_value, :filepath, :line_number, :defined_class, :trace, :tp]

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

    def method_name_and_location
      "Method: :#{method_name}, line: #{filepath}:#{line_number}"
    end

    def method_name_and_arguments
      "Method: :#{method_name}, argments: #{arguments.to_s}"
    end
  end
end
