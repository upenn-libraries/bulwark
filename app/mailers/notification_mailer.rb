class NotificationMailer < ApplicationMailer

  def process_completed_email(process_name, user_email, body)
    mail(to: user_email, subject: "#{process_name} completed", body: body)
  end

end
