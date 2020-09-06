# typed: true
RSpec.shared_context "order creation" do
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
  class OrderCreationService
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
