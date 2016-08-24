class NotificationMailer < ApplicationMailer

  def process_completed_email(process_name, user)
    @user = user
    mail(to: @user.email, subject: "#{process_name} completed")
  end

end
