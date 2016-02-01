Rails.application.routes.draw do
  resources :repos do
    member do
      post :checksum_log
    end
  end
  mount RailsAdmin::Engine => '/admin_repo', as: 'rails_admin'
  root to: "catalog#index"
  blacklight_for :catalog
  devise_for :users
  mount Qa::Engine => '/qa'
  mount HydraEditor::Engine => '/'
end
