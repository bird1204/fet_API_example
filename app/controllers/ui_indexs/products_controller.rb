class UiIndexs::ProductsController < ApplicationController
  before_filter :init_product,:only=>[:edit,:update]

  def index
    redirect_to search_ui_indexs_products_path(:product_type => 0)
  end

  def new
    @product=Product.new
    @product_type=(params[:commit][/NB/])? 3 : 4
    @brand_list=create_brand_list(@product_type)
  end

  def create
    params[:product][:product_type]=params[:product_type]    
    new_product=Product.new(params[:product])
    new_product.product_id=0 if params[:product][:product_type].to_i > 2
    new_product.save!

    if new_product.product_id==0
      spec_class_id = (params[:product][:product_type].to_i == 3)? 9 : 10
      Spec.where(:spec_class_id => spec_class_id).each do |spec_display|
        ProductSpecDisplay.create(:spec_id => spec_display.spec_id,:product_id => new_product.id)
      end
      Feature.create(:product_id => new_product.id)
      ProductImage.create(:categorized => 1,:imageable_id => new_product.id,:imageable_type=>"Product")
    end
    redirect_to search_ui_indexs_products_path(:product_type => params[:product_type])
  end
  
  def edit
    if @product.product_type > 2
      @brand_list=create_brand_list(@product.product_type) 
    else
      s_brand=SBrand.select("id,name_normal").find_by_id(@product.brand_id)
      if s_brand.id == 5368
        @brand_list={"Xiaomi" => s_brand.id}
      else
        @brand_list={s_brand.name_normal => s_brand.id}
      end
    end
  end

  def put_in_next_XML
    product=Product.find(params[:product_id])
    product.touch
    redirect_to search_ui_indexs_products_path(:product_type => product.product_type)
  end

  def update
    # 更新評測文章 -> :is_info_trans=>true && only update reviews
    # 保存 -> :is_info_trans=>true 




    if params[:commit].present?
      @product.update_attributes(params[:product],:is_info_trans => true)
      redirect_to search_ui_indexs_products_path(:product_type => @product.product_type)
    else
      @product.update_attributes(:reviews=>params[:product][:reviews],:is_info_trans => true)
      redirect_to edit_ui_indexs_product_path(params[:id])
    end
  end

  def search
    # search_sql_merge(原始SQL,表單欄位名稱,條件式欄位字串,{value,keyword} => 一般欄位對應用 value)
    @brand_list=create_brand_list(params[:product_type])
    sql_parameter = Array("select products.* from products") # 這樣寫就會直接把字串轉乘陣列   
    sql_parameter = search_sql_merge(sql_parameter,"product_id","product_id","value")
    if params[:product_id].blank?
      sql_parameter = search_sql_merge(sql_parameter,"product_keyword","name","keyword")
      sql_parameter = search_sql_merge(sql_parameter,"brand_keyword","brand_id","brand")
      sql_parameter = search_sql_merge(sql_parameter,"product_type","product_type","value") if params[:product_type] != "0"
    end
    sql_parameter.first << " ORDER BY id Desc"

    # paginate_by_sql => http://www.rorexperts.com/pagination-with-find-by-sql-using-will-paginate-t830.html
    # 讓Model透過SQL指令搜尋並做分頁   paginate_by_sql(sql_query,page,perpage)
    @products = Product.paginate_by_sql(sql_parameter, :page => params[:page], :per_page => 30)
    @today=Date.today

    @types=Hash.new()
    i18n= I18n.t("activerecord.type") 
    i18n.each_with_index do |str,i|
      @types =  @types.merge({str.last => i})
    end

    @brand_list=@brand_list.invert
    respond_to do |format|
      format.js
      format.html { render :action => "index" } # 指定使用 index 的 template
    end
  end

  def search_sql_merge(sql,params_name,fields,type)
    sql_where_keyword = sql[0].include?("where") ? " and " : " where "
    case type
      when "brand"
        if params[params_name.to_sym].present? 
          # returns an array of brands which include keyword
          @brand_list.keys.grep(/(.*)#{params[params_name.to_sym]}(.*)/i).each do |brand_name|
            sql_where_keyword = sql[0].include?("where") ? " or " : " where ("
            sql[0] << "#{sql_where_keyword}#{fields} like ?"
            sql << "#{@brand_list[brand_name]}"
          end
          sql[0] << ")"
        end 
      when "keyword"
        if params[params_name.to_sym].present? 
          sql_where_keyword = sql[0].include?("where") ? " and " : " where " 
          sql[0] << "#{sql_where_keyword}#{fields} like ?"
          sql << "%#{params[params_name.to_sym]}%"
        end 
      when "value"
        if params[params_name.to_sym].present? 
          sql_where_keyword = sql[0].include?("where") ? " and " : " where "
          sql[0] << "#{sql_where_keyword}#{fields} = ?"
          sql << params[params_name.to_sym]
        end
    end
    return sql
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
          if b.id == 5368
            @brand_list=@brand_list.merge({"Xiaomi" => b.id})
          else
            @brand_list=@brand_list.merge({b.name_normal => b.id})
          end
        end
    end
    return @brand_list
  end



  protected
  def init_product
    @product=Product.find_by_product_id(params[:id]) || Product.find_by_id(params[:id])
  end
end
