class ApplicationController < ActionController::Base
  # Adds a few additional behaviors into the application controller
  include Blacklight::Controller
  include Hydra::Controller::ControllerBehavior
  include Blacklight::Base

  layout 'blacklight'

  rescue_from ActiveRecord::RecordNotFound, :with => :rescue_not_found

  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :null_session
end
