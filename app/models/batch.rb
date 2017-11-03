class Batch < ActiveRecord::Base

  validates :queue_list, presence: true
  validates :email, presence: true

  serialize :queue_list, Array

  around_create :queue_repos

  before_destroy :dequeue_repos

  def queue_repos
    yield
    set_queued_status(self.queue_list, {:action => 'add'})
    message = I18n.t('colenda.mailers.notification.batch_created.body', :uuid => self.id, :queue_list => self.queue_list)
    MailerJob.perform_now('create', message)
  end

  def dequeue_repos
    errors.add(:base, 'Batch in process to Fedora, cannot delete') if self.status == 'in_progress'
    return false if errors.present?
    set_queued_status(self.queue_list, {:action => 'remove'}) if errors.blank?
    message = I18n.t('colenda.mailers.notification.batch_removed.body', :uuid => self.id, :queue_list => self.queue_list)
    MailerJob.perform_now('remove', message)
  end

  def queue_list=(queue_list)
    queued = Array.wrap(queue_list).reject(&:blank?)
    self[:queue_list] = queued
    self[:directive_names] = reconcile_names(queued)
  end

  def email=(email)
    self[:email] = email
  end

  def directive_names=(directive_names)
    self[:directive_names] = directive_names
  end

  def set_queued_status(queue_list, options = {})
    queue_list.each do |qid|
      repos_check = Repo.where(:unique_identifier => qid)
      raise 'Two repos with same unique identifier!' if repos_check.length > 1
      repo = repos_check.first
      if options[:action] == 'add'
        repo.queued = 'fedora'
        repo.update_last_action('Queued for Fedora')
      elsif options [:action] == 'remove'
        repo.queued = 'ingest'
        repo.update_last_action('Pre-Fedora review complete')
      elsif options [:action] == 'processed'
        repo.queued = 'processed'
        repo.update_last_action('Ingested to Fedora')
      else
        return
      end
    end
  end

  def load_all_queueable
    return Repo.where('queued' => 'ingest').pluck(:human_readable_name, :unique_identifier)
  end

  def activate
    self.status = 'in_progress'
    self.start = DateTime.now
    self.save!
  end

  def wrapup
    self.status = 'complete'
    self.end = DateTime.now
    self.save!
    set_queued_status(self.queue_list, {:action => 'processed'})
    report_blob = run_report(self.queue_list)
    message = I18n.t('colenda.mailers.notification.batch_processed.body', :uuid => self.id, :queue_list => self.queue_list, :report_blob => report_blob)
    MailerJob.perform_now('processed', message, self.email)
  end

  def run_report(identifiers)
    report_blob = "(page_count excludes reference shots)\nStarted: #{self.start} | Ended: #{self.end}\n"
    report_blob << "Ark_Identifier | Directive_Name | Page_Count\n"
    identifiers.each do |uuid|
      repo = Repo.where(:unique_identifier => uuid).first
      report_blob << "#{uuid} | #{repo.names.human} | #{repo.images_to_render.keys.length}\n"
    end
    return report_blob
  end

  def reconcile_names(queue_list)
    names = ''
    queue_list.each do |u|
      names << "#{Repo.where(:unique_identifier => u).pluck(:human_readable_name).first}|"
    end
    return names.to_s
  end

end
