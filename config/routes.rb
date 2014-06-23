Fet::Application.routes.draw do
  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Sample resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Sample resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Sample resource route with more complex sub-resources
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', :on => :collection
  #     end
  #   end

  # Sample resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  # root :to => 'welcome#index'
  root :to => "ui_indexs/mains#index"
  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id))(.:format)'

  resources :upload_tools
  resources :products do
    get "import_spec",:on => :collection
    get "import_info",:on => :collection
    get "import_pic",:on => :collection
    get "update_info",:on => :collection
    get "update_pic",:on => :collection
    get "update_spec",:on => :collection
    get "sync",:on => :collection
    get "import_all_image",:on => :collection
    get "import_all_product",:on => :collection
  end

  resources :xmls ,:defaults => { :format => 'xml' }

  namespace :ui_indexs do
    resources :official_images do
      get "upload",:on => :collection
    end
    resources :sogi_images
    resources :product_images
    resources :specs
    resources :features
    resources :mains
    resources :products do
      put "cancel_from_next_XML"
      put "put_in_next_XML"
      get "search", :on => :collection
      put "search", :on => :collection
    end  
  end

end
