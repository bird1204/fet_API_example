# encoding: utf-8

class MainImageUploader < CarrierWave::Uploader::Base
  # Include RMagick or MiniMagick support:
  include CarrierWave::MiniMagick
  include CarrierWave::MimeTypes
  #include CarrierWave::Compatibility::Paperclip

  #=======================================================================================
  # imagemagick 不能用 就安裝 sudo apt-get install graphicsmagick 再加下面這段, 就可以使用了
  MiniMagick.processor = :gm
  #=======================================================================================

  storage :aws
  @@filename ||= "#{Time.now.strftime("%Y%m%d%H%M%S")}"

  def filename

    file.content_type = "image/jpg" if file.present? # 改變檔案type 變成 jpg 格式, # TODO 若出現轉檔問題，就把這段拆開寫
    second=Time.now.strftime("%S").to_f*0.1
    file_sec= second.round
    @@filename = "#{Time.now.strftime("%Y%m%d%H%M%S")}" if (model.categorized > 1)

    super != nil ? "#{@@filename}.jpg" : super # 重新命名附檔名
  end

  def store_dir 
    case model.categorized.to_s
      when "1"
        "FET_img_product/main_image"
      when "4"
        "FET_img_product/picture"
      else
        "FET_img_product/official"
    end
  end

  # Provide a default URL as a default if there hasn't been a file uploaded:
  # def default_url
  #   "/images/fallback/" + [version_name, "default.png"].compact.join('_')
  # end
  
  # 產品圖片的規格如下:
  #===========================================
  # 產品主圖
  # 360*360 產品的大圖
  # 250*250 產品大圖（很舊的手機沒有360*360）
  # 160*160 產品中圖
  # 100*75 產品小圖

  # 產品寫真
  # 640*480 寫真大圖
  # 100*75 寫真小圖
  #============================================

  # init_filename方法會比內建的filename先跑, 這樣才會覆蓋類別變數@@filename
  process :init_filename

  version :thumb do

    process :resize_and_pad => [100,75], :if => :is_picture_or_official?
    # 轉換成 png
    process :convert => 'png', :if => :is_main_image?
    # 按比例縮成指定大小並且補白
    process :resize_and_pad => [100, 100] , :if => :is_main_image?
  end

  version :small do
    process :convert => 'png', :if => :is_main_image?
    process :resize_and_pad => [160, 160], :if => :is_main_image?
  end
  
  version :medium do
    process :convert => 'png', :if => :is_main_image?
    process :resize_and_pad => [250, 250], :if => :is_main_image?
  end
  
  version :big do
    process :convert => 'png', :if => :is_main_image?
    process :resize_and_pad => [360, 360], :if => :is_main_image?
    process :resize_and_pad => [640,480], :if => :is_picture_or_official?
  end

  def extension_white_list
    %w(jpg jpeg png)
  end

  protected

  def init_filename
    @@filename = "#{model.imageable_id}".gsub(/[\.\/\\\s]+/, "_")
  rescue Exception => e
    @@filename = "Exception"
  end

  def is_main_image?(file)
    model.categorized.to_s == "1"
  end

  def is_picture_or_official?(file)
    model.categorized.to_s != "1"
  end

end
