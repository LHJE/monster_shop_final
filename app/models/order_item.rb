class OrderItem < ApplicationRecord
  belongs_to :order
  belongs_to :item

  def subtotal
    @order_items = OrderItem.where(item_id: item.id)
    reverse_discounts = Discount.order(:percent)
    @discounts = reverse_discounts.reverse
    if @discounts != [] && @order_items != []
      if @total.nil?
        @total = 0
      else
        @total = @total
      end
      @order_items.each do |order_item|
        @discounts.each do |discount|
          if item.merchant_id == discount.merchant_id && discount.active && order.id == order_item.order_id && order_item.quantity >= discount.min_items
            @total += (quantity * price) - ((quantity * price) * (discount.percent / 100.0))
          end
        end
        if @total == 0
          @total += quantity * price
        end
      end
    else
      @total = quantity * price
    end
    @total

  end

  def fulfill
    update(fulfilled: true)
    item.update(inventory: item.inventory - quantity)
  end

  def fulfillable?
    item.inventory >= quantity
  end
end
