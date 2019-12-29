require "spec_helper"
require "shared_examples/stoppable_examples"
require "shared_examples/optionable_examples"

RSpec.describe "tap_sql!" do
  include TappingDevice::Trackable

  subject { :tap_sql! }

  let(:user) { User.create!(name: "Stan") }
  let(:post) { Post.create!(title: "foo", content: "bar", user: user) }
  let!(:comment) { Comment.create!(post: post, user: user, content: "Nice post!") }

  context "ActiveRecord model" do
    let(:target) { Post }
    let(:trigger_action) do
      -> (target) { target.first }
    end
    it_behaves_like "stoppable"
    it_behaves_like "optionable"

    it "locates the method that triggers the sql query" do
      device = tap_sql!(Post)

      line_mark = __LINE__
      Post.first

      # first
      expect(device.calls[0].filepath).to eq(__FILE__)
      expect(device.calls[0].target).to eq(Post)
      expect(device.calls[0].line_number).to eq((line_mark+1).to_s)
    end
    it "won't be affected by other object's calls" do
      device = tap_sql!(Post)

      assert_query_count(5) do
        Post.first
        User.first
        Post.last
        User.last
        Post.find_by_sql("SELECT \"posts\".* FROM \"posts\" ORDER BY \"posts\".\"id\"")
      end

      sqls = device.calls.map do |call|
        call.sql.squeeze(" ")
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
    it "locates calls even if them are created inside a block" do
      line_1 = line_2 = 0

      device = tap_sql!(Post)

      Post.transaction do
        Post.first; line_1 = __LINE__
        Post.last; line_2 = __LINE__
      end

      sqls = device.calls.map do |call|
        call.sql.squeeze(" ")
      end

      expect(sqls.count).to eq(2)
      expect(sqls).to eq(
        [
          "SELECT \"posts\".* FROM \"posts\" ORDER BY \"posts\".\"id\" ASC LIMIT ?",
          # last
          "SELECT \"posts\".* FROM \"posts\" ORDER BY \"posts\".\"id\" DESC LIMIT ?",
        ]
      )

      first_call = device.calls[0]
      expect(first_call.method_name).to eq(:first)
      expect(first_call.line_number).to eq(line_1.to_s)

      second_call = device.calls[1]
      expect(second_call.method_name).to eq(:last)
      expect(second_call.line_number).to eq(line_2.to_s)
    end
  end

  context "call on AR relation objects" do
    let(:posts) { Post.all }

    let(:target) { posts }
    let(:trigger_action) do
      -> (target) { target.where(id: 1).first }
    end

    it_behaves_like "stoppable"
    it_behaves_like "optionable"


    it "creates child devices when doing nested tapping" do
      device = tap_sql!(posts)

      new_scope = posts.where(id: 0) # should create 1 device
      posts.order(:id) # should create 1 device
      new_scope.preload(:comments) # should create 1 device

      expect(device.descendants.count).to eq(3)
    end

    it "tracks repeated calls correctly" do
      line_1 = 0
      line_2 = 0

      device = tap_sql!(posts)

      assert_query_count(2) do
        posts.where(id: 0).first; line_1 = __LINE__
        posts.where(id: 0).first; line_2 = __LINE__
      end

      expect(device.calls.count).to eq(2)

      first_call = device.calls[0]
      expect(first_call.target).to eq(posts)
      expect(first_call.method_name).to eq(:first)
      expect(first_call.line_number).to eq(line_1.to_s)

      second_call = device.calls[1]
      expect(second_call.target).to eq(posts)
      expect(second_call.method_name).to eq(:first)
      expect(second_call.line_number).to eq(line_2.to_s)
    end

    it "tracks enumerable methods" do
      line = 0

      device = tap_sql!(posts)

      assert_query_count(1) do
        posts.collect {}; line = __LINE__
      end

      call = device.calls[0]
      expect(call.method_name).to eq(:collect)
      expect(call.line_number).to eq(line.to_s)
    end

    it "also tracks sqls created by AR relation objects created by targets" do
      line = 0

      device = tap_sql!(posts)

      assert_query_count(3) do
        posts.first
        posts.where(id: 1).first; line = __LINE__
        posts.last
      end

      expect(device.calls.count).to eq(3)

      first_call = device.calls[0]
      expect(first_call.method_name).to eq(:first)
      expect(first_call.receiver).to eq(posts)

      second_call = device.calls[1]
      expect(second_call.method_name).to eq(:first)
      expect(second_call.receiver).to be_a(ActiveRecord::Relation)
      expect(second_call.line_number).to eq(line.to_s)

      last_call = device.calls[2]
      expect(last_call.method_name).to eq(:last)
      expect(last_call.receiver).to eq(posts)
    end
  end
end
