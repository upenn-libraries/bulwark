module BaseModelsController
  def sanitize(field_value)
    ActionController::Base.helpers.sanitize(field_value)
  end
end
