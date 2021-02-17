module RepoHelper
  include BlacklightHelper
  include Finder

  def render_git_directions_or_actions
    full_path = "#{Utils.config[:assets_path]}/#{@object.names.git}"
    if Dir.exists?(full_path)
      render :partial => 'repos/git_directions', :locals => {:full_path => full_path}
    else
      render :partial => 'repos/git_actions'
    end
  end

  def render_ingest_or_message
    if @object.queued == 'ingest'
      render :partial => 'repos/in_queue'
    elsif @object.queued == 'fedora'
      render :partial => 'repos/processing'
    else
      if @object.metadata_builder.xml_preview.present?
        render :partial => 'repos/ingest_select'
      else
        render :partial => 'repos/no_xml'
      end
    end
  end

  def render_file_checks
    render :partial => 'repos/file_checks'
  end

  def render_ingested_list
    if @object.ingested
      render :partial => 'repos/ingested_links'
    end
  end

  def render_preview_ingested
    if @object.ingested
      render :partial => 'repos/review_and_preview'
    end
  end

  def render_problem_files
    if @object.try(:problem_files).present?
      render :partial => 'repos/problem_files'
    end
  end

  def generate_ingest_link(ingested_id)
    if @object.ingested
      begin
        obj = Finder.fedora_find(ingested_id)
        truncated_title = "#{obj.title.first[0..100]}..."
        link_to(truncated_title, Rails.application.routes.url_helpers.catalog_url(obj, :only_path => true), :target => '_blank', :title => t('colenda.links.new_tab')).html_safe
      rescue
        return
      end
    end
  end

  def problem_files(problem_type)
    selected_problem_files ||= []
    @object.problem_files.find_all do |key, value|
      selected_problem_files << key if value == problem_type
    end
    selected_problem_files
  end

  def display_action_labels(repo_actions_array)
    repo_actions = {}
    repo_actions_array.each do |last_action, amount|
      repo_actions[last_action[:description]] = amount
    end
    return repo_actions
  end

end
