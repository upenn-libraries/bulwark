module Utils
  module Process

    include Finder

    @@status_message
    @@status_type
    @@derivatives_working_destination
    @@working_path

    extend self

    def import(file, repo, working_path)
      Repo.update(repo.id, :ingested => false)
      @@working_path = working_path
      @oid = repo.names.fedora
      @@derivatives_working_destination = "#{@@working_path}/#{repo.derivatives_subdirectory}"
      @@status_type = :error
      af_object = Finder.fedora_find(@oid)
      delete_duplicate(af_object) if af_object.present?
      @@status_message = contains_blanks(file) ? I18n.t('colenda.utils.process.warnings.missing_identifier') : execute_curl(_build_command('import', :file => file))
      FileUtils.rm(file)
      repo.problem_files = {}
      repo.version_control_agent.unlock(:content => repo.derivatives_subdirectory)
      attach_files(@oid, repo, Manuscript, Page)
      update_index(@oid)
      repo.save!
      repo.version_control_agent.add(:content => repo.derivatives_subdirectory)
      repo.version_control_agent.commit(I18n.t('colenda.version_control_agents.commit_messages.generated_all_derivatives', :object_id => repo.names.fedora))
      repo.version_control_agent.push
      @@status_type = :success
      @@status_message = I18n.t('colenda.utils.process.success.ingest_complete')
      Repo.update(repo.id, :ingested => true)
      {@@status_type => @@status_message}
    end

    def delete_duplicate(af_object)
      object_id = af_object.id
      execute_curl(_build_command('delete', :object_uri => af_object.translate_id_to_uri.call(object_id)))
      execute_curl(_build_command('delete_tombstone', :object_uri => af_object.translate_id_to_uri.call(object_id)))
      clear_af_cache(object_id)
    end

    def attach_files(oid = @oid, repo, parent_model, child_model)
      repo.images_to_render = {}
      children = []
      parent = Finder.fedora_find(oid)
      object_uri = ActiveFedora::Base.id_to_uri(oid)
      children_uris = ActiveFedora::Base.descendant_uris(object_uri)
      children_uris.delete_if { |c| c == object_uri }
      children_uris.each do |child_uri|
        child = Finder.fedora_find(ActiveFedora::Base.uri_to_id(child_uri))
        children << child
        if child.file_name.present?
          attach_file(repo, child, child.file_name, 'pageImage')
          parent.members << child
        end
      end
      children_sorted = children.sort_by! { |c| c.page_number }
      children_sorted.each do |child_sorted|
        file_print = child_sorted.pageImage.uri
        repo.images_to_render[file_print.to_s.html_safe] = child_sorted.serialized_attributes
      end
      parent.save
    end

    def attach_file(repo, parent, file_name, child_container = 'child')
      file_link = "#{@@working_path}/#{repo.assets_subdirectory}/#{file_name}"
      repo.version_control_agent.get(:location => file_link)
      repo.version_control_agent.unlock(:content => file_link)
      validation_state = validate_file(file_link)
      if validation_state.nil?
        derivative_link = "#{Utils.config[:federated_fs_path]}/#{repo.names.directory}/#{repo.derivatives_subdirectory}/#{Utils::Derivatives::Access.generate_copy(file_link, @@derivatives_working_destination)}"
        execute_curl(_build_command('file_attach', :file => derivative_link, :fid => parent.id, :child_container => child_container))
      else
        @@status_type = :warning
        repo.log_problem_file(file_link.gsub(@@working_path,''), validation_state)
      end
    end

    def generate_thumbnail(repo)
      unencrypted_thumbnail_path = "#{@@working_path}/#{repo.assets_subdirectory}/#{repo.thumbnail}"
      thumbnail_link = File.exist?(unencrypted_thumbnail_path) ? "#{Utils.config[:federated_fs_path]}/#{repo.names.directory}/#{repo.derivatives_subdirectory}/#{Utils::Derivatives::Thumbnail.generate_copy(unencrypted_thumbnail_path, @@derivatives_working_destination)}" : ''
      execute_curl(_build_command('file_attach', :file => thumbnail_link, :fid => repo.names.fedora, :child_container => 'thumbnail'))
      refresh_assets(repo)
    end

    def refresh_assets(repo)
      display_path = "#{Utils.config[:assets_display_path]}/#{repo.names.directory}"
      if File.directory?("#{Utils.config[:assets_display_path]}/#{repo.names.directory}")
        Dir.chdir(display_path)
        repo.version_control_agent.reset_hard(:location => "#{display_path}/#{repo.derivatives_subdirectory}")
        repo.version_control_agent.pull(:location => "#{display_path}/#{repo.derivatives_subdirectory}")
        repo.version_control_agent.get(:location => "#{display_path}/#{repo.derivatives_subdirectory}")
        repo.version_control_agent.unlock(:location => "#{display_path}/#{repo.derivatives_subdirectory}", :content => "#{display_path}/#{repo.derivatives_subdirectory}")
      else
        repo.version_control_agent.clone(:destination => display_path)
        refresh_assets(repo)
      end
    end

    def jettison_originals(repo, commit_message)
      Dir.glob("#{@@working_path}/#{repo.assets_subdirectory}/*").each do |original|
        repo.version_control_agent.unlock(original)
        FileUtils.rm(original)
      end
      repo.version_control_agent.commit(commit_message)
    end

    def update_index(object_id)
      if check_persisted(object_id)
        object_and_descendants_action(object_id, 'update_index')
      end
    end

    def execute_curl(command)
      `#{command}`
    end

    protected

    def validate_file(file)
      begin
        MiniMagick::Image.open(file)
        return nil
      rescue => exception
        return 'missing' if exception.inspect.downcase =~ /no such file/
        return 'invalid' if exception.inspect.downcase =~ /minimagick::invalid/
        return 'unknown file issue'
      end
    end

    def contains_blanks(file)
      status = File.read(file) =~ /<sv:node sv:name="">/
      status.nil? ? false : true
    end

    def object_and_descendants_action(parent_id, action)
      uri = ActiveFedora::Base.id_to_uri(parent_id)
      refresh_ldp_contains(uri)
      descs = ActiveFedora::Base.descendant_uris(uri)
      descs.each do |desc|
        begin
          Finder.fedora_find(ActiveFedora::Base.uri_to_id(desc)).send(action)
        rescue
          next
        end
      end
    end

    def check_persisted(object_id)
      Ldp::Orm.new(Ldp::Resource::RdfSource.new(ActiveFedora.fedora.connection, ActiveFedora::Base.id_to_uri(object_id))).persisted?
    end

    def refresh_ldp_contains(container_uri)
      resource = Ldp::Resource::RdfSource.new(ActiveFedora.fedora.connection, container_uri)
      orm = Ldp::Orm.new(resource)
      orm.graph.delete
      orm.save
    end

    def clear_af_cache(object_id)
      uri = ActiveFedora::Base.id_to_uri(object_id)
      resource = Ldp::Resource::RdfSource.new(ActiveFedora.fedora.connection, uri)
      resource.client.clear_cache
    end

    private

    def _build_command(type, options = {})
      @fedora_yml = "#{Rails.root}/config/fedora.yml"
      fedora_config = YAML.load(ERB.new(File.read(@fedora_yml)).result)[Rails.env]
      @fedora_user = fedora_config['user']
      @fedora_password = fedora_config['password']
      @fedora_link = "#{fedora_config['url']}#{fedora_config['base_path']}"
      child_container = options[:child_container]
      file = options[:file]
      fid = options[:fid]
      object_uri = options[:object_uri]
      case type
        when 'import'
          command = "curl -u #{@fedora_user}:#{@fedora_password} -X POST --data-binary \"@#{file}\" \"#{@fedora_link}/fcr:import?format=jcr/xml\""
        when 'file_attach'
          fedora_full_path = "#{@fedora_link}/#{fid}/#{child_container}"
          command = "curl -u #{@fedora_user}:#{@fedora_password}  -X PUT -H \"Content-Type: message/external-body; access-type=URL; URL=\\\"#{file}\\\"\" \"#{fedora_full_path}\""
        when 'delete'
          command = "curl -u #{@fedora_user}:#{@fedora_password} -X DELETE \"#{object_uri}\""
        when 'delete_tombstone'
          command = "curl -u #{@fedora_user}:#{@fedora_password} -X DELETE \"#{object_uri}/fcr:tombstone\""
        else
          raise I18n.t('colenda.utils.process.warnings.invalid_curl_command')
      end
      command
    end

  end
end