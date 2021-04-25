require "logger"
require "tapping_device/output/payload_wrapper"
require "tapping_device/output/writer"

class TappingDevice
  module Output
    DEFAULT_OPTIONS = {
      inspect: false,
      colorize: true,
      log_file: "/tmp/tapping_device.log"
    }

    module Helpers
      def and_write(payload_method = nil, options: {}, &block)
        and_output(payload_method, options: options, logger: Logger.new(options[:log_file]), &block)
      end

      def and_print(payload_method = nil, options: {}, &block)
        and_output(payload_method, options: options, logger: Logger.new($stdout), &block)
      end

      def and_output(payload_method = nil, options: {}, logger:, &block)
        output_block = generate_output_block(payload_method, block)
        @output_writer = Writer.new(options: options, output_block: output_block, logger: logger)
        self
      end

      private

      def generate_output_block(payload_method, block)
        if block
          block
        elsif payload_method
          -> (output_payload, output_options) { output_payload.send(payload_method, output_options) }
        else
          raise "need to provide either a payload method name or a block"
        end
      end
    end
  end
end
