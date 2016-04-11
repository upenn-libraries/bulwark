module RepoHelper
  include Blacklight::BlacklightHelperBehavior
  def render_git_directions_or_actions
    full_path = "#{assets_path_prefix}/#{@object.directory}"
    if Dir.exists?(full_path)
      render :partial => "repos/git_directions", :locals => {:full_path => full_path}
    else
      render :partial => "repos/git_actions"
    end
  end

  def render_ingested_list
    # docs_array.each do |doc|
    #   binding.pry()
    # end
  end

end
