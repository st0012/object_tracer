# typed: true
class TappingDevice
  class Exception < StandardError
  end

  class NotAnActiveRecordInstanceError < Exception
    def initialize(object)
      super("target object should be an instance of ActiveRecord::Base, got #{object}")
    end
  end

  class NotAClassError < Exception
    def initialize(object)
      super("target object should be a class, got #{object}")
    end
  end
end
