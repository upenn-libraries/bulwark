# frozen_string_literal: true

module Admin
  # alert message application actions
  class AlertMessagesController < ApplicationController
    def index
      @header_alert = AlertMessage.header
      @home_alert = AlertMessage.home
    end

    def update
      @alert_message = AlertMessage.find params[:id]
      if @alert_message.update alert_message_params
        redirect_to admin_alert_messages_path, notice: 'Alert updated'
      else
        redirect_to admin_alert_messages_path,
                    notice: "Problem saving Alert: #{@alert_message.errors.messages.first.join ' '}"
      end
    end

    private

      def alert_message_params
        params.require(:alert_message).permit(:active, :message, :level)
      end
  end
end
