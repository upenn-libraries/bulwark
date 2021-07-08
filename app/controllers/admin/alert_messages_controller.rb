# frozen_string_literal: true

module Admin
  # alert message application actions
  class AlertMessagesController < ApplicationController
    def index
      @alert_messages = AlertMessage.all
    end

    def new
      @alert_message = AlertMessage.new
    end

    def create
      @alert_message = AlertMessage.create alert_message_params
      redirect_to admin_alert_message_path @alert_message.id
    end

    def show
      @alert_message = AlertMessage.find params[:id]
    end

    def edit
      @alert_message = AlertMessage.find params[:id]
    end

    def update
      @alert_message = AlertMessage.find params[:id]
      @alert_message.update alert_message_params
      redirect_to admin_alert_message_path @alert_message.id
    end

    def destroy
      @alert_message = AlertMessage.find params[:id]
      @alert_message.destroy
      redirect_to admin_alert_messages_path, alert: 'Alert Message deleted'
    end

    private

      def alert_message_params
        params.require(:alert_message).permit(:active, :display_on, :display_until,
                                              :message, :level, :location)
      end
  end
end
