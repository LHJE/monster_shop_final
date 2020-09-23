class OrderItem < ApplicationRecord
  belongs_to :order
  belongs_to :item

  def subtotal
    if @total.nil?
      @total = 0
    end
    @order_item = OrderItem.where(item_id: item.id).where(order_id: order.id).reduce
    if @order_item == []
      @total = quantity * price
    else
      @discounts = Discount.where(active: true).where(merchant_id: item.merchant_id).where("min_items <= #{@order_item.quantity}").order(percent: :desc).pluck(:percent)
      if @discounts == []
        @total += quantity * price
      else
        @total += (quantity * price) - ((quantity * price) * (@discounts[0] / 100.0))
      end
    end
    @total.round(2)
  end

  def fulfill
    update(fulfilled: true)
    item.update(inventory: item.inventory - quantity)
  end

  def fulfillable?
    item.inventory >= quantity
  end
end
