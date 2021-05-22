return unless ENV["WITH_ACTIVE_RECORD"]

require "spec_helper"
require "shared_examples/stoppable_examples"
require "shared_examples/optionable_examples"
require "database_cleaner"
require "model"

RSpec.configure do |config|
  DatabaseCleaner.strategy = :truncation

  config.before(:suite) do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with(:truncation)
  end

  config.around(:each) do |example|
    DatabaseCleaner.cleaning do
      example.run
    end
  end
end

RSpec.describe "ActiveRecord" do
  describe "#tap_init!" do
    let(:locations) { [] }

    it "returns the instance object for ActiveRecord models" do
     device = tap_init!(Post)

     post = Post.new

     expect(device.calls.count).to eq(1)
     expect(device.calls.first.return_value).to eq(post)
     expect(device.calls.first.receiver).to eq(Post)
    end

    it "triggers tapping when calling .new" do
      tap_init!(Post) do |payload|
        locations << {path: payload.filepath, line_number: payload.line_number}
      end

      Post.new; line = __LINE__

      expect(locations.first[:path]).to eq(__FILE__)
      expect(locations.first[:line_number]).to eq(line.to_s)
    end
  end

  describe "#tap_on!" do
    context "with track_as_records: true" do
      it "tracks ActiveRecord::Base instances with their ids" do
        post = Post.create!(title: "foo", content: "bar")

        device = tap_on!(post, exclude_by_paths: [/gems/], track_as_records: true)

        Post.last.title

        expect(device.calls.count).to eq(1)
      end
    end
    context "without track_as_records: true" do
      it "treats the record like normal objects" do
        post = Post.create!(title: "foo", content: "bar")

        device = tap_on!(post, exclude_by_paths: [/gems/])

        Post.last.title

        expect(device.calls.count).to eq(0)
      end
    end
  end

  describe "#tap_assoc!" do
    subject { :tap_assoc! }

    let(:target) { post }
    let(:trigger_action) do
      -> (target) { post.user }
    end

    it_behaves_like "stoppable"
    it_behaves_like "optionable"

    let(:user) { User.create!(name: "Stan") }
    let(:post) { Post.create!(title: "foo", content: "bar", user: user) }

    it "raises error if the object is not an instance of ActiveRecord::Base" do
      expect { tap_assoc!(1) }.to raise_error(ObjectTracer::NotAnActiveRecordInstanceError)
    end

    it "tracks every association calls" do
      device = tap_assoc!(post)

      post.user; line_1 = __LINE__
      post.title
      post.comments; line_2 = __LINE__

      expect(device.calls.count).to eq(2)
      expect(device.calls[0].filepath).to eq(__FILE__)
      expect(device.calls[0].line_number).to eq(line_1.to_s)
      expect(device.calls[1].filepath).to eq(__FILE__)
      expect(device.calls[1].line_number).to eq(line_2.to_s)
    end
  end
end
