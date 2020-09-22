class Cart
  attr_reader :contents

  def initialize(contents)
    @contents = contents || {}
    @contents.default = 0
  end

  def add_item(item_id)
    @contents[item_id] += 1
  end

  def less_item(item_id)
    @contents[item_id] -= 1
  end

  def count
    @contents.values.sum
  end

  def items
    @contents.map do |item_id, _|
      Item.find(item_id)
    end
  end

  def grand_total
    grand_total = 0.0
    items = {}
    @contents.each do |item_id, quantity|
      items[Item.find(item_id)]= quantity
    end
    items.each do |item, quantity|
      @discounts = Discount.where(active: true).where(merchant_id: item.merchant_id).where("min_items <= #{quantity}").order(percent: :desc).pluck(:percent)
      if @discounts == []
        grand_total += item.price * quantity
      else
        grand_total += (quantity * item.price) - ((quantity * item.price) * (@discounts[0] / 100.0))
      end
    end
    grand_total
  end

  def count_of(item_id)
    @contents[item_id.to_s]
  end

  def subtotal_of(item_id)
    @contents[item_id.to_s] * Item.find(item_id).price
  end

  def subtotal_with_discount(cart, item_id, discount)
    cart.subtotal_of(item_id) - (cart.subtotal_of(item_id) * (discount.percent / 100.0))
  end

  def limit_reached?(item_id)
    count_of(item_id) == Item.find(item_id).inventory
  end
end
