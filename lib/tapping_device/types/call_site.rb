class TappingDevice
  module Types
    class CallSite < T::Struct
      const :filepath, String
      const :line_number, String
    end
  end
end
