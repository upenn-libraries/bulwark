module RailsAdminHelper
  include Filesystem
  include Utils

  def render_git_remote_options
    full_path = "#{assets_path_prefix}/#{@object.directory}"
    page_content = content_tag("div", :class => "git-actions") do
      if Dir.exists?(full_path)
        initialized_p = content_tag("p","Your git remote has been initialized at #{full_path}.  To begin using this remote, run the following commands from the terminal:")
        initialized_pre = content_tag("pre", "git annex init\ngit remote add fs ~/#{@object.directory}")
        push_p = content_tag("p","To push to this remote, run the following command from the terminal:")
        push_pre = content_tag("pre","git push fs master")
        concat(initialized_p)
        concat(initialized_pre)
        concat(push_p)
        concat(push_pre)
      else
        # TODO: make construction of the other model's URL stronger for deployment from subdirectories
        page_content = link_to "Create Remote", "/repos/#{@object.id}"
      end
    end
    return page_content
  end

  def render_sources_table(repo)
    headers = Array.new
    repo.metadata_sources.first.each{ |header| headers << header.first.to_s }
    table = _build_table_from_hash(headers, repo.metadata_sources)
    page_content = content_tag("div", table, :class => "metadata-sources-table")
    return page_content
  end

  def _build_table_from_hash(table_headers, hash_to_use)
    headers_formatted = ""
    table_headers.each {|header| headers_formatted << "<th>#{header}</th>" }
    rows = ""
    hash_to_use.each do |row|
      rows << "<tr>"
      row.each do |val|
        rows << "<td>" << val.last << "</td>"
      end
      rows << "</tr>"
    end
    array_table = "<table>#{headers_formatted}#{rows}</table>"
    return array_table.html_safe
  end

end
