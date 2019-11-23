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
  let(:user) { User.create!(name: "Stan") }
  let(:post) { Post.create!(title: "foo", content: "bar", user: user) }
  let!(:comment) { Comment.create!(post: post, user: user, content: "Nice post!") }

  describe "#tap_assoc!" do
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

  describe "#tap_sql!" do
    it "locates the method that triggers the sql query" do
      filepaths = []
      line_numbers = []

      device = described_class.new do |payload|
        filepaths << payload[:filepath]
        line_numbers << payload[:line_number]
      end

      device.tap_sql!(Post)

      line_mark = __LINE__
      Post.first

      # first
      expect(filepaths.first).to eq(__FILE__)
      expect(line_numbers.first).to eq((line_mark+1).to_s)
    end
    it "won't be affected by other object's calls" do
      sqls = []

      device = described_class.new do |payload|
        sqls << payload[:sql].squeeze(" ")
      end

      device.tap_sql!(Post)

      Post.first
      User.first
      Post.last
      User.last
      Post.find_by_sql("SELECT \"posts\".* FROM \"posts\" ORDER BY \"posts\".\"id\"")

      expect(sqls.count).to eq(3)
      expect(sqls).to eq(
        [
          # first
          "SELECT \"posts\".* FROM \"posts\" ORDER BY \"posts\".\"id\" ASC LIMIT ?",
          # last
          "SELECT \"posts\".* FROM \"posts\" ORDER BY \"posts\".\"id\" DESC LIMIT ?",
          # find_by_sql
          "SELECT \"posts\".* FROM \"posts\" ORDER BY \"posts\".\"id\""
        ]
      )
    end

    context "call on AR relation objects" do
      it "also tracks sqls created by AR relation objects created by targets" do
        calls = []

        device = described_class.new do |payload|
          calls << payload
        end

        posts = Post.where(user: user)

        device.tap_sql!(posts)

        posts.first
        posts.where(id: 1).first; line = __LINE__
        posts.last

        expect(calls.count).to eq(3)

        first_call = calls[0]
        expect(first_call[:method_name]).to eq(:first)
        expect(first_call[:receiver]).to eq(posts)

        second_call = calls[1]
        expect(second_call[:method_name]).to eq(:first)
        expect(second_call[:receiver]).to be_a(ActiveRecord::Relation)
        expect(second_call[:line_number]).to eq(line.to_s)

        last_call = calls[2]
        expect(last_call[:method_name]).to eq(:last)
        expect(last_call[:receiver]).to eq(posts)
      end
    end
  end
end
