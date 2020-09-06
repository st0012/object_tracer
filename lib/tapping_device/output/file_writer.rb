# typed: true
class TappingDevice
  module Output
    class FileWriter < Writer
      sig {params(options: Hash, output_block: Proc).void}
      def initialize(options, output_block)
        @path = options[:log_file]

        File.write(@path, "") # clean file

        super
      end

      sig {params(payload: TappingDevice::Payload).void}
      def write!(payload)
        output = generate_output(payload)

        File.open(@path, "a") do |f|
          f << output
        end
      end
    end
  end
end
