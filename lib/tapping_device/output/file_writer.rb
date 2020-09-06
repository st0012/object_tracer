# typed: true
class TappingDevice
  module Output
    class FileWriter < Writer
      def initialize(options, output_block)
        @path = options[:log_file]

        File.write(@path, "") # clean file

        super
      end

      def write!(payload)
        output = generate_output(payload)

        File.open(@path, "a") do |f|
          f << output
        end
      end
    end
  end
end
