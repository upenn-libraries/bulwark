require 'smarter_csv'

module AutomatedWorkflows
  module OPenn

    class Configuration
      attr_accessor :owner
      attr_accessor :description
      attr_accessor :initial_stop
      attr_accessor :endpoint
      attr_accessor :metadata_suffix
      attr_accessor :assets_suffix

      def initialize
        @owner = ENV['OPENN_OWNER'] || AutomatedWorkflows.config['openn']['csv']['owner']
        @description = ENV['OPENN_DESCRIPTION'] || AutomatedWorkflows.config['openn']['csv']['description']
        @initial_stop = ENV['OPENN_INITIAL_STOP'] || AutomatedWorkflows.config['openn']['csv']['initial_stop']
        @endpoint = ENV['OPENN_HARVESTING_ENDPOINT'] || nil
        @metadata_suffix = ENV['OPENN_METADATA_ENDPOINT_SUFFIX'] || AutomatedWorkflows.config['openn']['csv']['metadata_suffix']
        @assets_suffix = ENV['OPENN_ASSETS_ENDPOINT_SUFFIX'] || AutomatedWorkflows.config['openn']['csv']['assets_suffix']
      end
    end

    class Csv

      class << self
        def config
          @config ||= Configuration.new
        end

        def configure
          yield config
        end

        def convert_csv(csv_filename)
          directories = []
          listing = SmarterCSV.process(csv_filename)
          prefix_to_strip = "#{csv_filename.split('_').first}/"
          listing.each { |row| directories << "#{row[:path].gsub(prefix_to_strip,'')}|#{row[:updated]}" }
          directories.uniq!
          f = File.new("#{csv_filename.gsub('.csv','.txt')}", 'w')
          directories.each { |d| f << "#{d}\n" }
          f.close
          f.path
        end

        def generate_repos(csv)
          directories_file = convert_csv(csv)
          file_lines = File.readlines(directories_file).each{|l| l.strip! }
          directories = []
          file_lines.each do |dir|
            directory = dir.split('|').first
            last_updated = dir.split('|').last
            AutomatedWorkflows::Actions::Repos.create(directory,
                                                      :owner => AutomatedWorkflows::OPenn::Csv.config.owner,
                                                      :description => AutomatedWorkflows::OPenn::Csv.config.description,
                                                      :last_external_update => last_updated,
                                                      :initial_stop => AutomatedWorkflows::OPenn::Csv.config.initial_stop,
                                                      :endpoint_suffix => directory,
                                                      :assets_suffix => AutomatedWorkflows::OPenn::Csv.config.assets_suffix,
                                                      :type =>'directory')
            directories << directory
          end
          directories
        end

      end

    end
  end
end