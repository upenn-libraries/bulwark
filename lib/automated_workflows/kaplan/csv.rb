require 'smarter_csv'

module AutomatedWorkflows
  module Kaplan

    class Configuration
      attr_accessor :owner
      attr_accessor :description
      attr_accessor :initial_stop
      attr_accessor :endpoint
      attr_accessor :metadata_suffix
      attr_accessor :assets_suffix
      attr_accessor :metadata_fetch_method
      attr_accessor :metadata_protocol
      attr_accessor :assets_fetch_method
      attr_accessor :assets_protocol


      def initialize
        @owner = ENV['KAPLAN_OWNER'] || AutomatedWorkflows.config['openn']['csv']['owner']
        @description = ENV['KAPLAN_DESCRIPTION'] || AutomatedWorkflows.config['kaplan']['csv']['description']
        @initial_stop = ENV['KAPLAN_INITIAL_STOP'] || AutomatedWorkflows.config['kaplan']['csv']['initial_stop']
        @endpoint = ENV['KAPLAN_HARVESTING_ENDPOINT_REMOTE'] || ''
        @metadata_suffix = ENV['KAPLAN_METADATA_SUFFIX'] || AutomatedWorkflows.config['kaplan']['csv']['metadata_suffix']
        @assets_suffix = ENV['KAPLAN_ASSETS_SUFFIX'] || AutomatedWorkflows.config['kaplan']['csv']['assets_suffix']
        @metadata_fetch_method = AutomatedWorkflows.config['kaplan']['csv']['endpoints']['metadata_fetch_method'] || ''
        @metadata_protocol = AutomatedWorkflows.config['kaplan']['csv']['endpoints']['metadata_protocol'] || ''
        @assets_fetch_method = AutomatedWorkflows.config['kaplan']['csv']['endpoints']['assets_fetch_method'] || ''
        @assets_protocol = AutomatedWorkflows.config['kaplan']['csv']['endpoints']['assets_protocol'] || ''
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
          return "#{csv_filename} not found" unless File.exist?(csv_filename)
          directories = []
          listing = SmarterCSV.process(csv_filename)
          listing.each { |row| directories << row[:path] }
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
            directory = dir
            last_updated = DateTime.now
            repo = AutomatedWorkflows::Actions::Repos.create(directory,
                                                             :owner => AutomatedWorkflows::Kaplan::Csv.config.owner,
                                                             :description => AutomatedWorkflows::Kaplan::Csv.config.description,
                                                             :last_external_update => last_updated,
                                                             :initial_stop => AutomatedWorkflows::Kaplan::Csv.config.initial_stop,
                                                             :type =>'directory')
            desc = Endpoint.where(:repo => repo, :source => "#{AutomatedWorkflows::Kaplan::Csv.config.endpoint}/#{directory}/#{AutomatedWorkflows::Kaplan::Csv.config.metadata_suffix}").first_or_create
            desc.update_attributes( :destination => repo.metadata_subdirectory,
                                    :content_type => 'metadata',
                                    :fetch_method => AutomatedWorkflows::Kaplan::Csv.config.metadata_fetch_method,
                                    :protocol => AutomatedWorkflows::Kaplan::Csv.config.metadata_protocol,
                                    :problems => {} )
            desc.save!
            struct = Endpoint.where(:repo => repo, :source => "#{AutomatedWorkflows::Kaplan::Csv.config.endpoint}/#{directory}/#{AutomatedWorkflows::Kaplan::Csv.config.assets_suffix}").first_or_create
            struct.update_attributes( :destination => repo.assets_subdirectory,
                                      :content_type => 'assets',
                                      :fetch_method => AutomatedWorkflows::Kaplan::Csv.config.assets_fetch_method,
                                      :protocol => AutomatedWorkflows::Kaplan::Csv.config.assets_protocol,
                                      :problems => {} )
            struct.save!
            repo.endpoint += [desc, struct]
            AutomatedWorkflows::Agent.verify_sources(repo)
            repo.save!
            directories << directory
          end
          directories
        end

      end

    end
  end
end