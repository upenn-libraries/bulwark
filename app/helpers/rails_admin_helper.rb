require 'rexml/document'

module RailsAdminHelper

  include CatalogHelper
  include ManifestHelper
  include MetadataBuilderHelper
  include MetadataSourceHelper
  include RepoHelper

  def render_git_remote_options
    render_git_directions_or_actions
  end

  def render_ingest_select_form
    render_ingest_or_message
  end

  def render_ingest_links
    render_ingested_list
  end

  def render_review_box
    repo = Repo.where('unique_identifier = ?', @document.id.reverse_fedorafy).first
    render_review_status(repo)
  end

  def render_status_based_template(unique_identifier, process)
    render :partial => job_based_partial(unique_identifier, process)
  end

  def root_element_options
    MetadataSchema.config[:root_element_options]
  end

  def parent_element_options
    MetadataSchema.config[:parent_element_options]
  end

  def schema_terms
    MetadataSchema.config[:schema_terms]
  end

  def schema_term_default(source_value)
    schema_terms = MetadataSchema.config[:schema_terms].map(&:downcase)
    if schema_terms.index(source_value).present?
      best_guess = schema_terms[schema_terms.index(source_value)]
    elsif schema_terms.index { |s| s.starts_with?(source_value.first.downcase) }.present?
      best_guess = schema_terms[schema_terms.index { |s| s.starts_with?(source_value.first.downcase) }]
    else
      best_guess = schema_terms.first
    end
    best_guess
  end

  def render_job_statuses(unique_identifier, process)
    flash_message = collect_job_status(unique_identifier, process)
    flash[flash_message.first] = flash_message.last if flash_message.present?
  end

  def wrap_values(value)
    content_tag(:li, value_present?(value) ? Array(value).join(', ') : t('colenda.repos.ingest.review.metadata.preview.not_available') ).html_safe
  end

  def value_present?(value)
    singular_classes = [String, NilClass, ActiveTriples::Relation]
    multiples_classes = [Array]
    case
      when singular_classes.include?(value.class)
        return value.present?
      when multiples_classes.include?(value.class)
        return value.all?{|a|a.present?}
      else
        return true
    end
  end

  def form_label(form_type, object_steps)
    case form_type
    when 'generate_xml'
      object_steps[:preservation_xml_generated] ? t('colenda.rails_admin.labels.generate_xml.additional_times') : t('colenda.rails_admin.labels.generate_xml.first_time')
    when 'source_select'
      object_steps[:metadata_sources_selected] ? t('colenda.rails_admin.labels.source_select.additional_times') : t('colenda.rails_admin.labels.source_select.first_time')
    when 'metadata_mappings'
      object_steps[:metadata_mappings_generated] ? t('colenda.rails_admin.labels.metadata_mappings.additional_times') : t('colenda.rails_admin.labels.metadata_mappings.first_time')
    when 'extract_metadata'
      object_steps[:metadata_extracted] ? t('colenda.rails_admin.labels.extract_metadata.additional_times') : t('colenda.rails_admin.labels.extract_metadata.first_time')
    when 'metadata_source_additional_info'
      object_steps[:metadata_source_additional_info_set] ? t('colenda.rails_admin.labels.metadata_source_additional_info.additional_times'): t('colenda.rails_admin.labels.metadata_source_additional_info.first_time')
    when 'set_source_types'
      object_steps[:metadata_source_type_specified] ? t('colenda.rails_admin.labels.set_source_types.additional_times') : t('colenda.rails_admin.labels.set_source_types.first_time')
    when 'file_checks'
      t('colenda.rails_admin.labels.file_checked')
    when 'queued_for_ingest'
      object_steps[:queued_for_ingest] ? t('colenda.rails_admin.labels.queued_for_ingest.additional_times') : t('colenda.rails_admin.labels.queued_for_ingest.first_time')
    when 'publish_preview'
      object_steps[:published_preview] ? t('colenda.rails_admin.labels.publish_preview.additional_times') : t('colenda.rails_admin.labels.publish_preview.first_time')
    when 'validate_manifest'
      object_steps[:validate_manifest] ? t('colenda.rails_admin.labels.validate_manifest.additional_times') : t('colenda.rails_admin.labels.validate_manifest.first_time')
    when 'create_repos'
      object_steps[:create_repos] ? t('colenda.rails_admin.labels.create_repos.additional_times') : t('colenda.rails_admin.labels.create_repos.first_time')
    when 'process_manifest'
      object_steps[:process_manifest] ? t('colenda.rails_admin.labels.process_manifest.additional_times') : t('colenda.rails_admin.labels.process_manifest.first_time')
    else
      'Submit'
    end
  end

  def job_based_partial(unique_identifier, process)
    job_id = get_job_id_by_process(unique_identifier, process)
    (ActiveJobStatus::JobStatus.get_status(job_id: job_id) == :queued) || (ActiveJobStatus::JobStatus.get_status(job_id: job_id) == :working) ? 'shared/waiting' : ready_partial(process)
  end

  def ready_partial(process)
    partial = ''
    case process
    when 'ingest'
      partial = 'rails_admin/main/ingest_dashboard'
    when 'metadata_extraction'
      partial = 'rails_admin/main/extract_and_map_metadata'
    when 'generate_xml'
      partial = 'rails_admin/main/preview_xml'
    when 'file_checks'
      partial = 'rails_admin/main/file_checks'
    when 'validate_manifest'
      partial = 'rails_admin/main/validate_manifest'
    when 'create_repos'
      partial = 'rails_admin/main/create_repos'
    when 'process_manifest'
      partial = 'rails_admin/main/process_manifest'
    else
      partial = 'shared/generic_error'
    end
    partial
  end

  def collect_job_status(unique_identifier, process)
    job_status_message ||= ''
    job_id = get_job_id_by_process(unique_identifier, process)
    job_info = current_user.job_activity[job_id]
    job_status_message = job_status(job_id, job_info) if job_id.present?
    job_status_message
  end

  def job_status(job_id, job_info)
  job_status = ActiveJobStatus::JobStatus.get_status(job_id: job_id)
  case job_status
    when :queued
      [:warning, t('colenda.rails_admin.jobs.queued', :process => job_info[:process], :unique_identifier => job_info[:unique_identifier], :started => job_info[:started])]
    when :working
      [:warning, t('colenda.rails_admin.jobs.processing', :process => job_info[:process], :unique_identifier => job_info[:unique_identifier], :started => job_info[:started])]
    when nil
      [:success, t('colenda.rails_admin.jobs.complete', :process => job_info[:process], :unique_identifier => job_info[:unique_identifier], :started => job_info[:started])]
    else
      nil
  end

  end

  def get_job_id_by_process(unique_identifier, process)
    current_user.job_activity.find{|key,value| value[:unique_identifier] == unique_identifier && value[:process] == process}.try(:first)
  end

  def identifier_selection(attributes)
    attributes['id'].present? ? attributes['id'] : 'Object'
  end

  def thumbnail_preview(thumbnail_link)
    image_tag(thumbnail_link, :width => 100, :height => 150)
  end

  def self.render_queue_names(names)
    queue_names = ''
    names.split('|').each do |name|
      queue_names << "<li>#{name}</li>"
    end
    return "<ul>#{queue_names}</ul>"
  end

end
