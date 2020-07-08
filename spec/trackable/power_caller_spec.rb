require "spec_helper"
require "contexts/order_creation"

RSpec.describe TappingDevice do
  include TappingDevice::Trackable

  include_context "order creation"

  class CartOperationServiceForCaller < CartOperationService
    def create_order(cart)
      super
      puts(power_caller)
    end
  end

  let(:cart) { Cart.new }
  let(:service) { CartOperationServiceForCaller.new }

  it "contains correct information" do
    service.perform(cart)
  end
end
