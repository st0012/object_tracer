# typed: true
class TappingDevice
  module Manageable

    def suspend_new
      @suspend_new
    end

    # list all registered devices
    def devices
      @devices
    end

    # disable given device and remove it from registered list
    def delete_device(device)
      device.trace_point&.disable
      @devices -= [device]
    end

    # stops all registered devices and remove them from registered list
    def stop_all!
      @devices.each(&:stop!)
    end

    # suspend enabling new trace points
    # user can still create new Device instances, but they won't be functional
    def suspend_new!
      @suspend_new = true
    end

    # reset everything to clean state and disable all devices
    def reset!
      @suspend_new = false
      stop_all!
    end
  end
end

