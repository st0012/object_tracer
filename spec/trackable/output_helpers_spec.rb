require "spec_helper"
require "contexts/order_creation"

RSpec.describe TappingDevice::Trackable do
  let(:cart) { Cart.new }
  let(:service) { CartOperationService.new }

  shared_examples "output calls examples" do |action:|
    let(:helper_method) { "#{action}_calls" }
    let(:tap_action) { send(helper_method, service, colorize: false) }
    let(:expected_output) do
/:validate_cart # CartOperationService
    from: .*:.*
    <= {cart: #<Cart:.*>}
    => #<Cart:.*>

:apply_discount # CartOperationService
    from: .*:.*
    <= {cart: #<Cart:.*>}
    => #<Cart:.*>

:create_order # CartOperationService
    from: .*:.*
    <= {cart: #<Cart:.*>}
    => #<Order:.*>

:perform # CartOperationService
    from: .*:.*
    <= {cart: #<Cart:.*>}
    => #<Order:.*>/
    end

    it "prints out target's calls in detail" do
      tap_action

      expect { service.perform(cart) }.to produce_expected_output(expected_output)
    end

    context "with '.with' chained" do
      let(:expected_output) do
/:create_order # CartOperationService
    from: .*:.*
    <= {cart: #<Cart:.*>}
    => #<Order:.*>/
      end
      it "only prints the calls that matches the with condition" do
        tap_action.with do |payload|
          payload.method_name.to_s.match?(/order/)
        end

        expect { service.perform(cart) }.to produce_expected_output(expected_output)
      end
    end
  end

  shared_examples "output traces examples" do |action:|
    let(:helper_method) { "#{action}_traces" }
    let(:tap_action) { send(helper_method, cart, colorize: false) }

    let(:expected_output) do
/Passed as :cart in 'CartOperationService#:perform' at .*:\d+
Passed as :cart in 'CartOperationService#:validate_cart' at .*:\d+
Called :total from: .*:\d+
Passed as :cart in 'CartOperationService#:apply_discount' at .*:\d+
Called :promotion from: .*:\d+
Passed as :cart in 'CartOperationService#:create_order' at .*:\d+/
    end

    it "prints out what the target sees" do
      tap_action

      expect { service.perform(cart) }.to produce_expected_output(expected_output)
    end

    context "when chained with .with" do
      let(:expected_output) do
/Passed as :cart in 'CartOperationService#:perform' at .*:\d+
Passed as :cart in 'CartOperationService#:validate_cart' at .*:\d+
Passed as :cart in 'CartOperationService#:apply_discount' at .*:\d+
Passed as :cart in 'CartOperationService#:create_order' at .*:\d+/
      end

      it "filters output according to the condition" do
        tap_action.with do |trace|
          trace.arguments.keys.include?(:cart)
        end

        expect { service.perform(cart) }.to produce_expected_output(expected_output)
      end
    end
  end

  shared_examples "output mutations examples" do |action:|
    let(:student) { Student.new("Stan", 26) }
    let(:helper_method) { "#{action}_mutations" }
    let(:tap_action) { send(helper_method, student, colorize: false) }

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
    from: .*:\d+
    changes:
      @name: "Stan" => "Sean"/

      tap_action

      expect { student.name = "Sean" }.to produce_expected_output(expected_output)
    end

    it "prints calls that define/undefine an object's instance variables" do
      expected_output = /:id= # Student
    from: .*:\d+
    changes:
      @id: \[undefined\] => 1

:remove_id # Student
    from: .*:\d+
    changes:
      @id: 1 => \[undefined\].*/

      tap_action

      expect do
        student.id = 1
        student.remove_id
      end.to produce_expected_output(expected_output)
    end

    it "remembers changed value" do
      expected_output = /:id= # Student
    from: .*:.*
    changes:
      @id: \[undefined\] => 1

:id= # Student
    from: .*:.*
    changes:
      @id: 1 => nil/

      tap_action

      expect do
        student.id = 1
        student.id = 1
        student.id = nil
      end.to produce_expected_output(expected_output)
    end

    it "tracks multiple levels of state changes" do
      expected_output = /:age= # Student
    from: .*:.*
    changes:
      @age: 26 => 0

:reset_data! # Student
    from: .*:.*
    changes:
      @name: "Stan" => ""
      @age: 26 => 0
      @id: 1 => 0/

      tap_action

      student.id = 1

      expect { student.reset_data! }.to produce_expected_output(expected_output)
    end
  end

  describe "print_* helpers" do
    def produce_expected_output(expected_output)
      output(expected_output).to_stdout
    end

    describe "#print_calls" do
      include_context "order creation"
      it_behaves_like "output calls examples", action: "print"
    end

    describe "#print_traces" do
      include_context "order creation"
      it_behaves_like "output traces examples", action: "print"
    end

    describe "#print_mutations" do
      it_behaves_like "output mutations examples", action: "print"
    end
  end

  describe "write_* helpers" do
    def produce_expected_output(log_file = output_log_file, expected_output)
      write_to_file(log_file, expected_output)
    end

    describe "#write_calls" do
      include_context "order creation"
      it_behaves_like "output calls examples", action: "write"
    end

    describe "#write_traces" do
      include_context "order creation"
      it_behaves_like "output traces examples", action: "write"
    end

    describe "#write_mutations" do
      it_behaves_like "output mutations examples", action: "write"
    end

    let(:output_log_file) { "/tmp/tapping_device.log" }

    it "writes to designated file if log_file is provided" do
      student = Student.new("Stan", 26)
      log_file = "/tmp/another_file.log"

      expected_output = /:name= # #<Class:#<Student:\w+>>
    from: .*:\d+
    changes:
      @name: "Stan" => "Sean"/

      write_mutations(student, log_file: log_file, colorize: false)

      expect { student.name = "Sean" }.to produce_expected_output(log_file, expected_output)

      File.delete(log_file)
    end
  end
end
