require "active_support/configurable"
require "active_support/concern"

class TappingDevice
  module Configurable
    extend ActiveSupport::Concern

    DEFAULTS = {
      filter_by_paths: [],
      exclude_by_paths: [],
      with_trace_to: 50,
      event_type: :return,
      hijack_attr_methods: false,
      track_as_records: false,
    }.merge(TappingDevice::Output::DEFAULT_OPTIONS)

    included do
      include ActiveSupport::Configurable

      DEFAULTS.each do |key, value|
        config[key] = value
      end
    end
  end
end
