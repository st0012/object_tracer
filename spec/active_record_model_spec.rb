require "spec_helper"
require "model"
require "stoppable_examples"

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
    let(:device) do
      described_class.new do |payload|
        {path: payload[:filepath], line_number: payload[:line_number]}
      end
    end
    it "tracks every association calls" do
      device.tap_assoc!(post)

      post.user; line_1 = __LINE__
      post.title
      post.comments; line_2 = __LINE__

      expect(device.calls.count).to eq(2)
      expect(device.calls[0][:path]).to eq(__FILE__)
      expect(device.calls[0][:line_number]).to eq(line_1.to_s)
      expect(device.calls[1][:path]).to eq(__FILE__)
      expect(device.calls[1][:line_number]).to eq(line_2.to_s)
    end
  end

  describe "#tap_sql!" do
    let(:device) { described_class.new }
    subject { :tap_sql! }

    context "ActiveRecord model" do
      let(:target) { Post }

      it_behaves_like "stoppable" do
        let(:trigger_action) do
          -> (target) { target.first }
        end
      end

      it "locates the method that triggers the sql query" do
        device.tap_sql!(Post)

        line_mark = __LINE__
        Post.first

        # first
        expect(device.calls[0][:filepath]).to eq(__FILE__)
        expect(device.calls[0][:line_number]).to eq((line_mark+1).to_s)
      end
      it "won't be affected by other object's calls" do
        device.tap_sql!(Post)

        assert_query_count(5) do
          Post.first
          User.first
          Post.last
          User.last
          Post.find_by_sql("SELECT \"posts\".* FROM \"posts\" ORDER BY \"posts\".\"id\"")
        end

        sqls = device.calls.map do |call|
          call[:sql].squeeze(" ")
        end

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
    end

    context "call on AR relation objects" do
      it_behaves_like "stoppable" do
        let(:target) { Post.where(user: user) }
        let(:trigger_action) do
          -> (target) { target.where(id: 1).first }
        end
      end

      it "tracks repeated calls correctly" do
        posts = Post.where(user: user)
        line_1 = 0
        line_2 = 0

        device.tap_sql!(posts)

        assert_query_count(2) do
          posts.where(id: 0).first; line_1 = __LINE__
          posts.where(id: 0).first; line_2 = __LINE__
        end

        expect(device.calls.count).to eq(2)

        first_call = device.calls[0]
        expect(first_call[:method_name]).to eq(:first)
        expect(first_call[:line_number]).to eq(line_1.to_s)

        second_call = device.calls[1]
        expect(second_call[:method_name]).to eq(:first)
        expect(second_call[:line_number]).to eq(line_2.to_s)
      end

      it "also tracks sqls created by AR relation objects created by targets" do
        posts = Post.where(user: user)
        line = 0

        device.tap_sql!(posts)

        assert_query_count(3) do
          posts.first
          posts.where(id: 1).first; line = __LINE__
          posts.last
        end

        expect(device.calls.count).to eq(3)

        first_call = device.calls[0]
        expect(first_call[:method_name]).to eq(:first)
        expect(first_call[:receiver]).to eq(posts)

        second_call = device.calls[1]
        expect(second_call[:method_name]).to eq(:first)
        expect(second_call[:receiver]).to be_a(ActiveRecord::Relation)
        expect(second_call[:line_number]).to eq(line.to_s)

        last_call = device.calls[2]
        expect(last_call[:method_name]).to eq(:last)
        expect(last_call[:receiver]).to eq(posts)
      end
    end
  end
end
