require 'rails_helper'
include ActionView::Helpers::NumberHelper

RSpec.describe 'New Merchant Discount' do
  describe 'As a Merchant' do
    before :each do
      @merchant_1 = Merchant.create!(name: 'Morgans Marmalades', address: '123 Main St', city: 'Denver', state: 'CO', zip: 80218)
      @m_user = @merchant_1.users.create(name: 'Morgan', address: '123 Main St', city: 'Denver', state: 'CO', zip: 80218, email: 'morgan@example.com', password: 'securepassword')
      allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(@m_user)
    end

    it 'I can click a link to a new discount form page' do
      visit "/merchant/discounts"

      click_link 'New Discount'

      expect(current_path).to eq("/merchant/discounts/new")
    end

    it 'I can create an  discount for a merchant' do
      percent = 110
      min_items = 4

      visit "/merchant/discounts/new"

      fill_in 'Percent', with: percent
      fill_in 'Min items', with: min_items

      click_button 'Create Discount'

      expect(current_path).to eq("/merchant/discounts")
      expect(page).to have_content(percent)
      expect(page).to have_content(min_items)
      expect(page).to have_content("Inactive")
    end

    it 'I can not create an  discount for a merchant with an incomplete form' do
      percent = ''
      min_items = 4

      visit "/merchant/discounts/new"

      fill_in 'Percent', with: percent
      fill_in 'Min items', with: min_items
      click_button 'Create Discount'

      expect(page).to have_content("percent: [\"can't be blank\"]")

      expect(page).to have_button('Create Discount')
    end
  end
end
