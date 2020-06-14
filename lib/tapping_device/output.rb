require "tapping_device/output/payload"
require "tapping_device/output/stdout_writer"
require "tapping_device/output/file_writer"

class TappingDevice
  module Output
    module Helpers
      def and_write(payload_method = nil, filepath: "/tmp/tapping_device.log", &block)
        and_output(payload_method, output_writer: Output::FileWriter.new(filepath: filepath), &block)
      end

      def and_print(payload_method = nil, &block)
        and_output(payload_method, output_writer: StdoutWriter.new, &block)
      end

      def and_output(payload_method = nil, output_writer:, &block)
        @output_writer = output_writer

        @output_block =
          if block
            block
          elsif payload_method
            -> (output_payload) { output_payload.send(payload_method) }
          else
            raise "need to provide either a payload method name or a block"
          end

        self
      end
    end
  end
end
