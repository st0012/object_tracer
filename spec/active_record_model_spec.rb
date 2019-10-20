require "spec_helper"
require "model"

RSpec.describe Post do
  include TappingDevice::Trackable

  before do
    Post.create!(title: "foo", content: "bar")
  end

  describe "triggering test" do
    let(:locations) { [] }

    before do
      tap_init!(Post) do |payload|
        locations << {path: payload[:filepath], line_number: payload[:line_number]}
      end
    end

    it "triggers tapping when calling new" do
      Post.new; line = __LINE__

      expect(locations.first[:path]).to eq(__FILE__)
      expect(locations.first[:line_number]).to eq(line.to_s)
    end
  end
end
