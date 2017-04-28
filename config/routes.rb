require 'sidekiq/web'
Rails.application.routes.draw do

  resources :repos do
    member do
      post :repo_new
      post :update
      post :checksum_log
      post :ingest
      post :review_status
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
      post :fetch_voyager
      post :generate_preview_xml
      post :file_checks
    end
  end

  resources :metadata_sources

  mount RailsAdmin::Engine => '/admin_repo', as: 'rails_admin'
  root to: "catalog#index"
  blacklight_for :catalog
  devise_for :users

  authenticate :user do
    mount Qa::Engine => '/qa'
    mount Sidekiq::Web => '/sidekiq'
  end


end
