class TappingDevice
  class Configuration
    DEFAULTS = {
      filter_by_paths: [],
      exclude_by_paths: [],
      with_trace_to: 50,
      event_type: :return,
      hijack_attr_methods: false,
      track_as_records: false,
      ignore_private: false,
      only_private: false
    }.merge(TappingDevice::Output::DEFAULT_OPTIONS)

    def initialize
      @options = {}

      DEFAULTS.each do |key, value|
        @options[key] = value
      end
    end

    def [](key)
      @options[key]
    end

    def []=(key, value)
      @options[key] = value
    end
  end

  def self.config
    @config ||= Configuration.new
  end
end
