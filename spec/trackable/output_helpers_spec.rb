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

  let(:cart) { Cart.new }
  let(:service) { CartOperationService.new }

  shared_examples "output calls examples" do
    let(:expected_output) do
/:validate_cart # CartOperationService
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
    end

    it "prints out target's calls in detail" do
      print_calls(service, colorize: false)

      expect { service.perform(cart) }.to produce_expected_output(expected_output)
    end

    context "with '.with' chained" do
      let(:expected_output) do
/:create_order # CartOperationService
    from: #{__FILE__}:.*
    <= {cart: #<Cart:.*>}
    => #<Order:.*>/
      end
      it "only prints the calls that matches the with condition" do
        print_calls(service, colorize: false).with do |payload|
          payload.method_name.to_s.match?(/order/)
        end

        expect { service.perform(cart) }.to produce_expected_output(expected_output)
      end
    end
  end

  shared_examples "output traces examples" do
    let(:expected_output) do
/Passed as :cart in 'CartOperationService#:perform' at #{__FILE__}:\d+
Passed as :cart in 'CartOperationService#:validate_cart' at #{__FILE__}:\d+
Called :total from: #{__FILE__}:\d+
Passed as :cart in 'CartOperationService#:apply_discount' at #{__FILE__}:\d+
Called :promotion from: #{__FILE__}:\d+
Passed as :cart in 'CartOperationService#:create_order' at #{__FILE__}:\d+/
    end

    it "prints out what the target sees" do
      print_traces(cart, colorize: false)

      expect { service.perform(cart) }.to produce_expected_output(expected_output)
    end

    context "when chained with .with" do
      let(:expected_output) do
/Passed as :cart in 'CartOperationService#:perform' at #{__FILE__}:\d+
Passed as :cart in 'CartOperationService#:validate_cart' at #{__FILE__}:\d+
Passed as :cart in 'CartOperationService#:apply_discount' at #{__FILE__}:\d+
Passed as :cart in 'CartOperationService#:create_order' at #{__FILE__}:\d+/
      end

      it "filters output according to the condition" do
        print_traces(cart, colorize: false).with do |trace|
          trace.arguments.keys.include?(:cart)
        end

        expect { service.perform(cart) }.to produce_expected_output(expected_output)
      end
    end
  end

  shared_examples "output mutations examples" do
    let(:student) { Student.new("Stan", 26) }

    class Student
      def remove_id
        remove_instance_variable(:@id)
      end

      # this is to test if it can distinguish state changes made by different level of calls
      def reset_data!
        @id = 0
        @name = ""
        self.age = 0
      end
    end

    it "tracks attr_writer as well" do
      expected_output = /:name= # #<Class:#<Student:\w+>>
    from: #{__FILE__}:\d+
    changes:
      @name: "Stan" => "Sean"/

      print_mutations(student, colorize: false)

      expect { student.name = "Sean" }.to produce_expected_output(expected_output)
    end

    it "prints calls that define/undefine an object's instance variables" do
      expected_output = /:id= # Student
    from: #{__FILE__}:\d+
    changes:
      @id: \[undefined\] => 1

:remove_id # Student
    from: #{__FILE__}:\d+
    changes:
      @id: 1 => \[undefined\].*/

      print_mutations(student, colorize: false)

      expect do
        student.id = 1
        student.remove_id
      end.to produce_expected_output(expected_output)
    end

    it "remembers changed value" do
      expected_output = /:id= # Student
    from: #{__FILE__}:.*
    changes:
      @id: \[undefined\] => 1

:id= # Student
    from: #{__FILE__}:.*
    changes:
      @id: 1 => nil/

      print_mutations(student, colorize: false)

      expect do
        student.id = 1
        student.id = 1
        student.id = nil
      end.to produce_expected_output(expected_output)
    end

    it "tracks multiple levels of state changes" do
      expected_output = /:age= # Student
    from: #{__FILE__}:.*
    changes:
      @age: 26 => 0

:reset_data! # Student
    from: #{__FILE__}:.*
    changes:
      @name: "Stan" => ""
      @age: 26 => 0
      @id: 1 => 0/

      student.id = 1
      print_mutations(student, colorize: false)

      expect { student.reset_data! }.to produce_expected_output(expected_output)
    end
  end

  describe "print_* helpers" do
    def produce_expected_output(expected_output)
      output(expected_output).to_stdout
    end

    describe "#print_calls" do
      include_context "order creation"
      it_behaves_like "output calls examples"
    end

    describe "#print_traces" do
      include_context "order creation"
      it_behaves_like "output traces examples"
    end

    describe "#print_mutations" do
      it_behaves_like "output mutations examples"
    end
  end
end
