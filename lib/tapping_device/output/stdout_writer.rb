class TappingDevice
  module Output
    class StdoutWriter < Writer
      def write!(payload)
        puts(generate_output(payload))
      end
    end
  end
end
