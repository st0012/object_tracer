require "tapping_device/trackable"

module TappingDevice
  class Device
    include Trackable

    def initialize(options = {}, &block)
      @block = block
      @options = options
    end

    def tap_init!(klass)
      raise "argument should be a class, got #{klass}" unless klass.is_a?(Class)
      @tp = track(klass, condition: :tap_init?, block: @block, **@options)
    end

    def stop!
      @tp.disable
    end
  end
end
