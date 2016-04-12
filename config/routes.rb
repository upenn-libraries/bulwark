Rails.application.routes.draw do
  resources :repos do
    member do
      post :checksum_log
      post :ingest
      post :detect_metadata
      post :save_mappings
      post :generate_xml_preview
    end
  end
  resources :metadata_builders do
    member do
      post :update
      post :git_annex_commit
      post :ingest
    end
  end
  mount RailsAdmin::Engine => '/admin_repo', as: 'rails_admin'
  root to: "catalog#index"
  blacklight_for :catalog
  devise_for :users
  mount Qa::Engine => '/qa'
end
