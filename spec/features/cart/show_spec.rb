require 'rails_helper'
include ActionView::Helpers::NumberHelper

RSpec.describe 'Cart Show Page' do
  describe 'As a Visitor' do
    before :each do
      @morgan = Merchant.create!(name: 'Morgans Marmalades', address: '123 Main St', city: 'Denver', state: 'CO', zip: 80218)
      @brian = Merchant.create!(name: 'Brians Bagels', address: '125 Main St', city: 'Denver', state: 'CO', zip: 80218)
      @ogre = @morgan.items.create!(name: 'Ogre', description: "I'm an Ogre!", price: 20, image: 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTaLM_vbg2Rh-mZ-B4t-RSU9AmSfEEq_SN9xPP_qrA2I6Ftq_D9Qw', active: true, inventory: 25 )
      @giant = @morgan.items.create!(name: 'Giant', description: "I'm a Giant!", price: 50, image: 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTaLM_vbg2Rh-mZ-B4t-RSU9AmSfEEq_SN9xPP_qrA2I6Ftq_D9Qw', active: true, inventory: 3 )
      @hippo = @brian.items.create!(name: 'Hippo', description: "I'm a Hippo!", price: 50, image: 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTaLM_vbg2Rh-mZ-B4t-RSU9AmSfEEq_SN9xPP_qrA2I6Ftq_D9Qw', active: true, inventory: 3 )
      @discount_1 = @morgan.discounts.create!(percent: 20, min_items: 5, active: true)
      @discount_2 = @morgan.discounts.create!(percent: 50, min_items: 10)
      @discount_3 = @morgan.discounts.create!(percent: 75, min_items: 20, active: true)
    end

    describe 'I can see my cart' do
      it "I can visit a cart show page to see items in my cart" do
        visit item_path(@ogre)
        click_button 'Add to Cart'
        visit item_path(@hippo)
        click_button 'Add to Cart'
        visit item_path(@hippo)
        click_button 'Add to Cart'

        visit '/cart'

        expect(page).to have_content("Total: #{number_to_currency((@ogre.price * 1) + (@hippo.price * 2))}")

        within "#item-#{@ogre.id}" do
          expect(page).to have_link(@ogre.name)
          expect(page).to have_content("Price: #{number_to_currency(@ogre.price)}")
          expect(page).to have_content("Quantity: 1")
          expect(page).to have_content("Subtotal: #{number_to_currency(@ogre.price * 1)}")
          expect(page).to have_content("Sold by: #{@morgan.name}")
          expect(page).to have_css("img[src*='#{@ogre.image}']")
          expect(page).to have_link(@morgan.name)
        end

        within "#item-#{@hippo.id}" do
          expect(page).to have_link(@hippo.name)
          expect(page).to have_content("Price: #{number_to_currency(@hippo.price)}")
          expect(page).to have_content("Quantity: 2")
          expect(page).to have_content("Subtotal: #{number_to_currency(@hippo.price * 2)}")
          expect(page).to have_content("Sold by: #{@brian.name}")
          expect(page).to have_css("img[src*='#{@hippo.image}']")
          expect(page).to have_link(@brian.name)
        end
      end

      it "I can visit an empty cart page" do
        visit '/cart'

        expect(page).to have_content('Your Cart is Empty!')
        expect(page).to_not have_button('Empty Cart')
      end

      it "I can visit cart even if no discounts are active" do
        visit "cart"
      end

      describe 'discounts have been applied to the order' do
        before :each do
          @discount_1 = @morgan.discounts.create!(percent: 20, min_items: 5, active: true)
          @discount_2 = @morgan.discounts.create!(percent: 50, min_items: 10)
          @discount_3 = @morgan.discounts.create!(percent: 75, min_items: 20, active: true)
          @discount_4 = @brian.discounts.create!(percent: 90, min_items: 10, active: true)
        end

        it "I can visit a cart show page and not see an active discount unless the min items of one item is met" do
          2.times do
            visit item_path(@ogre)
            click_button 'Add to Cart'
            visit item_path(@hippo)
            click_button 'Add to Cart'
            visit item_path(@hippo)
            click_button 'Add to Cart'
          end

          expect(page).to_not have_content("#{@discount_1.percent}% Off #{@discount_1.min_items} Items or More Discount has been applied!")

        end

        it "I can visit a cart show page and see an active discount having been applied" do
          5.times do
            visit item_path(@ogre)
            click_button 'Add to Cart'
          end

          visit '/cart'

          within "#item-#{@ogre.id}" do
            expect(page).to have_content("Price: #{number_to_currency(@ogre.price)}")
            expect(page).to have_content("Quantity: 5")
            expect(page).to have_content("Subtotal: #{number_to_currency((@ogre.price * 5) - ((@ogre.price * 5) * (@discount_1.percent / 100.0)))}")
            expect(page).to have_content("#{@discount_1.percent}% Off #{@discount_1.min_items} Items or More Discount has been applied!")
          end

        end

        it "I can visit a cart show page and not see an inactive discount having overridden the a current discount now that there are more items in the cart" do
          10.times do
            visit item_path(@ogre)
            click_button 'Add to Cart'
          end

          visit '/cart'

          within "#item-#{@ogre.id}" do
            expect(page).to have_content("Price: #{number_to_currency(@ogre.price)}")
            expect(page).to have_content("Quantity: 10")
            expect(page).to have_content("Subtotal: #{number_to_currency((@ogre.price * 10) - ((@ogre.price * 10) * (@discount_1.percent / 100.0)))}")
            expect(page).to_not have_content("Subtotal: #{number_to_currency((@ogre.price * 10) - ((@ogre.price * 10) * (@discount_2.percent / 100.0)))}")
            expect(page).to have_content("#{@discount_1.percent}% Off #{@discount_1.min_items} Items or More Discount has been applied!")
            expect(page).to_not have_content("#{@discount_2.percent}% Off #{@discount_2.min_items} Items or More Discount has been applied!")
          end

        end

        it "I can visit a cart show page and see an active discount has overridden another discount now that more items are in the cart" do
          20.times do
            visit item_path(@ogre)
            click_button 'Add to Cart'
          end

          visit '/cart'

          expect(page).to have_content("Total: $100")
          
          within "#item-#{@ogre.id}" do
            expect(page).to have_content("Price: #{number_to_currency(@ogre.price)}")
            expect(page).to have_content("Quantity: 20")
            expect(page).to have_content("Subtotal: #{number_to_currency((@ogre.price * 20) - ((@ogre.price * 20) * (@discount_3.percent / 100.0)))}")
            expect(page).to have_content("#{@discount_3.percent}% Off #{@discount_3.min_items} Items or More Discount has been applied!")
            expect(page).to_not have_content("#{@discount_1.percent}% Off #{@discount_1.min_items} Items or More Discount has been applied!")
          end
        end
      end
    end

    describe 'I can manipulate my cart' do
      it 'I can empty my cart' do
        visit item_path(@ogre)
        click_button 'Add to Cart'
        visit item_path(@hippo)
        click_button 'Add to Cart'
        visit item_path(@hippo)
        click_button 'Add to Cart'

        visit '/cart'

        click_button 'Empty Cart'

        expect(current_path).to eq('/cart')
        expect(page).to have_content('Your Cart is Empty!')
        expect(page).to have_content('Cart: 0')
        expect(page).to_not have_button('Empty Cart')
      end

      it 'I can remove one item from my cart' do
        visit item_path(@ogre)
        click_button 'Add to Cart'
        visit item_path(@hippo)
        click_button 'Add to Cart'
        visit item_path(@hippo)
        click_button 'Add to Cart'

        visit '/cart'

        within "#item-#{@hippo.id}" do
          click_button('Remove')
        end

        expect(current_path).to eq('/cart')
        expect(page).to_not have_content("#{@hippo.name}")
        expect(page).to have_content('Cart: 1')
        expect(page).to have_content("#{@ogre.name}")
      end

      it 'I can add quantity to an item in my cart' do
        visit item_path(@ogre)
        click_button 'Add to Cart'
        visit item_path(@hippo)
        click_button 'Add to Cart'
        visit item_path(@hippo)
        click_button 'Add to Cart'

        visit '/cart'

        within "#item-#{@hippo.id}" do
          click_button('More of This!')
        end

        expect(current_path).to eq('/cart')
        within "#item-#{@hippo.id}" do
          expect(page).to have_content('Quantity: 3')
        end
      end

      it 'I can not add more quantity than the items inventory' do
        visit item_path(@hippo)
        click_button 'Add to Cart'
        visit item_path(@hippo)
        click_button 'Add to Cart'
        visit item_path(@hippo)
        click_button 'Add to Cart'

        visit '/cart'

        within "#item-#{@hippo.id}" do
          expect(page).to_not have_button('More of This!')
        end

        visit "/items/#{@hippo.id}"

        click_button 'Add to Cart'

        expect(page).to have_content("You have all the item's inventory in your cart already!")
      end

      it 'I can reduce the quantity of an item in my cart' do
        visit item_path(@hippo)
        click_button 'Add to Cart'
        visit item_path(@hippo)
        click_button 'Add to Cart'
        visit item_path(@hippo)
        click_button 'Add to Cart'

        visit '/cart'

        within "#item-#{@hippo.id}" do
          click_button('Less of This!')
        end

        expect(current_path).to eq('/cart')
        within "#item-#{@hippo.id}" do
          expect(page).to have_content('Quantity: 2')
        end
      end

      it 'if I reduce the quantity to zero, the item is removed from my cart' do
        visit item_path(@hippo)
        click_button 'Add to Cart'

        visit '/cart'

        within "#item-#{@hippo.id}" do
          click_button('Less of This!')
        end

        expect(current_path).to eq('/cart')
        expect(page).to_not have_content("#{@hippo.name}")
        expect(page).to have_content("Cart: 0")
      end
    end


  end
end
