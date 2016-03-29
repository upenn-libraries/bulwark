require "rexml/document"

module RailsAdminHelper

  include MetadataBuilderHelper
  include RepoHelper
  include Filesystem
  include Utils

  def render_git_remote_options
    render_git_directions_or_actions
  end

  def render_metadata_builder_form
    render_form_or_message
  end

  def render_generate_xml
    render_xml_or_message
  end

  def _metadata_builder(repo)
    mb = MetadataBuilder.where(:parent_repo => repo.id).blank? ? MetadataBuilder.create(:parent_repo => repo.id) : MetadataBuilder.find_by(:parent_repo => repo.id)
    return mb
  end

  def render_sample_xml
    @object.version_control_agent.clone
    @object.version_control_agent.get(:get_location => "#{@object.version_control_agent.working_path}/#{@object.metadata_subdirectory}")
    @sample_xml_docs = ""
    @object.metadata_builder.preserve.each do |file|
      sample_xml_content = File.open(file, "r"){|io| io.read}
      sample_xml_doc = REXML::Document.new sample_xml_content
      sample_xml = ""
      sample_xml_doc.write(sample_xml, 1)
      header = content_tag(:h3, "XML Sample for #{file.gsub(@object.version_control_agent.working_path, "")}")
      xml_code = content_tag(:pre, "#{sample_xml}")
      @sample_xml_docs << content_tag(:div, header << xml_code, :class => "doc")
    end
    @object.version_control_agent.delete_clone
    return @sample_xml_docs.html_safe
  end

  def render_flash_errors
    error_list = ""
    flash[:error].each do |errors|
      errors.each do |e|
        error_list << content_tag("li", e)
      end
    end
    flash[:error] = content_tag("ul", error_list.html_safe).html_safe if flash[:error]
  end

  def refresh_metadata_from_source
    unless flash[:error]
      @object.metadata_builder.set_source
      @object.metadata_builder.save!
    end
  end

end
