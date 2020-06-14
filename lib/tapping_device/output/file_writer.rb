class TappingDevice
  module Output
    class FileWriter
      def initialize(options = {})
        @path = options[:filepath]
        File.write(@path, "")
      end

      def write!(message)
        File.open(@path, "a") do |f|
          f << message
        end
      end
    end
  end
end
