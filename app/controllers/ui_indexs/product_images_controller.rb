class UiIndexs::ProductImagesController < ApplicationController
  def show
    @product=Product.find(params[:id])  
  end
end
