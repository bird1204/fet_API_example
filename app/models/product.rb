class Product < ActiveRecord::Base
  # attr_accessible :title, :body
  #set_primary_key :product_id
  has_many :features , :dependent => :destroy
  has_many :product_spec_displays , :dependent => :destroy
  #has_many :product_images,:foreign_key => "imageable_id"


  has_one :main_image, :as => :imageable, :class_name => "ProductImage", :conditions => { "product_images.categorized" => 1 } , :dependent => :destroy # 別名的寫法
  has_many :big_official_image, :as => :imageable, :class_name => "ProductImage", :conditions => { 'product_images.categorized' => 3 } , :dependent => :destroy
  has_many :picture, :as => :imageable, :class_name => "ProductImage", :conditions => { 'product_images.categorized' => 4 } , :dependent => :destroy
  
  accepts_nested_attributes_for :main_image
  accepts_nested_attributes_for :big_official_image
  accepts_nested_attributes_for :picture

  def current_main_image
    # 前者如果是 nil 就會等於後者否者就是自己本身
    if self.main_image.blank?
      self.build_main_image
    else
      self.main_image
    end
  end

  def current_official_image
    if self.big_official_image.blank?
      self.big_official_image.new
    else
      self.big_official_image
    end
  end

  def current_picture
    if self.picture.blank?
      self.picture.new
    else
      self.picture
    end
  end

end
