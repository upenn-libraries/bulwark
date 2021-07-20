class AdminController < ActionController::Base
  before_action :authenticate_user!
  before_action :header_alert

  layout 'admin'

  def header_alert
    @header_alert = AlertMessage.header
  end
end
