class UiIndexs::FeaturesController < ApplicationController
  before_filter :init_feature
  def create
    specs=ProductSpecDisplay.where(:product_id => params[:id]).map { |s| s.name }.join(",")
    #:feature1 =>  雙核處理器   :feature2 =>  3.5G   :feature3 =>  WiFi   :feature4 =>  GPS  :feature5 =>  FM Radio    
    #:feature6 =>  MP3        :feature7 =>  HDMI  :feature8 =>  FULL HD  :feature9 =>  NFC  :feature10 => 雙鏡頭
    #:feature11 =>  EAP-SIM        :feature12 =>  4G
    #1=>iOS   2=>Android    3=>Symbian    4=>Windows Phone    5=>Windows Mobile
    feature_list={  :feature => [ I18n.t("activerecord.feature.feature1"),
                                  "[Hh][Ss][DdUu][Pp][Aa]","[Ww]i(.*)[Ff]i","[Gg][Pp][Ss]","[Ff][Mm]",
                                  "[Mm][Pm]3","[Hh][Dd][Mm][Ii]","[Ff][Uu][lL]{2}\s[Hh][Dd]","[Nn][Ff][Cc]",
                                  I18n.t("activerecord.feature.feature10"),"[eE][aA][pP]-[Ss][Ii][Mm]","[lL][tT][eE]"] , 
                    :os => ["iOS","Android","Symbian","Windows Phone","Windows Mobile"]
                  }

    features=Hash.new
    features[:product_id]=params[:id];
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
    Feature.create(features)
    redirect_to edit_ui_indexs_feature_path(params[:id])
  end

  def edit
    create if @feature.blank?
    @product=Product.find_by_product_id(params[:id]) || Product.find_by_id(params[:id])
  end
  def update
    @feature.update_attributes!(params[:feature])
    redirect_to edit_ui_indexs_feature_path(params[:id])
  end
  protected
  def init_feature
    @feature=Feature.find_by_product_id(params[:id])
  end
end
