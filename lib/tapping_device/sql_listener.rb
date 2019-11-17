class TappingDevice
  class SqlListenser
    attr_reader :arr, :method, :block
    def initialize(method, block)
      @method = method
      @arr = []
      @block = block
    end
  end
end
