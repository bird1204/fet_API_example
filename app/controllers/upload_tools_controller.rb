class UploadToolsController < ApplicationController
   # 多圖上傳參考下列網址
  # 分享
  # http://gloryspring.blog.51cto.com/5470544/1065808
  # Demo
  # https://code.google.com/p/swfupload/
  # before_filter :init_picture
  
  before_filter :init_option_params

  def create   
    if @option["resource_type"].present? && @option["resource_id"].present?
      case @option["resource_type"].downcase
        when 'product'
          product = Product.find(@option["resource_id"].to_i)
          case @table_params["categorized"]
            when 1
              media = product.current_main_image
            when 3
              media = product.big_official_image.new(@table_params)          
            when 4
              media = product.picture.new(@table_params)
            else
              media = "null"
          end
          media.file = params[:file]
          media.save!
          media.update_urls_success?
      end
      render json: {:small => media.file.small.url, :medium => media.file.medium.url, :big => media.file.big.url, :original => media.file.url}
    end
  rescue Exception => e
    logger.error(e)
    p  "error_404 => #{e}"
  end

  protected

  def init_option_params
    # option: 自訂設定參數
    @option = params[:option].present? ? JSON.parse(params[:option].gsub("&quot;", '"')) : Hash.new
    # table_params: 傳進來的table params資料
    @table_params = params[:table_params].present? ? JSON.parse(params[:table_params].gsub("&quot;", '"')) : Hash.new
  end
end
