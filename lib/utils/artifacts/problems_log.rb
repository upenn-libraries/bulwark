require 'open-uri'

module Utils
  module Artifacts

    class FileProblems

      attr_reader :problems_hash, :temp_location

      def initialize(repo)
        @problems_hash = repo.problem_files
      end

      def temp_location
        "#{Dir.mktmpdir}/#{Utils.config[:problem_log]}"
      end


      def problems
        formatted = ''
        self.problems_hash.each do |file_path, problem|
          formatted << "#{file_path} - #{problem}\n"
        end
        formatted
      end

    end

    module ProblemsLog

      def problems_log
        log = FileProblems.new(self)
        write_log(log.temp_location, log.problems)
      end

      def write_log(location, contents)
        File.write(location, contents)
        location
      end

    end
  end
end