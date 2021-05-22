require "spec_helper"
require "contexts/order_creation"

RSpec.describe ObjectTracer::Trackable do
  let(:cart) { Cart.new }
  let(:service) { OrderCreationService.new }
  let(:options) { { colorize: false } }

  after do
    File.delete("/tmp/object_tracer.log") if File.exist?("/tmp/object_tracer.log")
  end

  shared_examples "output calls examples" do
    let(:expected_output) do
/:validate_cart # OrderCreationService
    from: .*:.*
    <= {cart: #<Cart:.*>}
    => #<Cart:.*>

:apply_discount # OrderCreationService
    from: .*:.*
    <= {cart: #<Cart:.*>}
    => #<Cart:.*>

:create_order # OrderCreationService
    from: .*:.*
    <= {cart: #<Cart:.*>}
    => #<Order:.*>

:perform # OrderCreationService
    from: .*:.*
    <= {cart: #<Cart:.*>}
    => #<Order:.*>/
    end

    it "prints out target's calls in detail" do
      expect do
        tap_action
        service.perform(cart)
      end.to produce_expected_output(expected_output)
    end

    context "visual test" do
      let(:options) { {} }

      it "prints out target's calls in colorized detail" do
        tap_action

        service.perform(cart)
      end
    end

    context "with tag: option" do
      let(:options) { { colorize: false, tag: "service" } }
      let(:expected_output) do
/:validate_cart \[service\] # OrderCreationService
    from: .*:.*
    <= {cart: #<Cart:.*>}
    => #<Cart:.*>

:apply_discount \[service\] # OrderCreationService
    from: .*:.*
    <= {cart: #<Cart:.*>}
    => #<Cart:.*>

:create_order \[service\] # OrderCreationService
    from: .*:.*
    <= {cart: #<Cart:.*>}
    => #<Order:.*>

:perform \[service\] # OrderCreationService
    from: .*:.*
    <= {cart: #<Cart:.*>}
    => #<Order:.*>/
      end

      it "prints out target's calls in detail" do
        expect do
          tap_action
          service.perform(cart)
        end.to produce_expected_output(expected_output)
      end
    end

    context "with '.with' chained" do
      let(:expected_output) do
/:create_order # OrderCreationService
    from: .*:.*
    <= {cart: #<Cart:.*>}
    => #<Order:.*>/
      end
      it "only prints the calls that matches the with condition" do
        expect do
          tap_action.with do |payload|
            payload.method_name.to_s.match?(/order/)
          end
          service.perform(cart)
        end.to produce_expected_output(expected_output)
      end
    end
  end

  shared_examples "output traces examples" do
    let(:expected_output) do
/Passed as :cart in 'OrderCreationService#:perform' at .*:\d+
Passed as :cart in 'OrderCreationService#:validate_cart' at .*:\d+
Called :total from: .*:\d+
Passed as :cart in 'OrderCreationService#:apply_discount' at .*:\d+
Called :promotion from: .*:\d+
Passed as :cart in 'OrderCreationService#:create_order' at .*:\d+/
    end

    it "prints out what the target sees" do
      expect do
        tap_action
        service.perform(cart)
      end.to produce_expected_output(expected_output)
    end

    context "when chained with .with" do
      let(:expected_output) do
/Passed as :cart in 'OrderCreationService#:perform' at .*:\d+
Passed as :cart in 'OrderCreationService#:validate_cart' at .*:\d+
Passed as :cart in 'OrderCreationService#:apply_discount' at .*:\d+
Passed as :cart in 'OrderCreationService#:create_order' at .*:\d+/
      end

      it "filters output according to the condition" do
        expect do
          proxy = tap_action
          proxy.with do |trace|
            trace.arguments.keys.include?(:cart)
          end
          service.perform(cart)
        end.to produce_expected_output(expected_output)
      end
    end

    context "visual test" do
      let(:options) { {} }

      it "prints out target's calls in colorized detail" do
        tap_action

        service.perform(cart)
      end
    end
  end

  shared_examples "output mutations examples" do
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

      expect do
        tap_action
        student.name = "Sean"
      end.to produce_expected_output(expected_output)
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

      expect do
        tap_action

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

      expect do
        tap_action

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

      expect do
        tap_action
        student.id = 1
        student.reset_data!
      end.to produce_expected_output(expected_output)
    end

    context "visual test" do
      let(:options) { {} }

      it "prints out target's calls in colorized detail" do
        tap_action

        student.id = 1
        student.id = 1
        student.id = nil
      end
    end
  end

  describe "print_* helpers" do
    def produce_expected_output(expected_output)
      output(expected_output).to_stdout
    end

    describe "#print_calls" do
      let(:tap_action) { print_calls(service, options) }

      include_context "order creation"
      it_behaves_like "output calls examples" do
        describe "with_print_calls" do
          it "prints out calls" do
            expect do
              service.with_print_calls(colorize: false).perform(cart)
            end.to produce_expected_output(expected_output)
          end
        end
      end
    end

    describe "#print_traces" do
      let(:tap_action) { print_traces(cart, options) }

      include_context "order creation"
      it_behaves_like "output traces examples" do
        describe "with_print_traces" do
          it "prints out traces" do
            expect do
              service.perform(cart.with_print_traces(colorize: false))
            end.to produce_expected_output(expected_output)
          end
        end
      end
    end

    describe "#print_mutations" do
      let(:student) { Student.new("Stan", 26) }
      let(:tap_action) { print_mutations(student, options) }

      it_behaves_like "output mutations examples"
    end
  end

  describe "print_instance_* helpers" do
    def produce_expected_output(expected_output)
      output(expected_output).to_stdout
    end

    describe "#print_instance_calls" do
      let(:tap_action) { print_instance_calls(OrderCreationService, options) }

      include_context "order creation"
      it_behaves_like "output calls examples"
    end

    describe "#print_instance_traces" do
      let(:tap_action) { print_instance_traces(Cart, options) }

      include_context "order creation"
      it_behaves_like "output traces examples"
    end

    describe "#print_instance_mutations" do
      let(:student) { Student.new("Stan", 26) }
      let(:tap_action) { print_instance_mutations(Student, options) }

      it_behaves_like "output mutations examples"
    end
  end

  describe "write_* helpers" do
    def produce_expected_output(log_file = output_log_file, expected_output)
      write_to_file(log_file, expected_output)
    end

    describe "#write_calls" do
      let(:tap_action) { write_calls(service, options) }

      include_context "order creation"
      it_behaves_like "output calls examples" do
        describe "with_write_calls" do
          it "prints out calls" do
            expect do
              service.with_write_calls(colorize: false).perform(cart)
            end.to produce_expected_output(expected_output)
          end
        end
      end
    end

    describe "#write_traces" do
      let(:tap_action) { write_traces(cart, options) }

      include_context "order creation"
      it_behaves_like "output traces examples" do
        describe "with_write_traces" do
          it "prints out traces" do
            expect do
              service.perform(cart.with_write_traces(colorize: false))
            end.to produce_expected_output(expected_output)
          end
        end
      end
    end

    describe "#write_mutations" do
      let(:student) { Student.new("Stan", 26) }
      let(:tap_action) { write_mutations(student, options) }

      it_behaves_like "output mutations examples"
    end

    let(:output_log_file) { "/tmp/object_tracer.log" }

    it "writes to designated file if log_file is provided" do
      student = Student.new("Stan", 26)
      log_file = "/tmp/another_file.log"

      expected_output = /:name= # #<Class:#<Student:\w+>>
    from: .*:\d+
    changes:
      @name: "Stan" => "Sean"/

      write_mutations(student, options.merge(log_file: log_file))

      expect { student.name = "Sean" }.to produce_expected_output(log_file, expected_output)

      File.delete(log_file)
    end
  end

  describe "write_instance_* helpers" do
    let(:output_log_file) { "/tmp/object_tracer.log" }

    def produce_expected_output(log_file = output_log_file, expected_output)
      write_to_file(log_file, expected_output)
    end

    describe "#write_instance_calls" do
      let(:tap_action) { write_instance_calls(OrderCreationService, options) }

      include_context "order creation"
      it_behaves_like "output calls examples"
    end

    describe "#write_instance_traces" do
      let(:tap_action) { write_instance_traces(Cart, options) }

      include_context "order creation"
      it_behaves_like "output traces examples"
    end

    describe "#write_instance_mutations" do
      let(:student) { Student.new("Stan", 26) }
      let(:tap_action) { write_instance_mutations(Student, options) }

      it_behaves_like "output mutations examples"
    end
  end
end
