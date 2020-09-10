module ExtendedGit
  class RepositoryInfo

    attr_reader :remotes

    def initialize(base)
      @base = base

      construct_remote_info
    end

    def remote(name) # TODO: Eventually accept UUID
      remotes.find { |r| r.name == name }
    end

    def remote?(name)
      !!remote(name)
    end

    def construct_remote_info
      raw_result = @base.annex.lib.info(json: true)
      result = JSON.parse(raw_result)
      remotes = result['semitrusted repositories'] + result['trusted repositories'] + result['untrusted repositories']

      @remotes = remotes.map do |remote|
        remote_result = JSON.parse(@base.annex.lib.info(remote['uuid'], json: true))

        # If needed, can expose more information.
        OpenStruct.new(
          uuid: remote['uuid'],
          here: remote['here'],
          description: remote['description'],
          name: remote_result['remote'] || remote['description'], # When the repository is the current one need to use the description.
          type: remote_result['type'],
          directory: remote_result['directory'],
          trust: remote_result['trust']
        )
      end
    end
  end
end
