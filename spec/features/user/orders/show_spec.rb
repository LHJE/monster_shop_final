require 'rails_helper'
include ActionView::Helpers::NumberHelper

RSpec.describe 'Order Show Page' do
  describe 'As a Registered User' do
    before :each do
      @morgan = Merchant.create!(name: 'Morgans Marmalades', address: '123 Main St', city: 'Denver', state: 'CO', zip: 80218)
      @brian = Merchant.create!(name: 'Brians Bagels', address: '125 Main St', city: 'Denver', state: 'CO', zip: 80218)
      @sal = Merchant.create!(name: 'Sals Salamanders', address: '125 Main St', city: 'Denver', state: 'CO', zip: 80218)
      @ogre = @morgan.items.create!(name: 'Ogre', description: "I'm an Ogre!", price: 20.25, image: 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTaLM_vbg2Rh-mZ-B4t-RSU9AmSfEEq_SN9xPP_qrA2I6Ftq_D9Qw', active: true, inventory: 25 )
      @giant = @morgan.items.create!(name: 'Giant', description: "I'm a Giant!", price: 50, image: 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTaLM_vbg2Rh-mZ-B4t-RSU9AmSfEEq_SN9xPP_qrA2I6Ftq_D9Qw', active: true, inventory: 3 )
      @hippo = @brian.items.create!(name: 'Hippo', description: "I'm a Hippo!", price: 50, image: 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTaLM_vbg2Rh-mZ-B4t-RSU9AmSfEEq_SN9xPP_qrA2I6Ftq_D9Qw', active: true, inventory: 1 )
      @user = User.create!(name: 'Morgan', address: '123 Main St', city: 'Denver', state: 'CO', zip: 80218, email: 'morgan_1@example.com', password: 'securepassword')
      @discount_1 = @morgan.discounts.create!(percent: 20, min_items: 5, active: true)
      @discount_2 = @morgan.discounts.create!(percent: 50, min_items: 10)
      @discount_3 = @morgan.discounts.create!(percent: 75, min_items: 20, active: true)
      @order_1 = @user.orders.create!(status: "packaged")
      @order_2 = @user.orders.create!(status: "pending")
      @order_3 = @user.orders.create!(status: "pending")
      @order_item_1 = @order_1.order_items.create!(item: @ogre, price: @ogre.price, quantity: 2, fulfilled: true)
      @order_item_2 = @order_2.order_items.create!(item: @giant, price: @giant.price, quantity: 2, fulfilled: true)
      @order_item_3 = @order_2.order_items.create!(item: @ogre, price: @ogre.price, quantity: 21, fulfilled: false)
      allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(@user)
    end

    it 'I can link from my orders to an order show page' do
      visit '/profile/orders'

      click_link @order_1.id

      expect(current_path).to eq("/profile/orders/#{@order_1.id}")
    end

    it 'I see order information on the show page' do
      visit "/profile/orders/#{@order_2.id}"

      expect(page).to have_content(@order_2.id)
      expect(page).to have_content("Created On: #{@order_2.created_at}")
      expect(page).to have_content("Updated On: #{@order_2.updated_at}")
      expect(page).to have_content("Status: #{@order_2.status}")
      expect(page).to have_content("#{@order_2.count_of_items} items")
      expect(page).to have_content("Total: #{number_to_currency(@order_2.grand_total)}")
      expect(page).to have_content("Total: $206.31")

      within "#order-item-#{@order_item_2.id}" do
        expect(page).to have_link(@order_item_2.item.name)
        expect(page).to have_content(@order_item_2.item.description)
        expect(page).to have_content(@order_item_2.quantity)
        expect(page).to have_content(@order_item_2.price)
        expect(page).to have_content(@order_item_2.subtotal)
        expect(page).to have_content("Subtotal: $100.00")
      end

      within "#order-item-#{@order_item_3.id}" do
        expect(page).to have_link(@order_item_3.item.name)
        expect(page).to have_content(@order_item_3.item.description)
        expect(page).to have_content(@order_item_3.quantity)
        expect(page).to have_content(@order_item_3.price)
        expect(page).to have_content(@order_item_3.subtotal)
        expect(page).to have_content("Subtotal: $106.31")
      end
    end

    it 'I see a link to cancel an order, only on a pending order show page' do
      visit "/profile/orders/#{@order_1.id}"

      expect(page).to_not have_button('Cancel Order')

      visit "/profile/orders/#{@order_2.id}"

      expect(page).to have_button('Cancel Order')
    end

    it 'I can cancel an order to return its contents to the items inventory' do
      visit "/profile/orders/#{@order_2.id}"

      click_button 'Cancel Order'

      expect(current_path).to eq("/profile/orders/#{@order_2.id}")
      expect(page).to have_content("Status: cancelled")

      @giant.reload
      @ogre.reload
      @order_item_2.reload
      @order_item_3.reload

      expect(@order_item_2.fulfilled).to eq(false)
      expect(@order_item_3.fulfilled).to eq(false)
      expect(@giant.inventory).to eq(5)
      expect(@ogre.inventory).to eq(46)
    end
  end
end
