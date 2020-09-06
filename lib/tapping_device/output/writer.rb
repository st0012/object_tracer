# typed: false
class TappingDevice
  module Output
    class Writer
      extend T::Sig

      sig {params(options: Hash, output_block: Proc).void}
      def initialize(options, output_block)
        @options = options
        @output_block = output_block
      end

      sig {params(payload: TappingDevice::Payload).void}
      def write!(payload)
        raise NotImplementedError
      end

      private

      sig {params(payload: TappingDevice::Payload).returns(String)}
      def generate_output(payload)
        @output_block.call(Output::Payload.init(payload), @options)
      end
    end
  end
end
