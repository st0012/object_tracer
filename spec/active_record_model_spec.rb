require "spec_helper"
require "model"

RSpec.describe "ActiveRecord model spec" do
  include TappingDevice::Trackable

  let!(:post) { Post.create!(title: "foo", content: "bar") }
  let(:locations) { [] }

  describe "#tap_init!" do
    let(:locations) { [] }

    before do
      tap_init!(Post) do |payload|
        locations << {path: payload[:filepath], line_number: payload[:line_number]}
      end
    end

    it "triggers tapping when calling .new" do
      Post.new; line = __LINE__

      expect(locations.first[:path]).to eq(__FILE__)
      expect(locations.first[:line_number]).to eq(line.to_s)
    end
  end

  describe "#tap_assoc!" do
    let(:user) { User.create!(name: "Stan") }
    let(:post) { Post.create!(title: "foo", content: "bar", user: user) }
    let!(:comment) { Comment.create!(post: post, user: user, content: "Nice post!") }

    it "tracks every association calls" do
      tap_assoc!(post) do |payload|
        locations << {path: payload[:filepath], line_number: payload[:line_number]}
      end

      post.user; line_1 = __LINE__
      post.title
      post.comments; line_2 = __LINE__

      expect(locations.count).to eq(2)
      expect(locations[0][:path]).to eq(__FILE__)
      expect(locations[0][:line_number]).to eq(line_1.to_s)
      expect(locations[1][:path]).to eq(__FILE__)
      expect(locations[1][:line_number]).to eq(line_2.to_s)
    end
  end
end


RSpec.describe TappingDevice do
  describe "#tap_assoc!" do
    let(:user) { User.create!(name: "Stan") }
    let(:post) { Post.create!(title: "foo", content: "bar", user: user) }
    let!(:comment) { Comment.create!(post: post, user: user, content: "Nice post!") }

    it "tracks every association calls" do
      locations = []

      device = described_class.new do |payload|
        locations << {path: payload[:filepath], line_number: payload[:line_number]}
      end
      device.tap_assoc!(post)

      post.user; line_1 = __LINE__
      post.title
      post.comments; line_2 = __LINE__

      expect(locations.count).to eq(2)
      expect(locations[0][:path]).to eq(__FILE__)
      expect(locations[0][:line_number]).to eq(line_1.to_s)
      expect(locations[1][:path]).to eq(__FILE__)
      expect(locations[1][:line_number]).to eq(line_2.to_s)
    end
  end
end
