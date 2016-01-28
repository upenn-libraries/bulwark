module RailsAdminHelper
  include Filesystem

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
end
