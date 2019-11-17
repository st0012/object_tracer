class TappingDevice
  class SqlListenser
    attr_reader :method, :payload, :block
    def initialize(method, payload, block)
      @method = method
      @payload = payload
      @block = block
    end
  end
end
