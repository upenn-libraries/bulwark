Rails.application.routes.draw do
  root to: "catalog#index"
  blacklight_for :catalog
  devise_for :users
  mount Qa::Engine => '/qa'
  mount HydraEditor::Engine => '/'
  mount Hydra::RoleManagement::Engine => '/'
  Hydra::BatchEdit.add_routes(self)
end
