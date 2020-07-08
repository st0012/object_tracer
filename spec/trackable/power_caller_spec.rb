require "spec_helper"
require "contexts/order_creation"

RSpec.describe TappingDevice do
  include TappingDevice::Trackable

  include_context "order creation"

  class CartOperationServiceForCaller < CartOperationService
    def create_order(cart)
      super
      a_method_with_block do |one|
        inspect_method
      end
    end

    def a_method_with_block
      yield
    end

    def inspect_method
      puts(power_caller)
    end
  end

  let(:cart) { Cart.new }
  let(:service) { CartOperationServiceForCaller.new }

  it "contains correct information" do
    service.perform(cart)
  end
end
