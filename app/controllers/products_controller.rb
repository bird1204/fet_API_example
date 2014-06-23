# encoding: utf-8

class ProductsController < ApplicationController
  before_filter :init_product_ids , :only=>[:import_spec,:update_spec,:import_info,:update_info,:import_pic,:update_pic]
  before_filter :init_s3_connection , :only=>[:import_pic]#,:sync,:import_all_image,:import_all_product]
  ## 系統轉換時使用的程式
  #before_filter :init_fet_and_sogi_field_list , :only=>[:sync,:insert_sql,:import_all_product]

  # def import_all_image
  #   ProductImage.delete_all
  #   p "-------------------START-------------------"
    
  #   all_images=Array.new

  #   path="FET_img_product/official"
  #   p "fetching official key ...."
  #   aws_product_keys=@bucket.objects.with_prefix("#{path}/").collect(&:key)
  #   official_array=aws_big_or_small_image_filter(aws_product_keys,path,"official")
  #   all_images << official_array

  #   path="FET_img_product/picture"
  #   p "fetching picture key ...."
  #   aws_product_keys=@bucket.objects.with_prefix("#{path}/").collect(&:key)
  #   picture_array=aws_big_or_small_image_filter(aws_product_keys,path,"picture")
  #   all_images << picture_array

  #   all_images.each do |images|
  #     if images.present?
  #       images.each do |image|
  #         ProductImage.create(image)
  #       end
  #     end
  #   end

  #   Product.find_in_batches do |products|
  #     products.each do |product|
  #       id=(product.id.present?)? product.id : product.product_id
  #       ProductImage.create(:imageable_id => product.id,:categorized => 1,:imageable_type => "Product",
  #         :url_big => "http://sogi-attach.s3.amazonaws.com/FET_img_product/360/NO_#{id}.jpg",
  #         :url_medium => "http://sogi-attach.s3.amazonaws.com/FET_img_product/250/NO_#{id}.jpg",
  #         :url_small => "http://sogi-attach.s3.amazonaws.com/FET_img_product/160/NO_#{id}.jpg",
  #         :url_thumb => "http://sogi-attach.s3.amazonaws.com/FET_img_product/100/NO_#{id}.jpg"
  #         )
  #     end
  #   end
  #   p "product_main_images ------------------- DONE"
  #   redirect_to products_path
  # end

  # def import_all_product
  #   Product.delete_all
  #   Feature.delete_all
  #   ProductSpecDisplay.delete_all
  #   p "-------------------START-------------------"

  #   insert_with_ORM(@sogi_fields[:MsProduct],@fet_fields[:Product])
  #   p "products ------------------- DONE" 

  #   insert_with_ORM(@sogi_fields[:MsFeature],@fet_fields[:Feature])
  #   p "features ------------------- DONE"

  #   insert_with_ORM(@sogi_fields[:MsProductSpecDisplay],@fet_fields[:ProductSpecDisplay])
  #   p "product_spec_displays ------------------- DONE"  
  #   redirect_to products_path
  # end

  # def sync
  #   Spec.delete_all
  #   SpecClass.delete_all
  #   #   SEE
  #   #   https://www.coffeepowered.net/2009/01/23/mass-inserting-data-in-rails-without-killing-your-performance/    
  #   #
  #   #   benchmark_sql           : 0.010000 0.000000 0.010000 ( 0.325680) 
  #   #   benchmark_active_record : 0.440000 0.150000 0.590000 ( 1.991017)
  #   p "-------------------START-------------------"
    
  #   insert_with_ORM(@sogi_fields[:MsSpec],@fet_fields[:ms][:Spec])
  #   p "specs ------------------- DONE"
 
  #   insert_with_ORM(@sogi_fields[:MsSpecClass],@fet_fields[:ms][:SpecClass])     
  #   p "spec_classes ------------------- DONE" 
  #   redirect_to products_path
  # end

  # def insert_with_ORM(sogi_fields,fet_fields)
  #   sogi_tables=@sogi_fields.key(sogi_fields).to_s
  #   fet_table=@fet_fields.key(fet_fields).to_s
  #   is_not_spec=true if fet_table.present?

  #   fet_table=@fet_fields[:ms].key(fet_fields).to_s if fet_table.blank?

  #   sogi_tables.constantize.find_in_batches(:batch_size =>1000) do |sogi_table|
  #     sogi_table.each do |sogi_record|
  #       hash=Hash.new
  #       sogi_fields.each_with_index do |sogi_field,index|
  #         hash=hash.merge(fet_fields[index].to_sym => sogi_record.send(sogi_field))
  #       end        
  #       new_record=fet_table.constantize.new(hash)
  #       new_record.id = sogi_record.id if is_not_spec
  #       new_record.save!
  #     end
  #   end
  # end

  def import_spec
    @product_ids.each do |id|
      product=Product.find_or_initialize_by_product_id(id)
      sogi_specs=SProductSpecDisplay.where(:product_id => id)
      
      product_spec_displays=ProductSpecDisplay.where(:product_id => product.id)
      product_spec_displays.delete_all if product_spec_displays.present?
      
      update_product_spec_display(sogi_specs,product)
      feature_create(product.id)
    end
    redirect_to products_path    
  end

  def import_info
    @product_ids.each do |id|
      product=Product.find_or_initialize_by_product_id(id)
      return if !product.new_record?
      product.attributes=init_product_attributes(id,true)
      product.save!

    end
    redirect_to products_path
  end
  
  def import_pic
    #   using fog
    #   benchmark_first_way(1 product)  :  1.060000   0.220000   1.280000 ( 47.151362)
    #   benchmark_first_way(2 product)  :  1.510000   0.370000   1.880000 ( 61.318670)

    # SEE AWSRubySDK
    # http://docs.aws.amazon.com/AWSRubySDK/latest/AWS/S3/S3Object.html#copy_from-instance_method
    #   using aws-sdk
    #   benchmark_first_way(1 product)  :  0.030000   0.040000   0.070000 (  2.736472)
    #   benchmark_first_way(2 product)  :  0.210000   0.020000   0.230000 (  3.672600)
    @product_ids.each do |id|
      product=Product.find_by_product_id(id)

      SProduct.find(id).s_product_image.where(:categorized => 1).each do |image|
        product.main_image.delete if product.main_image.present?
        product.build_main_image.remote_file_url=image.url_big 
        product.save!      
        product.main_image.update_urls_success? if product.main_image.present?
      end

      SProduct.find(id).s_product_image.where(:categorized => 2).each do |image|
        values={
          :imageable_id => product.id,
          :categorized => 3,
          :imageable_type => image.imageable_type,
          :url_big => image.url_big,
          :url_medium => image.url_medium,
          :url_small => image.url_small,
          :url_thumb => image.url_small
        }          
        product.big_official_image.delete_all if product.big_official_image.present?
        ProductImage.create(values)
 
      end
    end
    redirect_to products_path
  end

  def update_all_spec
    ProductSpecDisplay.where("spec_id in (34,35)").each do |display|
      display.update_attributes!(:name=>display.name.split("*").first,:is_spec_trans =>1) if display.name[/\*/]
    end  

    ProductSpecDisplay.where("spec_id = 50 and name not regexp '.* [0-9].*'").each do |display|
      display_name = String.new
      SProductSpecDisplay.where(:product_id => display.product.product_id).each do |sogi_spec|
        if fet_spec_builder(sogi_spec,display.product.product_type) == 50
          if display_name[/\d/]
            display_name = (display_name.blank?)? sogi_spec.spec_value : "#{sogi_spec.spec_value} #{display_name}"
          else
            display_name = (display_name.blank?)? sogi_spec.spec_value : "#{display_name} #{sogi_spec.spec_value}"      
          end
        end
      end
      display.update_attributes!(:name => display_name,:is_spec_trans =>1)
    end 
    redirect_to products_path
  end
  
  def update_spec
    update_all_spec if @product_ids.first=="all"

    @product_ids.each do |id|
      product=Product.find_by_product_id(id)
      product.update_attributes(:is_spec_trans =>1)

      product_spec_displays=ProductSpecDisplay.where(:product_id => product.id)
      product_spec_displays.delete_all if product_spec_displays.present?

      sogi_specs=SProductSpecDisplay.where(:product_id => id)
      update_product_spec_display(sogi_specs,product)
      feature_create(product.id)
    end

    redirect_to products_path
  end

  def update_info
    @product_ids.each do |id|
      product=Product.find_or_initialize_by_product_id(id)
      product.attributes=init_product_attributes(id,false)
      product.save!
    end
    redirect_to products_path
  end

  def update_pic
    @product_ids.each do |id|
      product=Product.find_by_product_id(id)
      product.update_attributes(:is_pic_trans => 1)
      product.main_image.delete
      product.big_official_image.delete_all
    end
    import_pic
  end

  def update_product_spec_display(sogi_specs,fet_product)
    sogi_specs.each do |sogi| 
      spec_id = fet_spec_builder(sogi,fet_product.product_type)
      display = ProductSpecDisplay.find_or_initialize_by_product_id_and_spec_id(fet_product.id,spec_id)
    
      sogi_display_name = sogi.spec_value
      # spec_id = 60 , 50 為多筆資料合併成一筆寫入資料庫
      # spec_id = 57 為一筆資料分成多筆寫入資料庫
      case spec_id
        when 60 #平版的長寬高 合併成尺寸(spec_id = 60)
          sogi_display_name = (display.name.blank?)? sogi_display_name.gsub("mm(公厘)","mm") : "#{display.name} x #{sogi_display_name}".gsub("mm(公厘)","mm")
        when 50 #平版記憶卡插槽和ROM 合併成支援記憶卡(最高容量)
          sogi_display_name = sogi_display_name.split(",").first
          if sogi_display_name[/\d/]
            sogi_display_name = (display.name.blank?)? sogi_display_name : "#{display.name} #{sogi_display_name}"
          else
            sogi_display_name = (display.name.blank?)? sogi_display_name : "#{sogi_display_name} #{display.name}"
          end
        when 57 #檢查機身設計的內容有沒有包含耳機跟立體聲喇叭
          #耳機輸出 (3.5mm 耳機孔 | null) / spec_id = 59
          if sogi_display_name[/3.5mm( |)耳機孔/] 
            headPhone = ProductSpecDisplay.find_or_initialize_by_product_id_and_spec_id(fet_product.id,spec_id)
            headPhone.attributes = {:product_id => fet_product.id, 
                                    :name => "3.5mm 耳機孔", 
                                    :spec_id => 59
                                    }
            headPhone.save!                      
          end

          #立體聲喇叭  (有 | 無)  / spec_id = 57
          sogi_display_name = "無"
          sogi_display_name = "有" if sogi_display_name[/立體聲喇叭/]
      end

      display.attributes = {:product_id => fet_product.id, 
                            :name => sogi_display_name.gsub("，",","), #20140619 ，改,
                            :spec_id => spec_id
                          }
      display.save!
    end

    if fet_product.product_type == 2
      Spec.where(:spec_class_id=>8).each do |spec|
        is_need = true
        ProductSpecDisplay.where(:product_id=>fet_product.id).each do |display|
          is_need = false if display.spec_id==spec.spec_id
        end
        ProductSpecDisplay.create(:product_id => fet_product.id,:spec_id => spec.spec_id) if is_need
      end
    end
    
    spec_classes={1 => 1, 2 => 8, 3 => 9, 4 => 10}
    Spec.where("name like ? and spec_class_id = ?","%LTE%",spec_classes[fet_product.product_type]).select(:spec_id).each do |spec|
      display=ProductSpecDisplay.find_or_initialize_by_product_id_and_spec_id(fet_product.id,spec.spec_id)
      display.attributes = {:product_id => fet_product.id, 
                            :spec_id => spec.spec_id
                          }
      display.save!
    end
  end

  def fet_spec_builder(specs,product_type)
    if product_type == 1
      case specs.spec_name_local
        when /頻率系統/
          return 1
        when /內建相機畫素/
          return 2    
        when /相機功能/
          return 3
        when /鈴聲種類/
          return 4
        when /內建記憶體/
          return 5
        when /內建儲存空間/
          return 5
        when /藍牙版本/
          return 6
        when /RAM記憶體/
          return 7
        when /音樂播放器/
          return 8
        when /作業系統/
          return 9
        when /傳輸介面/
          return 10
        when '處理器'
          return 11
        when /記憶卡插槽/
          return 12
        when /感光元件/
          return 13
        when /錄影格式/
          return 14
        when /圖片支援格式/
          return 15 #ASK
        when /影片播放格式/
          return 16
        when /和弦鈴聲/
          return 17
        when /視訊鏡頭/
          return 18
        when /主螢幕材質/
          return 19 
        when /主螢幕色彩/
          return 20
        when /主螢幕尺寸/
          return 21
        when /主螢幕解析度/
          return 22
        when /E-mail格式/
          return 23 
        when /簡訊格式/
          return 24
        when /上網方式/
          return 25
        when /Office文件/
          return 26
        when /輸入法/
          return 27    
        when /實用工具/
          return 28
        when /進階功能/
          return 29
        when /機身長度/
          return 30
        when /機身寬度/
          return 31
        when /機身厚度/
          return 32
        when /機身重量/
          return 33    
        when /通話時間/
          return 34
        when /待機時間/
          return 35
        when /電池容量/
          return 36
        when /操作介面/
          return 37
        when /機身顏色/
          return 38
        when /機身設計/
          return 41    
        when '處理器分類'
          return 117
      end
    end

    if product_type == 2
      case specs.spec_name_local
        when /機身顏色/
          return 43
        when /進階功能/
          return 44      
        when /主螢幕解析度/
          return 45
        when '處理器'
          return 46
        when /作業系統/
          return 47
        when /RAM記憶體/
          return 48
        when /硬碟容量/
          return 49
        when /記憶卡插槽/
          return 50
        when /內建記憶體/
          return 50
        when /內建儲存空間/
          return 50
        when /內建相機畫素/
          return 51
        when /頻率系統/
          return 52
        when /上網方式/
          return 53
        # '54 多點觸控
        # '55 讀卡機
        when /傳輸介面/
          return 56
        when /機身設計/
          return 57
        # '58麥克風輸入  
        when /機身設計/
          return 59 #ASK
        when /機身長度/
          return 60
        when '機身寬度'
          return 60
        when /機身厚度/
          return 60
        when /機身重量/
          return 61 
        when /電池容量/
          return 62
        when /待機時間/
          return 63
        # '64標準配件
        when /Office文件/
          return 65
        # '66 支援 Flash 播放
        when '進階功能'
          return 67 #ASK
        # '68內建社群服務  
        when /實用工具/
          return 69
        # '70 保固
        # '71 技術支援專線
        when '處理器分類'
          return 119
        else
          return specs.spec_id
      end
    end
  end

  ## 系統轉換時使用的程式
  # def aws_big_or_small_image_filter(aws_product_keys,path,categorized)
  #   image_array=Array.new
  #   aws_product_keys.each do |key|
  #     case categorized
  #       when "official"
  #         if key.scan(/\/(\d*)\/(b_.*)/).present?
  #           image_with_id_and_url=key.scan(/\/(\d*)\/(b_.*)/).first
  #           url="http://sogi-attach.s3.amazonaws.com/#{path}/#{image_with_id_and_url[0]}/" 
  #           image_array << {:imageable_id => image_with_id_and_url.first,
  #                         :categorized => 3 ,
  #                         :url_big => "#{url}#{image_with_id_and_url[1]}",
  #                         :url_thumb => "#{url}#{image_with_id_and_url[1].gsub("b_","s_")}",
  #                         :imageable_type => "Product",
  #                         :created_at => "'#{Time.now.to_s(:db)}'",
  #                         :updated_at => "'#{Time.now.to_s(:db)}'"
  #                         }
  #         end
  #     when "picture"
  #         if key.scan(/\/(\d*)\/(b_.*)/).present?
  #           picture_with_id_and_url=key.scan(/\/(\d*)\/(b_.*)/).first
  #           url="http://sogi-attach.s3.amazonaws.com/#{path}/#{picture_with_id_and_url[0]}/" 
  #           image_array << {:imageable_id => picture_with_id_and_url.first,
  #                         :categorized => 4,
  #                         :url_big => "#{url}#{picture_with_id_and_url[1]}",
  #                         :url_thumb => "#{url}#{picture_with_id_and_url[1].gsub("b_","s_")}",
  #                         :imageable_type => "Product",
  #                         :created_at => "#{Time.now.to_s(:db)}",
  #                         :updated_at => "#{Time.now.to_s(:db)}"
  #                        }
  #         end
  #     end
  #   end
  #   return image_array
  # end

  def init_product_attributes(s_product_id,is_import)
    #hall_id :1 --> type :1
    #        :47         :2
    #        :48         :5
    s_product=SProduct.find(s_product_id)
    product_hash=Hash.new
    if is_import
      product_type= 1 if s_product.hall_id== 1   #cell phone
      product_type= 2 if s_product.hall_id== 47  #pad
      product_type= 5 if s_product.hall_id== 48  #wearable
      
      market_date =(s_product.market_date_desc.present?)? s_product.market_date_desc : s_product.market_date 
 
      product_hash = {
        :product_id => s_product.id,
        :name => (s_product.name_local.present?)? s_product.name_local : s_product.name_normal, 
        :product_type => product_type,
        :info => s_product.intro_detail, 
        :market_date => market_date,
        :brand_id => s_product.brand_id,
        :status => 1
      }
    else
      product_hash = {
        :name => (s_product.name_local.present?)? s_product.name_local : s_product.name_normal, 
        :info => s_product.intro_detail, 
        :brand_id => s_product.brand_id,
        :is_info_trans => 1,
      }
    end
    return product_hash
  end

  def feature_create(fet_id)
    product_id=fet_id
    specs=ProductSpecDisplay.where(:product_id => product_id).map { |s| s.name }.join(",")
    #:feature1 =>  雙核處理器   :feature2 =>  3.5G   :feature3 =>  WiFi   :feature4 =>  GPS  :feature5 =>  FM Radio    
    #:feature6 =>  MP3        :feature7 =>  HDMI  :feature8 =>  FULL HD  :feature9 =>  NFC  :feature10 => 雙鏡頭
    #1=>iOS   2=>Android    3=>Symbian    4=>Windows Phone    5=>Windows Mobile
    feature_list={  :feature => [ I18n.t("activerecord.feature.feature1"),
                                  "[Hh][Ss][DdUu][Pp][Aa]","[Ww]i(.*)[Ff]i","[Gg][Pp][Ss]","[Ff][Mm]",
                                  "[Mm][Pm]3","[Hh][Dd][Mm][Ii]","[Ff][Uu][lL]{2}\s[Hh][Dd]","[Nn][Ff][Cc]",
                                  I18n.t("activerecord.feature.feature10"),"[eE][aA][pP]-[Ss][Ii][Mm]","[lL][tT][eE]"] , 
                    :os => ["iOS","Android","Symbian","Windows Phone","Windows Mobile","Windows 8"]
                  }

    features=Hash.new
    features[:product_id]=product_id;
    feature_list.keys.each_with_index do |list,i|
      feature_list[list].each_with_index do |pattern,feature|
        if i==0
          if feature != 10
            features["features#{feature+1}".to_sym]=(specs[/#{pattern}/])? true : false
          else
            features["features#{feature+1}".to_sym]=false
          end
        end
        if i==1
          features[:os] = feature+1 if specs[/#{pattern}/]
          features[:os] = 5 if features[:os].to_i > 5
        end
      end
    end

    features[:os] = 2 if features[:os].blank?
    feature_record=Feature.find_or_initialize_by_product_id(product_id)
    feature_record.attributes=features
    feature_record.save!
  end

  protected
  ## 系統轉換時使用的程式
  # def init_fet_and_sogi_field_list
  #   @sogi_fields={
  #     :SSpec => ['id','name_local','spec_class_id','sort'],
  #     :SSpecClass => ['name_local','sort','id','hall_id'],
  #     :MsSpec => ['s_no','s_name','s_name_eng','sc_no','s_sort','s_remark'],
  #     :MsSpecClass => ['sc_name','sc_sort','sc_name_eng','sc_no','c_no'],
  #     :MsProduct => ['id','p_no','p_name','p_info','p_type','b_no','p_reviews',
  #                   'p_mdate','p_status','p_isInfoTrans','p_isSpecTrans','p_isPicTrans'],
  #     :MsFeature => ['p_no','os','features1','features2','features3','features4','features5',
  #                   'features6','features7','features8','features9','features10'],
  #     :MsProductSpecDisplay => ['p_no','sv_name','s_no'],
  #   }
  #   @fet_fields={
  #     :ms => {
  #       :Spec => ['spec_id','name','name_en','spec_class_id','sort','remark'],
  #       :SpecClass => ['name','sort','name_en','spec_class_id','hall_id'],        
  #        },
  #     :sogi => {
  #       :Spec => ['spec_id','name','spec_class_id','sort'],
  #       :SpecClass => ['name','sort','spec_class_id','hall_id'],        
  #        },
  #     :Product => ['id','product_id','name','info','product_type','brand_id','reviews','market_date','status','is_info_trans','is_spec_trans','is_pic_trans'],
  #     :Feature => ['product_id','os','features1','features2','features3','features4','features5','features6','features7','features8','features9','features10'],
  #     :ProductSpecDisplay => ['product_id','name','spec_id']
  #   }  
  # end

  def init_product_ids
    @product_ids=params[:product_id].split(".")
  end

  def init_s3_connection
    # read YAML file
    @aws = YAML.load_file("config/aws.yml")[Rails.env]

    # AWS-SDK : Get an instance of the S3 interface.
    s3 = AWS::S3.new(
      :access_key_id => @aws[:access_key_id], 
      :secret_access_key => @aws[:secret_access_key]
    )

    #@bucket=s3.buckets[@aws[:s3_bucket_name]]
    @bucket=s3.buckets['sogi-attach']

  end
end

