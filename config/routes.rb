Rails.application.routes.draw do
  root to: "catalog#index"
  blacklight_for :catalog
  devise_for :users
  mount HydraEditor::Engine => '/'
  mount Hydra::RoleManagement::Engine => '/'
end
