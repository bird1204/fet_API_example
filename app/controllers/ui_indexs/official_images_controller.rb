# encoding: utf-8
class UiIndexs::OfficialImagesController < ApplicationController
  before_filter :init_categorized
  def show
    params[:format]=params[:id]
    @id=params[:format]
    @image_urls=ProductImage.where("imageable_id = #{params[:id]} and categorized = #{@categorized}")
    redirect_to new_ui_indexs_official_image_path(params) if @image_urls.blank?
  end

  def new
    delete if params[:commit] == "刪除圖片"
    @product=Product.find(params[:format])
    @add_images=Array.new(10){"1"}
  end

  def delete
    @working_image=Hash.new
    params.keys.each do |work|
      list_state=work.scan(/_(\d*)/).first
      @working_image=@working_image.merge("#{list_state.first}" => TRUE) if list_state.present?
    end
    @product=Product.find(params[:format])
    @product.update_attributes!(:is_pic_trans => 1)  if @categorized == 3
    @product.update_attributes!(:is_info_trans => 1) if @categorized == 4
    need_delete_images=ProductImage.where("imageable_id = #{params[:format]} and categorized = #{@categorized}")
    need_delete_images.each_with_index do |delete_image,index|
      delete_image.delete if @working_image["#{index}"].present?
    end
    if  @categorized == 3
      redirect_to ui_indexs_official_image_path(@product.id,:image_type=>"official")
      return
    else
      redirect_to ui_indexs_official_image_path(@product.id,:image_type=>"product")
      return
    end
  end

  def upload
    product=Product.find(params[:format])
    product.big_official_image.delete_all if product.big_official_image.present?
    SProduct.find(product.product_id).s_product_image.where(:categorized => 2).each do |image|
      product.big_official_image.new(:remote_file_url=>image.url_big,:imageable_id=>product.id)
      product.save!
      product.big_official_image.last.update_urls_success? if product.big_official_image.present? 
    end
    redirect_to :back
  end

  protected
  def init_categorized
    @categorized = (params[:image_type] == "official")? 3 : 4
  end
end
