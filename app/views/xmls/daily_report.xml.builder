xml = Builder::XmlMarkup.new(:indent => 2)
xml.instruct!
xml.device{
  xml.producer("sogi")
  xml.comment! "固定為sogi"
  xml.receiver("FET_sidelist")
    xml.comment! "固定為 FET_sidelist "
    xml.xmldate("#{@today.to_formatted_s(:db)}")
    xml.comment! "(required):取得XML資料日期"
    xml.startdate("#{@today.ago(86400).to_formatted_s(:db)}")
    xml.comment! "(required):查詢起始日期(含當日)"
    xml.enddate("#{@today.to_formatted_s(:db)}")
    xml.comment! "(required):查詢結束日期(含當日)"
    xml.items{
      @products.each do |product|
        xml.item("type"=>"#{product.product_type}"){
        xml.comment! "type=1(手機),2(平板),3(筆電),4(網卡)" 
        xml.guid("#{product.id}")
        xml.url("http://fet.sogi.com.tw/fet_xml/#{product.id}.xml")
        }
      end
    }
  }

path=Rails.root.join("public", "fet_xml")
extension="FET_List#{Date.today.to_formatted_s(:number)}.xml"
XmlsController::create_and_write_file(path,extension,xml.target!)