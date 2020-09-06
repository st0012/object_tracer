class TappingDevice
  class Payload < Hash
    ATTRS = [
      :target, :receiver, :method_name, :method_object, :arguments, :return_value, :filepath, :line_number,
      :defined_class, :trace, :tag, :tp, :ivar_changes, :is_private_call?
    ]

    ATTRS.each do |attr|
      define_method attr do |options = {}|
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

    def method_head
      method_object.source.strip if method_object.source_location
    end

    def location(options = {})
      "#{filepath}:#{line_number}"
    end
  end
end
