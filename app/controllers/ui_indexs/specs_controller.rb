# encoding: utf-8

class UiIndexs::SpecsController < ApplicationController
  def edit
    @product=Product.find_by_id(params[:id])
    @display_array=Array.new
    SpecClass.includes(:product_spec_displays).where("product_spec_displays.product_id = ?",params[:id]).each do |spec_class|
      spec_class.product_spec_displays.each do |d|
          @display_array << { 
            :display_id => d.id,
            :product_id => d.product_id,
            :spec_name => d.spec.name,
            :spec_class_name => spec_class.name,
            :display_name => d.name,
            :remark => d.spec.remark
          }
      end
    end

    if @display_array.blank? 
      spec_class_id = ((@product.product_type == 3)? 9 : 10) if @product.product_type > 2
      Spec.where(:spec_class_id => spec_class_id).each do |spec_display|
        ProductSpecDisplay.create(:spec_id => spec_display.spec_id,:product_id =>params[:id])
      end
      edit
    else
      @display_array=@display_array.sort_by {|k|  k[:spec_class_name] }
      @display_array=@display_array.sort_by {|k|  k[:sort] }
    end

    
  end

  def update
    # 修改異動規格 -> :is_spec_trans=>true
    # 補上缺少規格 -> :is_spec_trans=>false
    params.keys.each do |id|
      if is_numeric?(id) 
        @product_spec_display=ProductSpecDisplay.find(id)
        @product_spec_display.update_attributes(:name=>params[id])
      end 
    end
    redirect_to edit_ui_indexs_spec_path(params[:id])
  end
  def is_numeric?(obj) 
    obj.to_s.match(/\A[+-]?\d+?(\.\d+)?\Z/) == nil ? false : true
  end

  
end
