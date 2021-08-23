class CreateReposJob < ActiveJobStatus::TrackableJob

  queue_as :create_repos

  after_perform :relay_message

  def perform(manifest, root_url, user_email)
    @manifest = manifest
    @root_url = root_url
    @user_email = user_email
    @manifest.create_repos
  end

  private

  def relay_message
    NotificationMailer.process_completed_email(I18n.t('colenda.mailers.notification.create_repos.subject'), @user_email, I18n.t('colenda.mailers.notification.create_repos.body', :name => @manifest.name, :root_url => @root_url, :link_fragment => @manifest.id)).deliver_now
  end
end
