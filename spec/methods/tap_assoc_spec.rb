require "spec_helper"
require "shared_examples/stoppable_examples"
require "shared_examples/optionable_examples"

RSpec.describe "tap_assoc!" do
  subject { :tap_assoc! }

  let(:target) { post }
  let(:trigger_action) do
    -> (target) { post.user }
  end

  it_behaves_like "stoppable"
  it_behaves_like "optionable"

  let(:user) { User.create!(name: "Stan") }
  let(:post) { Post.create!(title: "foo", content: "bar", user: user) }

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
