class TappingDevice
  module Output
    class Writer
      def initialize(options:, output_block:, logger:)
        @options = options
        @output_block = output_block
        @logger = logger
      end

      def write!(payload)
        output = generate_output(payload)
        @logger << output
      end

      private

      def generate_output(payload)
        @output_block.call(PayloadWrapper.new(payload), @options)
      end
    end
  end
end
