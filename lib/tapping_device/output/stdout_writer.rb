class TappingDevice
  module Output
    class StdoutWriter < Writer
      def initialize(options, output_block)
        super
        @logger = Logger.new($stdout)
      end
    end
  end
end
