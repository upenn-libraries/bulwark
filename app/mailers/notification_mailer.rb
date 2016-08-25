class NotificationMailer < ApplicationMailer

  def process_completed_email(process_name, user_email)
    binding.pry()
    mail(to: user_email, subject: "#{process_name} completed", body: "hooray!")
  end

end
