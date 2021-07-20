module HeaderAlert
  extend ActiveSupport::Concern

  included do
    before_action :header_alert
  end

  def header_alert
    @header_alert = AlertMessage.header
  end
end
