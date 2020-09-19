class Merchant::DiscountsController < Merchant::BaseController
  def index
    @discounts = current_user.merchant.discounts
  end

  def new
  end

  def create
    merchant = current_user.merchant
    discount = merchant.discounts.new(discount_params)
    if discount.save
      redirect_to "/merchant/discounts"
    else
      generate_flash(discount)
      render :new
    end
  end

  def edit
    @discount = Discount.find(params[:id])
  end

  def update
    @discount = Discount.find(params[:id])
    if @discount.update(discount_params)
      redirect_to "/merchant/discounts"
    else
      generate_flash(@discount)
      render :edit
    end
  end

  def change_status
    discount = Discount.find(params[:id])
    discount.update(active: !discount.active)
    if discount.active?
      flash[:notice] = "#{discount.name} is now available"
    else
      flash[:notice] = "#{discount.name} is no longer available"
    end
    redirect_to '/merchant/discounts'
  end

  def destroy
    discount = Discount.find(params[:id])
    if discount.orders.empty?
      discount.destroy
    else
      flash[:notice] = "#{discount.name} can not be deleted - it has been ordered!"
    end
    redirect_to '/merchant/discounts'
  end

  private

  def discount_params
    params.permit(:name)
  end
end