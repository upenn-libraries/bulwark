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
      post :git_annex_commit
      post :ingest
      post :preserve
      post :set_source
      post :set_preserve
      post :clear_files
      post :generate_preview_xml
    end
  end

  resources :metadata_sources

  mount RailsAdmin::Engine => '/admin_repo', as: 'rails_admin'
  root to: "catalog#index"
  blacklight_for :catalog
  devise_for :users
  mount Qa::Engine => '/qa'
end
