require "spec_helper"

RSpec.describe TappingDevice::Trackable do
  shared_context "order creation" do
    class Promotion; end
    class Order;end
    class Cart
      def total
        10
      end
      def promotion
        Promotion.new
      end
    end
    class CartOperationService
      def perform(cart)
        validate_cart(cart)
        apply_discount(cart)
        create_order(cart)
      end

      def validate_cart(cart)
        cart.total
        cart
      end

      def apply_discount(cart)
        cart.promotion
        cart
      end

      def create_order(cart)
        Order.new
      end
    end
  end

  describe "#print_calls_in_detail" do
    include_context "order creation"

    it "prints out target's calls in detail" do
      cart = Cart.new
      service = CartOperationService.new
      print_calls_in_detail(service, colorize: false)

      expect do
        service.perform(cart)
      end.to output(/:validate_cart # CartOperationService
    from: #{__FILE__}:.*
    <= {cart: #<Cart:.*>}
    => #<Cart:.*>

:apply_discount # CartOperationService
    from: #{__FILE__}:.*
    <= {cart: #<Cart:.*>}
    => #<Cart:.*>

:create_order # CartOperationService
    from: #{__FILE__}:.*
    <= {cart: #<Cart:.*>}
    => #<Order:.*>

:perform # CartOperationService
    from: #{__FILE__}:.*
    <= {cart: #<Cart:.*>}
    => #<Order:.*>/
      ).to_stdout
    end
  end

  describe "#print_traces" do
    include_context "order creation"

    it "prints out what the target sees" do
      cart = Cart.new
      service = CartOperationService.new
      print_traces(cart, colorize: false)

      expect do
        service.perform(cart)
      end.to output(/Passed as :cart in 'CartOperationService#:perform' at #{__FILE__}:\d+
Passed as :cart in 'CartOperationService#:validate_cart' at #{__FILE__}:\d+
Called :total from: #{__FILE__}:\d+
Passed as :cart in 'CartOperationService#:apply_discount' at #{__FILE__}:\d+
Called :promotion from: #{__FILE__}:\d+
Passed as :cart in 'CartOperationService#:create_order' at #{__FILE__}:\d+/
      ).to_stdout
    end
  end

  describe "#tap_passed!" do
    def foo(obj)
      obj
    end

    def bar(obj)
      obj
    end

    it "records all usages of the object" do
      count = 0
      s = Student.new("Stan", 18)

      tap_passed!(s) { count += 1 }

      foo(s)
      s.name
      bar(s)

      expect(count).to eq(2)
    end
  end

  describe "#tap_init!" do
    it "tracks Student's initialization" do
      count = 0
      tap_init!(Student) do |options|
        count += 1
      end

      Student.new("Stan", 18)
      Student.new("Jane", 23)

      expect(count).to eq(2)
    end
    it "can track subclass's initialization as well" do
      count = 0
      device = tap_init!(HighSchoolStudent) do |options|
        count += 1
      end

      HighSchoolStudent.new("Stan", 18)

      expect(count).to eq(1)

      device.stop!
    end
    it "doesn't track School's initialization" do
      count = 0
      tap_init!(Student) do |options|
        count += 1
      end

      School.new("A school")

      expect(count).to eq(0)
    end
    it "doesn't track non-initialization method calls" do
      count = 0
      tap_init!(Student) do |options|
        count += 1
      end

      Student.foo

      expect(count).to eq(0)
    end
  end

  describe "#tap_on!" do
    it "tracks method calls on the tapped object" do
      stan = Student.new("Stan", 18)
      jane = Student.new("Jane", 23)

      calls = []
      tap_on!(stan) do |payload|
        calls << [payload[:receiver].object_id, payload[:method_name], payload[:return_value]]
      end

      stan.name
      stan.age
      jane.name
      jane.age

      expect(calls).to match_array(
        [
          [stan.object_id, :name, "Stan"],
          [stan.object_id, :age, 18]
        ]
      )
    end
    it "supports multiple tappings" do
      stan = Student.new("Stan", 18)

      count_1 = 0
      count_2 = 0

      tap_on!(stan) { count_1 += 1 }
      tap_on!(stan) { count_2 -= 1 }

      stan.name

      expect(count_1).to eq(1)
      expect(count_2).to eq(-1)
    end
    it "tracks alias" do
      c = Class.new(Student)
      c.class_eval do
        alias :alias_name :name
      end
      stan = c.new("Stan", 18)

      names = []
      tap_on!(stan) do |payload|
        names << payload[:method_name]
      end

      stan.alias_name

      expect(names).to match_array([:alias_name])
    end

    describe "yield parameters" do
      it "detects correct arguments" do
        stan = Student.new("Stan", 18)

        arguments = []

        tap_on!(stan) do |payload|
          arguments = payload[:arguments]
        end

        stan.age = (25)

        expect(arguments).to eq({age: 25})
      end
      it "returns correct filepath and line number" do
        stan = Student.new("Stan", 18)

        filepath = ""
        line_number = 0

        tap_on!(stan) do |payload|
          filepath = payload[:filepath]
          line_number = payload[:line_number]
        end

        line_mark = __LINE__
        stan.age

        expect(filepath).to eq(__FILE__)
        expect(line_number).to eq((line_mark+1).to_s)
      end
    end

    describe "options - exclude_by_paths: [/path/]" do
      it "skips calls that matches the pattern" do
        stan = Student.new("Stan", 18)
        count = 0
        tap_on!(stan, exclude_by_paths: [/spec/]) { count += 1 }

        stan.name

        expect(count).to eq(0)
      end
    end
    describe "options - filter_by_paths: [/path/]" do
      it "skips calls that matches the pattern" do
        stan = Student.new("Stan", 18)
        count = 0

        device = tap_on!(stan, filter_by_paths: [/lib/]) { count += 1 }
        stan.name
        expect(count).to eq(0)

        device.stop!

        tap_on!(stan, filter_by_paths: [/spec/]) { count += 1 }
        stan.name
        expect(count).to eq(1)
      end
    end
  end
end

RSpec.describe TappingDevice::Trackable do
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
