module ExtendedGit
  class WhereIs
    include Enumerable

    attr_reader :files

    def initialize(base, path = nil, options = {})
      @base = base

      construct_whereis_files(path, options)
    end

    # enumerable methods
    def [](file)
      @files[file]
    end

    def each(&block)
      @files.each(&block)
    end

    class WhereIsFile
      attr_accessor :name, :locations

      def initialize(json)
        parsed_json = JSON.parse(json)

        @name = parsed_json['file']
        @locations = generate_locations(parsed_json['whereis'])
      end

      # Returns true, if a copy of the file is located in this working directory.
      def here?
        @locations.any?(&:here)
      end

      private
        def generate_locations(locations)
          locations.map do |location|
            OpenStruct.new(
              description: location['description'],
              here: location['here'],
              uuid: location['uuid'],
              urls: location['urls']
            )
          end
        end
    end

    private

      def construct_whereis_files(path = nil, options = {})
        results = @base.annex.lib.whereis(path, json: true, **options)

        # have to divide the results by new line and then each new line can be parsed
        @files = results.lines.map { |result| WhereIsFile.new(result) }
      end
  end
end
