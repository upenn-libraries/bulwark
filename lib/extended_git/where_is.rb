# Using the `git annex whereis` command finds the location of the set of files
# described by the path and options. Files that are managed by git-annex may
# be stored in different location. This class helps confirm the files that are
# tracked by git-annex and the location of those files.
#
# Examples:
#   git = ExtendedGit.open(directory)

#   To get the location of a specific file without quering for all the files:
#     git.annex.whereis('filename.txt')['filename.txt'].locations
#
#   To get the locations of each file within a directory:
#     files = git.annex.whereis('directory_name/') # Returns list of files
#     files.first.locations                        # Returns the locations of the first file
#     files['specific_file.txt'].locations         # Returns locations of specific file

module ExtendedGit
  class WhereIs
    include Enumerable

    attr_reader :files

    def initialize(base, path = nil, options = {})
      @base = base

      construct_whereis_files(path, options)
    end

    # Enumerable method
    def each(&block)
      @files.values.each(&block)
    end

    def [](file)
      @files[file]
    end

    def includes_file?(file)
      @files.key?(file)
    end

    class WhereIsFile
      attr_accessor :filepath, :locations

      def initialize(json)
        parsed_json = JSON.parse(json)

        @filepath = parsed_json['file']
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
        found_files = results.lines.map { |result| WhereIsFile.new(result) }

        @files = found_files.map { |f| [f.filepath, f] }.to_h
      end
  end
end
