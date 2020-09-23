class OrderItem < ApplicationRecord
  belongs_to :order
  belongs_to :item

  def subtotal
    @total = 0
    @order_item = OrderItem.where(item_id: item.id).where(order_id: order.id).reduce
    @discounts = Discount.where(active: true).where(merchant_id: item.merchant_id).where("min_items <= #{@order_item.quantity}").order(percent: :desc).pluck(:percent)
    if @discounts == []
      @total = (quantity * price).round(2)
    else
      @total = (quantity * price) - ((quantity * price) * (@discounts[0] / 100.0)).round(2)
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
