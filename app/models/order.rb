class Order < ApplicationRecord
  has_many :order_items
  has_many :items, through: :order_items
  has_many :order_discounts
  has_many :discounts, through: :order_discounts
  belongs_to :user

  enum status: ['pending', 'packaged', 'shipped', 'cancelled']

  def grand_total
    @total = 0
    order_items.each do |order_item|
      @total += order_item.subtotal
    end
    @total
  end

  def count_of_items
    order_items.sum(:quantity)
  end

  def cancel
    update(status: 'cancelled')
    order_items.each do |order_item|
      order_item.update(fulfilled: false)
      order_item.item.update(inventory: order_item.item.inventory + order_item.quantity)
    end
  end

  def merchant_subtotal(merchant_id)
    @order_item = order_items.joins("JOIN items ON order_items.item_id = items.id").where("items.merchant_id = #{merchant_id}").reduce
    @discounts = Discount.where(active: true).where(merchant_id: merchant_id).where("min_items <= #{@order_item.quantity}").order(percent: :desc).pluck(:percent)
    if @discounts == []
      @total = (@order_item.price * @order_item.quantity).round(2)
    else
      @total = (@order_item.price * @order_item.quantity) - ((@order_item.price * @order_item.quantity) * (@discounts[0] / 100.0)).round(2)
    end
    @total
  end

  def merchant_quantity(merchant_id)
    order_items
      .joins("JOIN items ON order_items.item_id = items.id")
      .where("items.merchant_id = #{merchant_id}")
      .sum('order_items.quantity')
  end

  def is_packaged?
    update(status: 1) if order_items.distinct.pluck(:fulfilled) == [true]
  end

  def self.by_status
    order(:status)
  end
end
