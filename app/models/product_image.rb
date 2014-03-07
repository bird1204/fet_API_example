class ProductImage < ActiveRecord::Base
  # attr_accessible :title, :body
  mount_uploader :file, MainImageUploader

  belongs_to :product,:foreign_key => "imageable_id"
  scope :default_order, order("id DESC")

  def to_good_url(bad_url)
    return bad_url.split("?").first.gsub!("https://","http://")
  end

  def update_urls_success?
    begin
      puts "file is #{self.file.present?}"
      # 這邊就寫, 如果 file 存在, 就 update url 要不然就不要 update
      if self.file.present?
        s3_host = "http://soginationaltest.s3.amazonaws.com/"
          update_datas = {
            :url_origin => to_good_url(self.file.url) ,        # 轉原圖
            :url_big    => to_good_url(self.file.big.url),     # 轉大圖
            :url_medium => to_good_url(self.file.medium.url),  # 轉中圖
            :url_small  => to_good_url(self.file.small.url),    # 轉小圖
            :url_thumb  => to_good_url(self.file.thumb.url)    # 轉小小圖
          }  
        if self.update_attributes( update_datas )
          return true
        else
          return false
        end
      end
    rescue Exception => e
      logger.error("Uploader Error!! cannot update url")
      logger.error("==================================")
      logger.error(e)
      logger.error("==================================")
      return false
    end
  end
end
