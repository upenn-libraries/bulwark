require "rexml/document"

module RailsAdminHelper

  include Filesystem
  include Utils

  def render_git_remote_options
    full_path = "#{assets_path_prefix}/#{@object.directory}"
    page_content = content_tag("div", :class => "git-actions") do
      if Dir.exists?(full_path)
        initialized_p = content_tag("p","Your git remote has been initialized at #{full_path}.  To begin using this remote, run the following command from the terminal:")
        #TODO: Create config option to store server URL for users creating remotes
        initialized_pre = content_tag("pre", "git clone #{Utils.config.assets_path}/#{@object.directory}\ncd #{(@object.directory).gsub(".git","")}")
        concat(initialized_p << initialized_pre)
      else
        # TODO: make construction of the other model's URL stronger for deployment from subdirectories
        page_content = link_to "Create Remote", "/repos/#{@object.id}"
      end
    end
    return page_content
  end

  def render_sources_table(repo)
    table = _build_table_from_hash(repo.metadata_builder.source)
    page_content = content_tag("div", table, :class => "metadata-sources-table")
    return page_content
  end

  def _build_table_from_hash(hash_to_use)
    header = "<th>File Path</th>"
    rows = ""
    hash_to_use.each do |row|
      rows << "<tr>" << "<td>" << row << "</td>" << "</tr>"
    end
    array_table = "<table>#{header}#{rows}</table>"
    return array_table.html_safe
  end


  def _metadata_builder(repo)
    mb = MetadataBuilder.where(:parent_repo => repo.id).blank? ? MetadataBuilder.create(:parent_repo => repo.id) : MetadataBuilder.find_by(:parent_repo => repo.id)
    return mb
  end

  def render_sample_xml(sample_xml_content)
    sample_xml_docs = ""
    sample_xml_doc = REXML::Document.new sample_xml_content
    sample_xml = ""
    sample_xml_doc.write(sample_xml, 1)
    xml_code = content_tag(:pre, "#{sample_xml}")
    sample_xml_docs << content_tag(:div, xml_code, :class => "doc")
    return sample_xml_docs.html_safe
  end

end
