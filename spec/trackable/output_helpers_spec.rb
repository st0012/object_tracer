require "spec_helper"
require "contexts/order_creation"

RSpec.describe TappingDevice::Trackable do
  let(:cart) { Cart.new }
  let(:service) { CartOperationService.new }

  shared_examples "output calls examples" do
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

  shared_examples "output traces examples" do
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
        proxy = tap_action
        proxy.with do |trace|
          trace.arguments.keys.include?(:cart)
        end

        expect { service.perform(cart) }.to produce_expected_output(expected_output)
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
      let(:tap_action) { print_calls(service, colorize: false) }

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
      let(:tap_action) { print_traces(cart, colorize: false) }

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
      let(:tap_action) { print_mutations(student, colorize: false) }

      it_behaves_like "output mutations examples"
    end
  end

  describe "print_instance_* helpers" do
    def produce_expected_output(expected_output)
      output(expected_output).to_stdout
    end

    describe "#print_instance_calls" do
      let(:tap_action) { print_instance_calls(CartOperationService, colorize: false) }

      include_context "order creation"
      it_behaves_like "output calls examples"
    end

    describe "#print_instance_traces" do
      let(:tap_action) { print_instance_traces(Cart, colorize: false) }

      include_context "order creation"
      it_behaves_like "output traces examples"
    end

    describe "#print_instance_mutations" do
      let(:student) { Student.new("Stan", 26) }
      let(:tap_action) { print_instance_mutations(Student, colorize: false) }

      it_behaves_like "output mutations examples"
    end
  end

  describe "write_* helpers" do
    def produce_expected_output(log_file = output_log_file, expected_output)
      write_to_file(log_file, expected_output)
    end

    describe "#write_calls" do
      let(:tap_action) { write_calls(service, colorize: false) }

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
      let(:tap_action) { write_traces(cart, colorize: false) }

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
      let(:tap_action) { write_mutations(student, colorize: false) }

      it_behaves_like "output mutations examples"
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

  describe "write_instance_* helpers" do
    let(:output_log_file) { "/tmp/tapping_device.log" }

    def produce_expected_output(log_file = output_log_file, expected_output)
      write_to_file(log_file, expected_output)
    end

    describe "#write_instance_calls" do
      let(:tap_action) { write_instance_calls(CartOperationService, colorize: false) }

      include_context "order creation"
      it_behaves_like "output calls examples"
    end

    describe "#write_instance_traces" do
      let(:tap_action) { write_instance_traces(Cart, colorize: false) }

      include_context "order creation"
      it_behaves_like "output traces examples"
    end

    describe "#write_instance_mutations" do
      let(:student) { Student.new("Stan", 26) }
      let(:tap_action) { write_instance_mutations(Student, colorize: false) }

      it_behaves_like "output mutations examples"
    end
  end
end
