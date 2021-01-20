require 'sidekiq/web'
require 'sidekiq/cron/web'

Rails.application.routes.draw do
  resources :repos do
    member do
      post :repo_new
      post :update
      post :checksum_log
      post :ingest
      post :review_status
      post :detect_metadata
      post :fetch_by_ark
      get :download
      get :fetch_image_ids, :defaults => { :format => 'json' }
    end
  end

  resources :batches do
    member do
      post :batch_new
      post :process_batch
    end
  end

  resources :manifests do
    member do
      post :manifest_new
      post :validate_manifest
      post :create_repos
      post :process_manifest
    end
  end

  resources :metadata_builders do
    member do
      post :update
      post :queue_for_ingest
      post :remove_from_queue
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

  namespace :admin do
    resources :digital_objects, only: [:index, :show]
    resources :bulk_imports, except: %w[edit update destroy]

    if Rails.env.development? || Rails.env.test?
      get 'special_remote_download/:bucket/:key', to: :special_remote_download, as: :special_remote_download, constraints: { key: /[^\/]+/ }
    end
  end

  get '/admin', to: redirect('/admin/digital_objects')

  mount RailsAdmin::Engine => '/admin_repo', as: 'rails_admin'

  root to: 'catalog#index'
  blacklight_for :catalog, except: [:bookmarks, :saved_searches, :search_history]

  devise_for :users, skip: :registrations
  devise_scope :user do
    resource :registration,
             only: [:edit, :update],
             path: 'users'
  end

  authenticate :user do
    mount Qa::Engine => '/qa'
    mount Sidekiq::Web => '/sidekiq'
  end
end
