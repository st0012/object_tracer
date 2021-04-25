class TappingDevice
  module Output
    class FileWriter < Writer
      def initialize(options, output_block)
        @path = options[:log_file]
        @logger = Logger.new(@path)
        super
      end

      def write!(payload)
        output = generate_output(payload)
        @logger << output
      end
    end
  end
end
