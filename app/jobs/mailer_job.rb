class MailerJob < ActiveJobStatus::TrackableJob

  queue_as :mailer

  after_perform :relay_message

  def perform(action, message, email = '')
    if action == 'create'
      @subject = I18n.t('colenda.mailers.notification.batch_created.subject')
      @email = BatchOps.config[:email]
      @message = message
    elsif action == 'remove'
      @subject = I18n.t('colenda.mailers.notification.batch_removed.subject')
      @email = BatchOps.config[:email]
      @message = message
    elsif action == 'processed'
      @subject = I18n.t('colenda.mailers.notification.batch_processed.subject')
      @email = "#{BatchOps.config[:email]};#{email};"
      @message = message
    end

  end

  private

  def relay_message
    NotificationMailer.process_completed_email(@subject, @email, @message).deliver_now
  end

end
