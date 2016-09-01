class NotificationMailer < ApplicationMailer

  def process_completed_email(subject, user_email, body)
    mail(to: user_email, subject: subject, body: body)
  end

end
