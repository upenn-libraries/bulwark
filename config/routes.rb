Rails.application.routes.draw do
  resources :repos do
    member do
      post :checksum_log
      post :prepare_for_ingest
      post :ingest
      post :detect_metadata
      post :convert_metadata
      post :save_mappings
    end
  end
  resources :metadata_builders do
    member do
      post :update
    end
  end
  mount RailsAdmin::Engine => '/admin_repo', as: 'rails_admin'
  root to: "catalog#index"
  blacklight_for :catalog
  devise_for :users
  mount Qa::Engine => '/qa'
end
