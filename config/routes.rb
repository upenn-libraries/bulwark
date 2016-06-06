Rails.application.routes.draw do

  resources :repos do
    member do
      post :checksum_log
      post :ingest
      post :detect_metadata
    end
  end

  resources :metadata_builders do
    member do
      post :update
      post :ingest
      post :preserve
      post :set_source
      post :clear_files
      post :refresh_metadata
      post :generate_preview_xml
    end
  end

  resources :manuscripts do
    post :update
  end

  resources :metadata_sources

  mount RailsAdmin::Engine => '/admin_repo', as: 'rails_admin'
  root to: "catalog#index"
  blacklight_for :catalog
  devise_for :users
  mount Qa::Engine => '/qa'
end
