class AdminController < ActionController::Base
  include HeaderAlert

  before_action :authenticate_user!

  layout 'admin'
end
