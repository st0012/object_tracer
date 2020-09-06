# typed: true
class TappingDevice
  module Output
    class StdoutWriter < Writer
      sig {params(payload: TappingDevice::Payload).void}
      def write!(payload)
        puts(generate_output(payload))
      end
    end
  end
end
