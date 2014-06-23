# encoding: utf-8
class XmlsController < ApplicationController
  before_filter :init_s3_connection , :only=>[:import_pic,:update_pic]
  respond_to :xml
  def index
    @products=Product.where("DATEDIFF(updated_at, ADDTIME(NOW(),'08:00:00'))=-1").order("id desc")
    @today=Time.now

    respond_to do |format|
      format.xml { render :action => "daily_report.xml.builder"}
    end
    daily_product_detail
  end

  def daily_product_detail
    @products.each do |product|
      brand_list = create_brand_list(product.product_type)
      feature = Feature.where(:product_id=>product.id).first       
      product_image=ProductImage.where(:imageable_id => product.id)


      path=Rails.root.join("public", "fet_xml") 
      extension="#{product.id}.xml"

      @display_array=Array.new
      SpecClass.includes(:product_spec_displays).where("product_spec_displays.product_id = ?",product.id).each do |spec_class|
        spec_class.product_spec_displays.each do |d|
          @display_array << { 
              :spec_id => d.spec.spec_id,
              :spec_name=>d.spec.name,
              :spec_class_name=>spec_class.name,
              :spec_name_en=>d.spec.name_en,
              :display_name=>d.name
            } 
        end
      end

      # establish xml
      xml = Builder::XmlMarkup.new(:indent => 2)
      xml.instruct!
      xml.device("xmlns:xsi"=>"http://www.w3.org/2001/XMLSchema-instance"){
        xml.producer(to_cdata("sogi"))
        xml.comment! "固定為sogi"
        xml.receiver(to_cdata('FET_sidelist'))
        xml.comment! " 固定為 FET_sidelist "
        xml.updatedate(to_cdata("#{product.updated_at.strftime('%Y-%m-%dT%H:%M:%S')}"))
        xml.comment! "手機王更新日期"
        market_date = product.market_date.sub!("年","-") if product.market_date.present?
        market_date = market_date.sub!("月","-") if market_date.present?
        market_date << "01" if market_date.present?
        if market_date.blank?
          xml.releasedate("xsi:nil"=>market_date.blank?)
        else
          xml.releasedate(to_cdata("#{market_date.to_date.to_s}"),"xsi:nil"=>market_date.blank?)       
        end

        xml.comment! "產品上市日期"
        device_type = String.new()
        case product.product_type
          when 1
            device_type = "handset"
          when 2
            device_type = "pad"
          when 3
            device_type = "notebook"
          when 4
            device_type = "networkcard"
          else
            device_type="--"   
        end
        xml.device_type(to_cdata("#{device_type}"))
        xml.brand(to_cdata("#{brand_list[product.brand_id]}"))
        xml.comment! "brand"
        xml.pname(to_cdata("#{product.name}"))
        xml.comment! "型號"
        xml.guid(to_cdata("#{product.id}"))
        xml.comment! "編號(unique key)"
        if product.product_type == 1
          xml.smartPhone(to_cdata("#{(@display_array.select{|hash| hash[:spec_id] == 9 }.present?)? 1 : 0}"))
          xml.comment! "是否為智慧型手機"
        end
        if product.main_image.present? and product.main_image.url_big.present?
          xml.mainimage360(to_cdata(URI.decode(product.main_image.url_big))) 
          xml.comment! "手機圖片連結 360*360" 
          xml.mainimage250(to_cdata(URI.decode(product.main_image.url_medium))) 
          xml.comment! "手機圖片連結 250*250"
          xml.mainimage160(to_cdata(URI.decode(product.main_image.url_small)))
          xml.comment! "手機圖片連結 160*160"
          xml.mainimage100(to_cdata(URI.decode(product.main_image.url_thumb)))
          xml.comment! "手機圖片連結 100*100"
        else
          xml.mainimage360(to_cdata('--')) 
          xml.comment! "手機圖片連結 360*360" 
          xml.mainimage250(to_cdata('--')) 
          xml.comment! "手機圖片連結 250*250"
          xml.mainimage160(to_cdata('--')) 
          xml.comment! "手機圖片連結 160*160"
          xml.mainimage100(to_cdata('--')) 
          xml.comment! "手機圖片連結 100*100"          
        end      
        xml.images{
          xml.comment! "(官圖)寫真圖連結"  
          official_image=product.big_official_image
          if official_image.present?
            xml.image100{
              xml.comment! "寫真圖連結 100*75"
              official_image.each do |image|
                xml.image(to_cdata(URI.decode(image.url_thumb)))
              end
            }
            xml.image600{
              xml.comment! "寫真圖連結 640*480"
              official_image.each do |image|
                xml.image(to_cdata(URI.decode(image.url_big))) 
              end
            }
          end
        }
        xml.studioShoot{
          xml.comment! "(棚拍圖)寫真圖連結"
          picture=product.picture
          if picture.present?
            picture.each do |image|
              xml.image(to_cdata("#{URI.decode(image.url_big)}")) 
            end
          end
        }
        xml.introduction(to_cdata("#{URI.decode(product.info.gsub("+", "＋").gsub("%", "％").gsub("&deg;", "°").gsub("&nbsp;", " "))}"))
        xml.comment! "介紹"
        xml.spec{
          # 手機用
          if product.product_type == 1
            xml.BasicInformation{
              xml.Frequency(to_cdata(find_display_name_by_value("基本資訊","頻率系統")))
              xml.CameraPixel(to_cdata(find_display_name_by_value("基本資訊","內建相機畫素")))
              xml.CameraFunctions(to_cdata(find_display_name_by_value("基本資訊","相機功能"))) 
              xml.RingtonesType(to_cdata(find_display_name_by_value("基本資訊","鈴聲種類")))   
              xml.ROM(to_cdata(find_display_name_by_value("基本資訊","內建記憶體(ROM)")))
              xml.Bluetooth(to_cdata(find_display_name_by_value("基本資訊","藍牙版本"))) 
              xml.RAM(to_cdata(find_display_name_by_value("基本資訊","RAM記憶體")))
              xml.MusicPlayer(to_cdata(find_display_name_by_value("基本資訊","音樂播放器")))
              xml.Platform(to_cdata(find_display_name_by_value("基本資訊","作業系統(平台)")))
              xml.Transmission(to_cdata(find_display_name_by_value("基本資訊","傳輸介面")))
              xml.CPU(to_cdata(find_display_name_by_value("基本資訊","處理器"))) 
              xml.CPUcore(to_cdata(find_display_name_by_value("基本資訊","處理器分類")))
              xml.MemoryCard(to_cdata(find_display_name_by_value("基本資訊","記憶卡插槽"))) 
            }
            xml.VideoInformation{
              xml.Sensor(to_cdata(find_display_name_by_value("影音資訊","感光元件")))
              xml.VideoFormat(to_cdata(find_display_name_by_value("影音資訊","錄影格式")))
              xml.ImageSupport(to_cdata(find_display_name_by_value("影音資訊","圖片支援格式"))) 
              xml.VideoSupport(to_cdata(find_display_name_by_value("影音資訊","影片播放格式"))) 
              xml.Polyphonic(to_cdata(find_display_name_by_value("影音資訊","和弦鈴聲")))   
              xml.VideoLens(to_cdata(find_display_name_by_value("影音資訊","視訊鏡頭(3G)")))
            }
            xml.ScreenInformation{
              xml.ScreenMaterial(to_cdata(find_display_name_by_value("螢幕資訊","外螢幕材質"))) #ASK
              xml.ScreenColor(to_cdata(find_display_name_by_value("螢幕資訊","外螢幕色彩"))) #ASK
              xml.ScreenSize(to_cdata(find_display_name_by_value("螢幕資訊","外螢幕尺寸")))
              xml.ScreenResolution(to_cdata(find_display_name_by_value("螢幕資訊","外螢幕解析度")))
            }
            xml.NetworkInformation{
              xml.E_mail(to_cdata(find_display_name_by_value("網路資訊","E-mail格式"))) 
              xml.Newsletter(to_cdata(find_display_name_by_value("網路資訊","簡訊格式")))
              xml.Network(to_cdata(find_display_name_by_value("網路資訊","上網方式")))
            }
            xml.BuiltinInformation{
              xml.OfficeDocs(to_cdata(find_display_name_by_value("內建資訊","Office文件"))) 
              xml.InputMethod(to_cdata(find_display_name_by_value("內建資訊","輸入法"))) #ASK
              xml.Tools(to_cdata(find_display_name_by_value("內建資訊","實用工具")))
              xml.Advanced(to_cdata(find_display_name_by_value("內建資訊","進階功能")))
            }
            xml.DeviceInformation{
              xml.DeviceLength(to_cdata(find_display_name_by_value("機身資訊","機身長度")))
              xml.DeviceWidgh(to_cdata(find_display_name_by_value("機身資訊","機身寬度")))
              xml.DeviceThick(to_cdata(find_display_name_by_value("機身資訊","機身厚度")))
              xml.DeviceWeight(to_cdata(find_display_name_by_value("機身資訊","機身重量")))
              xml.TalkTime(to_cdata(find_display_name_by_value("機身資訊","通話時間(最大)")))
              xml.StandbyTime(to_cdata(find_display_name_by_value("機身資訊","待機時間(最大)")))
              xml.Battery(to_cdata(find_display_name_by_value("機身資訊","電池容量")))
              xml.Interface(to_cdata(find_display_name_by_value("機身資訊","操作介面")))
              xml.DeviceColor(to_cdata(find_display_name_by_value("機身資訊","機身顏色")))
              xml.DeviceDesign(to_cdata(find_display_name_by_value("機身資訊","機身設計")))
              xml.AddedServices(to_cdata(find_display_name_by_value("機身資訊","7"))) #ASK
            } 
            xml.OtherInformation{
              xml.other1{
                msg=String.new
                if File.exist?("#{path}/#{extension}")
                  if product.is_info_trans
                    msg << "[Device 資訊內容包含 :評測文章或棚拍圖],"
                  end
                  if product.is_spec_trans
                    msg << "[規格內容包含: 基本規格, 詳細規格],"
                  end
                  if product.is_pic_trans
                    msg << "[內容包含: 名稱、介紹、產品圖、寫真圖、官圖]"
                  end
                  if msg.blank?
                    msg << "新增"
                  end
                else
                  msg << "新增"
                end
                xml.name(to_cdata(msg))
                xml.value(to_cdata("--"))
              }
              xml.other2{
                xml.name(to_cdata(find_display_name_by_value("基本資訊","FDD-LTE Band")))
                xml.value(to_cdata("--"))
              }          
              xml.other3{
                xml.name(to_cdata(find_display_name_by_value("基本資訊","TDD-LTE Band")))
                xml.value(to_cdata("--"))
              }
              xml.other4{
                xml.name(to_cdata("--"))
                xml.value(to_cdata("--"))
              }
              xml.other5{
                xml.name(to_cdata("--"))
                xml.value(to_cdata("--"))
              }
            }
          end

          # 平板用
          if product.product_type == 2 

            xml.Color(to_cdata(find_display_name_by_value("規格項目","顏色")))
            xml.KeyFeatures(to_cdata(find_display_name_by_value("規格項目","產品特色")))
            xml.Monitor(to_cdata(find_display_name_by_value("規格項目","規格(LCD螢幕(解析度)")))
            xml.CPU(to_cdata(find_display_name_by_value("規格項目","CPU 處理器/時脈")))
            xml.CPUcore(to_cdata(find_display_name_by_value("規格項目","處理器分類")))
            xml.OS(to_cdata(find_display_name_by_value("規格項目","作業系統")))

            xml.RAM(to_cdata(find_display_name_by_value("規格項目","記憶體")))
            xml.Storage(to_cdata(find_display_name_by_value("規格項目","儲存設備")))
            xml.MemoryCard(to_cdata(find_display_name_by_value("規格項目","支援記憶卡(最高容量)")))
            xml.Camera(to_cdata(find_display_name_by_value("規格項目","照相機/攝影機")))
            xml.Frequency_3G(to_cdata(find_display_name_by_value("規格項目","3G模組")))
            xml.WiFi(to_cdata(find_display_name_by_value("規格項目","Wi-Fi 無線網路")))
            xml.MultiTouch(to_cdata(find_display_name_by_value("規格項目","多點觸控")))

            xml.CardReader(to_cdata(find_display_name_by_value("規格項目","讀卡機")))
            xml.IO(to_cdata(find_display_name_by_value("規格項目","輸出/輸入裝置")))
            xml.Audio(to_cdata(find_display_name_by_value("規格項目","立體聲喇叭")))
            xml.Microphone(to_cdata(find_display_name_by_value("規格項目","麥克風輸入")))
            xml.Headphone(to_cdata(find_display_name_by_value("規格項目","耳機輸出")))

            xml.Dimensions(to_cdata(find_display_name_by_value("規格項目","尺寸(mm)")))
            xml.Weight(to_cdata(find_display_name_by_value("規格項目","重量(g)")))
            xml.Battery(to_cdata(find_display_name_by_value("規格項目","電池")))
            xml.BatteryLife(to_cdata(find_display_name_by_value("規格項目","電池使用時間")))
            xml.Accessories(to_cdata(find_display_name_by_value("規格項目","標準配件")))
            xml.Office(to_cdata(find_display_name_by_value("規格項目","內建Office軟體")))
            xml.Flash(to_cdata(find_display_name_by_value("規格項目","支援 Flash 播放")))

            xml.GPS(to_cdata(find_display_name_by_value("規格項目","GPS衛星定位")))
            xml.Community(to_cdata(find_display_name_by_value("規格項目","內建社群服務")))
            xml.Other(to_cdata(find_display_name_by_value("規格項目","其它特色")))
            xml.Warranty(to_cdata(find_display_name_by_value("規格項目","保固")))
            xml.Support(to_cdata(find_display_name_by_value("規格項目","技術支援專線")))


            xml.OtherInformation{
              xml.other1{
                msg=String.new
                if File.exist?("#{path}/#{extension}")
                  if product.is_info_trans
                    msg << "[Device 資訊內容包含 :評測文章或棚拍圖],"
                  end
                  if product.is_spec_trans
                    msg << "[規格內容包含: 基本規格, 詳細規格],"
                  end
                  if product.is_pic_trans
                    msg << "[內容包含: 名稱、介紹、產品圖、寫真圖、官圖]"
                  end
                  if msg.blank?
                    msg << "新增"
                  end
                else
                  msg << "新增"
                end
                xml.name(to_cdata(msg))
                xml.value(to_cdata("--"))
              }
              xml.other2{
                xml.name(to_cdata(find_display_name_by_value("規格項目","FDD-LTE Band")))
                xml.value(to_cdata("--"))
              }          
              xml.other3{
                xml.name(to_cdata(find_display_name_by_value("規格項目","TDD-LTE Band")))
                xml.value(to_cdata("--"))
              }
              xml.other4{
                xml.name(to_cdata("--"))
                xml.value(to_cdata("--"))
              }
              xml.other5{
                xml.name(to_cdata("--"))
                xml.value(to_cdata("--"))
              }
            }
          end

          #筆電用
          if product.product_type == 3 
            xml.Color(to_cdata(find_display_name_by_value("規格項目","顏色")))
            xml.Monitor(to_cdata(find_display_name_by_value("規格項目","LCD螢幕(解析度)")))
            xml.CPU(to_cdata(find_display_name_by_value("規格項目","CPU 處理器/時脈")))
            xml.CPUcore(to_cdata(find_display_name_by_value("規格項目","處理器分類")))
            xml.OS(to_cdata(find_display_name_by_value("規格項目","作業系統")))

            xml.GraphicCard(to_cdata(find_display_name_by_value("規格項目","獨立顯示晶片")))
            xml.RAM(to_cdata(find_display_name_by_value("規格項目","記憶體")))
            xml.Storage(to_cdata(find_display_name_by_value("規格項目","儲存設備")))
            xml.OpticalMediaDrive(to_cdata(find_display_name_by_value("規格項目","ODD光碟機")))
            xml.WebCam(to_cdata(find_display_name_by_value("規格項目","網路攝影機")))
            xml.TouchDevice(to_cdata(find_display_name_by_value("規格項目","指向裝置")))

            xml.USB(to_cdata(find_display_name_by_value("規格項目","USB連接埠")))
            xml.LAN(to_cdata(find_display_name_by_value("規格項目","區域網路")))
            xml.WLAN(to_cdata(find_display_name_by_value("規格項目","無線網路")))
            xml.Bluetooth(to_cdata(find_display_name_by_value("規格項目","內建藍芽")))
            xml.CardReader(to_cdata(find_display_name_by_value("規格項目","讀卡機")))

            xml.IO(to_cdata(find_display_name_by_value("規格項目","輸出/輸入裝置")))
            xml.Audio(to_cdata(find_display_name_by_value("規格項目","音效")))
            xml.Software(to_cdata(find_display_name_by_value("規格項目","軟體")))
            xml.Dimensions(to_cdata(find_display_name_by_value("規格項目","尺寸(mm)")))
            xml.Weight(to_cdata(find_display_name_by_value("規格項目","重量(g)")))

            xml.Battery(to_cdata(find_display_name_by_value("規格項目","電池")))
            xml.BatteryLife(to_cdata(find_display_name_by_value("規格項目","電池使用時間")))
            xml.Accessories(to_cdata(find_display_name_by_value("規格項目","標準配件")))
            xml.Warranty(to_cdata(find_display_name_by_value("規格項目","保固")))
            xml.KeyFeatures(to_cdata(find_display_name_by_value("規格項目","產品特色")))
            xml.Support(to_cdata(find_display_name_by_value("規格項目","技術支援專線")))
         
            xml.OtherInformation{
              xml.other1{
                msg=String.new
                if File.exist?("#{path}/#{extension}")
                  if product.is_info_trans
                    msg << "[Device 資訊內容包含 :評測文章或棚拍圖],"
                  end
                  if product.is_spec_trans
                    msg << "[規格內容包含: 基本規格, 詳細規格],"
                  end
                  if product.is_pic_trans
                    msg << "[內容包含: 名稱、介紹、產品圖、寫真圖、官圖]"
                  end
                  if msg.blank?
                    msg << "新增"
                  end
                else
                  msg << "新增"
                end
                xml.name(to_cdata(msg))
                xml.value(to_cdata("--"))
              }
              xml.other2{
                xml.name(to_cdata(find_display_name_by_value("規格項目","FDD-LTE Band")))
                xml.value(to_cdata("--"))
              }          
              xml.other3{
                xml.name(to_cdata(find_display_name_by_value("規格項目","TDD-LTE Band")))
                xml.value(to_cdata("--"))
              }
              xml.other4{
                xml.name(to_cdata("--"))
                xml.value(to_cdata("--"))
              }
              xml.other5{
                xml.name(to_cdata("--"))
                xml.value(to_cdata("--"))
              }
            }
          end
          
          # 網卡用
          if product.product_type == 4 
            xml.Color(to_cdata(find_display_name_by_value("規格項目","顏色")))
            xml.Frequence(to_cdata(find_display_name_by_value("規格項目","頻率")))
            xml.Speed(to_cdata(find_display_name_by_value("規格項目","網卡速度")))
            xml.OS(to_cdata(find_display_name_by_value("規格項目","支援作業系統")))
            xml.Connectivity(to_cdata(find_display_name_by_value("規格項目","介面")))

            xml.Dimensions(to_cdata(find_display_name_by_value("規格項目","尺寸(mm)")))
            xml.Weight(to_cdata(find_display_name_by_value("規格項目","重量(g)")))
            xml.Other(to_cdata(find_display_name_by_value("規格項目","其他功能")))
            xml.Accessories(to_cdata(find_display_name_by_value("規格項目","標準配件")))
            xml.Warranty(to_cdata(find_display_name_by_value("規格項目","保固")))
            xml.KeyFeatures(to_cdata(find_display_name_by_value("規格項目","產品特色")))
            
            xml.Support(to_cdata(find_display_name_by_value("規格項目","技術支援專線")))
            
            xml.OtherInformation{
              xml.other1{
                msg=String.new
                if File.exist?("#{path}/#{extension}")
                  if product.is_info_trans
                    msg << "[Device 資訊內容包含 :評測文章或棚拍圖],"
                  end
                  if product.is_spec_trans
                    msg << "[規格內容包含: 基本規格, 詳細規格],"
                  end
                  if product.is_pic_trans
                    msg << "[內容包含: 名稱、介紹、產品圖、寫真圖、官圖]"
                  end
                  if msg.blank?
                    msg << "新增"
                  end
                else
                  msg << "新增"
                end
                xml.name(to_cdata(msg))
                xml.value(to_cdata("--"))
              }
              xml.other2{
                xml.name(to_cdata(find_display_name_by_value("規格項目","FDD-LTE Band")))
                xml.value(to_cdata("--"))
              }          
              xml.other3{
                xml.name(to_cdata(find_display_name_by_value("規格項目","TDD-LTE Band")))
                xml.value(to_cdata("--"))
              }
              xml.other4{
                xml.name(to_cdata("--"))
                xml.value(to_cdata("--"))
              }
              xml.other5{
                xml.name(to_cdata("--"))
                xml.value(to_cdata("--"))
              }
            }
          end

          # 穿戴裝置用
          # if product.product_type == 5 
            #程式邏輯
          # end
        }
        Product.record_timestamps = false
        begin
          product.update_attributes(:is_pic_trans=>0,:is_spec_trans=>0,:is_info_trans=>0)
        ensure
          Product.record_timestamps = true  # don't forget to enable it again!
        end
        xml.features{
          if product.product_type <= 2  and feature.present?
            xml.os(to_cdata("#{feature.os}"))
            xml.feature1(to_cdata("#{(feature.features1)? 1 : 0}"))
            xml.feature2(to_cdata("#{(feature.features2)? 1 : 0}"))
            xml.feature3(to_cdata("#{(feature.features3)? 1 : 0}"))
            xml.feature4(to_cdata("#{(feature.features4)? 1 : 0}"))
            xml.feature5(to_cdata("#{(feature.features5)? 1 : 0}"))
            xml.feature6(to_cdata("#{(feature.features6)? 1 : 0}"))
            xml.feature7(to_cdata("#{(feature.features7)? 1 : 0}"))
            xml.feature8(to_cdata("#{(feature.features8)? 1 : 0}"))
            xml.feature9(to_cdata("#{(feature.features9)? 1 : 0}"))
            xml.feature10(to_cdata("#{(feature.features10)? 1 : 0}"))
            xml.feature11(to_cdata("#{(feature.features11)? 1 : 0}"))
            xml.feature12(to_cdata("#{(feature.features12)? 1 : 0}"))
            xml.feature13(to_cdata("0"))
            xml.feature14(to_cdata("0"))
            xml.feature15(to_cdata("0"))
            xml.feature16(to_cdata("0"))
            xml.feature17(to_cdata("0"))
          end
        }

        reviews = Array.new
        reviews = product.reviews.split(",") if product.reviews.present?
        if reviews.count > 0
          gem_article = String.new
          if product.product_type < 3
            gem_article=SGemArticle.where(:article_id => reviews.first).select("title,intro").first
          else
            gem_article=TwGemArticle.where(:id => reviews.first).first
          end
          if gem_article.present?
            xml.content{
              #檢查有沒有文章標題
              title = (gem_article.blank?)? "--" : gem_article.title
              #檢查有沒有自訂標題
              title = product.title if product.title.present?

              xml.title(to_cdata(title))
              xml.comment! "文章標題"

              #文章編號以第一篇文章為準
              xml.guid(to_cdata(reviews.first))
              xml.comment! "文章編號(unique key)"
            

              content = String.new
              reviews.each do |review|
                if product.product_type < 3
                  article_content = SArticleContent.where(:article_id => review).select(:content).first.content
                else
                  article_content = TwArticleContent.where(:article_id => review).select(:content).first.content
                end

                if content.blank?
                  #第一篇文章 => 保存全文
                  content = article_content
                else
                  #其他文章 => 先刪除第一張圖片前的內容再合併
                  content << article_content.gsub!(article_content[/(.*\n){2}<img alt=.+?>/],"")
                end
              end
              # scan可以搜尋所有條件
              # 為了篩選出網址，所以((http|https):\/\/.+?(jpg|jpeg))多加上一個括號
              # 一個括號會有一個結果
              urls=content.scan(/<img.+?src=(\'|\")((http|https):\/\/.+?(JPG|jpeg|jpg|png))(\'|\")/)
              xml.images{
                urls.each_with_index do |url,index|
                  xml.image("","id" => "image#{index+1}" , "value"=>"#{url[1]}")
                  content=content.gsub(/#{url[1]}/,"{image#{index+1}}")
                end
              }
              xml.abstract(to_cdata("#{(gem_article.blank?)? "" : gem_article.intro}")) if product.product_type <=2
              xml.abstract(to_cdata("#{content[0..255]}")) if product.product_type >=3
              xml.comment! "前言"
              # 這裡fetch的文章內容已經先編譯過了，需要先處理文章的內容
              # 若沒先處理 則會出現 『&deg;』再編譯成『&amp;deg;』
              xml.body(to_cdata("#{content.gsub("&deg;", "°").gsub("&nbsp;", " ")}"))
              xml.comment! "內文"
            }
          end
        end
      }
      XmlsController::create_and_write_file(path,extension,xml.target!)
    end
  end

  def self.create_and_write_file(path,extension,content)
    unless File.directory?(path)
      FileUtils.mkdir_p(path)
    end

    file = File.new("#{path}/#{extension}", "w")
    #處理整份XML的內容
    content = content.gsub(/（點圖可放大看原圖）/,"")
    content = content.gsub(/（點圖可放大）/,"")
    content = content.gsub(/（點擊可查看大圖）/,"")
    content = content.gsub(/手機王網站/,"")
    content = content.gsub(/<strong>(<br.+?|)延伸閱讀.*/,"")
    content = content.gsub("cf-attach.i-sogi.com", "cf-attach.s3.amazonaws.com")
    content = content.gsub("attach.sogi.com.tw","sogi-attach.s3.amazonaws.com")
    content = content.gsub("&lt;", "<")
    content = content.gsub("&gt;", ">")
    # content = content.gsub("%", "%25")
    content = content.gsub("\n", "")
    content = content.gsub("<E_mail>","<E-mail>").gsub("</E_mail>","</E-mail>")
    #content = content.gsub("FDDQQLTEQQBand","FDD-LTE Band") ####
    content = content.gsub("sogi-image.sogi.com.tw","sogi-attach-ruby.s3.amazonaws.com")
    content = content.gsub("+", "＋").gsub("%", "％").gsub("&deg;", "°").gsub("&nbsp;", " ")
    # XML取代半形%為全形%後，會連帶影響連結
    # 這裡將連結還原
    # scan => 找出所有連結
    content.scan(/(www.(youtube|sogi).com.+?(\'|\"))/).uniq.each do |url|
      content = content.gsub(url[0],content[url[0]].gsub("％","%"))
    end
    file.write(content)
    file.close
  end

  private


  def find_display_name_by_value(spec_class_name_condition,spec_name_condition)
    selects = @display_array.select{|k| k[:spec_class_name]==spec_class_name_condition and  k[:spec_name]==spec_name_condition }
    value="--"
    value = selects.last[:display_name] if selects.last.present?
    return value
  end  

  def to_cdata(string)
    xml = Builder::XmlMarkup.new(:indent => 2)
    str=String.new
    if string.present?
      str=string
      str="" if string=="market_date"
    else
      str="--"
    end
    return xml.cdata!("#{str}")
  end

  def create_brand_list(product_type)
    @brand_list=Hash.new()
    case product_type.to_i
      when 3
        @brand_list=@brand_list.merge({
                  "Acer"=>1,"Sony"=>26,"BenQ"=>31,"TOSHIBA"=>42,
                  "ASUS"=>49,"HP"=>105,"Apple"=>116,"Lenovo"=>130,
                  "Fujitsu"=>1529,"MSI"=>1819,"DELL"=>1828,"KJS"=>208
                })
      when 4
        i18n= I18n.t("activerecord.NIC_brand") 
        i18n.each_with_index do |str,i|
          @brand_list =  @brand_list.merge({str.last => i})
        end
      else
        SBrand.select("id,name_normal").each do |b|
          case b.id
            when 5368
              @brand_list=@brand_list.merge({"Xiaomi" => b.id})
            when 4140
              @brand_list=@brand_list.merge({"FarEastone" => b.id})
            else
              @brand_list=@brand_list.merge({b.name_normal => b.id})
          end

          # if b.id == 5368
          #   @brand_list=@brand_list.merge({"Xiaomi" => b.id})
          # else
          #   @brand_list=@brand_list.merge({b.name_normal => b.id})
          # end
        end
    end
    return @brand_list.invert
  end

  protected
  def init_s3_connection
    # read YAML file
    @aws = YAML.load_file("config/aws.yml")[Rails.env]

    # fog : establish connection 
    # @connection = Fog::Storage.new(
    #   provider: 'AWS',
    #   aws_access_key_id: @aws["access_key_id"],
    #   aws_secret_access_key: @aws["secret_access_key"]
    # )
    
    # AWS-SDK : Get an instance of the S3 interface.
    s3 = AWS::S3.new(
      :access_key_id => @aws["access_key_id"], 
      :secret_access_key => @aws["secret_access_key"]
    )

    @bucket=s3.buckets[@aws["s3_bucket_name"]]
  end
end
