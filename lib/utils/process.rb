module Utils
  module Process

    @@status_message
    @@status_type

    extend self

    def import(file, repo)
      @command = build_command("import", :file => file)
      @oid = File.basename(repo.unique_identifier)
      @@status_type = :error
      @@status_message = contains_blanks(file) ? "Object(s) missing identifier.  Please check metadata source." : execute_curl
      unless @@status_message.present?
        object_and_descendants_action(@oid, "update_index")
        @@status_message = "Ingestion complete.  See link(s) below to preview ingested items associated with this repo.\n"
        @@status_type = :success
        ActiveFedora::Base.find(@oid).try(:attach_files, repo)
        repo.version_control_agent.push
      end
      if(@@status_message == "Item already exists") then
        obj = ActiveFedora::Base.find(@oid)
        object_and_descendants_action(@oid, "delete")
        @command = build_command("delete_tombstone", :object_uri => obj.translate_id_to_uri.call(obj.id))
        execute_curl
        import(file, repo)
      end
      return {@@status_type => @@status_message}
    end

    def attach_file(repo, parent, file_name, child_container = "child")
      file_link = "#{repo.version_control_agent.working_path}/#{repo.assets_subdirectory}/#{file_name}"
      repo.version_control_agent.get(:get_location => file_link)
      repo.version_control_agent.unlock(file_link)
      validated = validate_file(file_link) if File.exist?(file_link)
      if(File.exist?(file_link) && validated)
        derivatives_destination = "#{repo.version_control_agent.working_path}/#{repo.derivatives_subdirectory}"
        derivative_link = "#{Utils.config.federated_fs_path}/#{repo.directory}/#{repo.derivatives_subdirectory}/#{Utils::Derivatives::Access.generate_copy(file_link, derivatives_destination)}"
        thumbnail_link = "#{Utils.config.federated_fs_path}/#{repo.directory}/#{repo.derivatives_subdirectory}/#{Utils::Derivatives::Thumbnail.generate_copy(file_link, derivatives_destination)}"
        @command = build_command("file_attach", :file => derivative_link, :fid => parent.id, :child_container => child_container)
        execute_curl
        @command = build_command("file_attach", :file => thumbnail_link, :fid => repo.unique_identifier, :child_container => "thumbnail")
        execute_curl
        repo.version_control_agent.add(:add_location => "#{derivatives_destination}")
        repo.version_control_agent.commit("Generated derivative for #{parent.file_name}")
      else
        @@status_type = :warning
        if File.exist?(file_link)
          @@status_message << "Image #{repo.assets_subdirectory}/#{file_name} did not pass validation.  No derivatives made or attached.\n"
        else
          @@status_message << "Image #{repo.assets_subdirectory}/#{file_name} not detected in file directory.  No derivatives made or attached.\n"
        end
      end
    end

    protected

    def validate_file(file)
      begin
        MiniMagick::Image.open(file)
        return true
      rescue MiniMagick::Invalid
        return false
      end
    end

    def generate_additional_derivatives(file, destination)
      Utils::Derivatives.generate_additional_derivatives(file, destination)
    end

    private

    @fedora_yml = "#{Rails.root}/config/fedora.yml"
    fedora_config = YAML.load_file(File.expand_path(@fedora_yml, __FILE__))
    @fedora_user = fedora_config['development']['user']
    @fedora_password = fedora_config['development']['password']
    @fedora_link = "#{fedora_config['development']['url']}#{fedora_config['development']['base_path']}"

    def build_command(type, options = {})
      child_container = options[:child_container]
      file = options[:file]
      fid = options[:fid]
      object_uri = options[:object_uri]
      case type
      when "import"
        command = "curl -u #{@fedora_user}:#{@fedora_password} -X POST --data-binary \"@#{file}\" \"#{@fedora_link}/fcr:import?format=jcr/xml\""
      when "file_attach"
        fedora_full_path = "#{@fedora_link}/#{fid}/#{child_container}"
        command = "curl -u #{@fedora_user}:#{@fedora_password}  -X PUT -H \"Content-Type: message/external-body; access-type=URL; URL=\\\"#{file}\\\"\" \"#{fedora_full_path}\""
      when "delete"
        command = "curl -u #{@fedora_user}:#{@fedora_password} -X DELETE \"#{object_uri}\""
      when "delete_tombstone"
        command = "curl -u #{@fedora_user}:#{@fedora_password} -X DELETE \"#{object_uri}/fcr:tombstone\""
      else
        raise "Invalid command type specified.  Command not built."
      end
      return command
    end

    def execute_curl
      `#{@command}`
    end

    def contains_blanks(file)
      status = File.read(file) =~ /<sv:node sv:name="">/
      return status.nil? ? false : true
    end

    def object_and_descendants_action(parent_id, action)
      uri = ActiveFedora::Base.id_to_uri(parent_id)
      refresh_ldp_contains(uri)
      descs = ActiveFedora::Base.descendant_uris(uri)
      descs.rotate!
      descs.each do |desc|
        ActiveFedora::Base.find(ActiveFedora::Base.uri_to_id(desc)).send(action)
      end
    end

    def refresh_ldp_contains(container_uri)
      resource = Ldp::Resource::RdfSource.new(ActiveFedora.fedora.connection, container_uri)
      orm = Ldp::Orm.new(resource)
      orm.graph.delete
      orm.save
    end


  end
end
