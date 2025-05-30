require 'sidekiq/web'
require 'sidekiq/cron/web'

Rails.application.routes.draw do
  namespace :admin do
    resources :alert_messages, only: %w[index update]

    resources :bulk_imports, except: %w[create edit update destroy] do
      member do
        get :csv
      end

      resources :digital_object_imports, only: [:show]
    end

    resources :digital_objects, only: [:index, :show] do
      collection do
        post :csv
      end

      # member do
      #   post :publish
      #   post :unpublish
      #   post :generate_derivatives
      #   post :generate_iiif_manifest
      #   post :refresh_catalog_metadata
      # end
    end

    post 'file_listing_tool/file_list', to: 'file_listing_tool#file_list'
    get 'file_listing_tool', to: 'file_listing_tool#tool'
  end

  get '/admin', to: redirect('/admin/digital_objects')

  namespace :pages do
    get 'about'
  end

  defaults format: :json do
    scope :migration, controller: :migration do
      get ':id/serialized', action: :serialize, as: :serialize
      # post 'migration/:id/migrated', action: :mark_migrated
    end
  end

  resources :items, only: [], constraints: { id: /ark:\/\d{5}\/[a-z0-9]+/ } do
    collection do
      post :create, constraints: { format: :json }
    end

    member do
      delete :destroy, constraints: { format: :json }
      get :manifest
      get :thumbnail
      get :pdf
    end

    resources :assets, only: [], constraints: { id: /[a-zA-Z0-9\-]+/ } do
      member do
        get :thumbnail
        get :access
        get :original
      end
    end
  end

  if Rails.env.development? || Rails.env.test?
    get 'special_remote_download/:bucket/:key',
        action: :special_remote_download,
        controller: :application,
        as: :special_remote_download,
        constraints: { key: /[^\/]+/ }
  end

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
