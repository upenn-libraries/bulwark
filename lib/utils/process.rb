module Utils
  module Process

    def initialize
    end

    extend self

    def import(file)
      @command = build_command("import", :file => file)
      execute_curl
    end

    def attach_file(repo, parent, child_container = "child")
      begin
        file_link = "#{Utils.config.federated_fs_path}/#{repo.directory}/#{repo.assets_subdirectory}/#{parent.file_name}"
        @command = build_command("file_attach", :file => file_link, :fid => parent.id, :child_container => child_container)
        execute_curl
      rescue
        raise $!, "File attachment failed due to the following error(s): #{$!}", $!.backtrace
      end
    end

    def reindex
      ActiveFedora::Base.reindex_everything
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
      case type
      when "import"
        command = "curl -u #{@fedora_user}:#{@fedora_password} -X POST --data-binary \"@#{file}\" \"#{@fedora_link}/fcr:import?format=jcr/xml\""
      when "file_attach"
        fedora_full_path = "#{@fedora_link}/#{fid}/#{child_container}"
        command = "curl -u #{@fedora_user}:#{@fedora_password}  -X PUT -H \"Content-Type: message/external-body; access-type=URL; URL=\\\"#{file}\\\"\" \"#{fedora_full_path}\""
      else
        raise "Invalid command type specified.  Command not built."
      end
      return command
    end

    def execute_curl
      `#{@command}`
    end

  end
end
