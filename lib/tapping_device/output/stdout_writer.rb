class TappingDevice
  module Output
    class StdoutWriter
      def initialize(_options = {}); end

      def write!(message)
        puts(message)
      end
    end
  end
end
