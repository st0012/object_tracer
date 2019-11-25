class TappingDevice
  class SqlListenser
    attr_reader :method, :payload, :device
    def initialize(method, payload, device)
      @method = method
      @payload = payload
      @device = device
    end
  end
end
