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
      attr_accessor :metadata_fetch_method
      attr_accessor :metadata_protocol
      attr_accessor :assets_fetch_method
      attr_accessor :assets_protocol


      def initialize
        @owner = ENV['OPENN_OWNER'] || AutomatedWorkflows.config['openn']['csv']['owner']
        @description = ENV['OPENN_DESCRIPTION'] || AutomatedWorkflows.config['openn']['csv']['description']
        @initial_stop = ENV['OPENN_INITIAL_STOP'] || AutomatedWorkflows.config['openn']['csv']['initial_stop']
        @endpoint = ENV['OPENN_HARVESTING_ENDPOINT_REMOTE'] || ''
        @metadata_suffix = ENV['OPENN_METADATA_SUFFIX'] || AutomatedWorkflows.config['openn']['csv']['metadata_suffix']
        @assets_suffix = ENV['OPENN_ASSETS_SUFFIX'] || AutomatedWorkflows.config['openn']['csv']['assets_suffix']
        @metadata_fetch_method = AutomatedWorkflows.config['openn']['csv']['endpoints']['metadata_fetch_method'] || ''
        @metadata_protocol = AutomatedWorkflows.config['openn']['csv']['endpoints']['metadata_protocol'] || ''
        @assets_fetch_method = AutomatedWorkflows.config['openn']['csv']['endpoints']['assets_fetch_method'] || ''
        @assets_protocol = AutomatedWorkflows.config['openn']['csv']['endpoints']['assets_protocol'] || ''
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
          identifiers = []
          file_lines.each do |dir|
            directory = dir.split('|').first
            last_updated = dir.split('|').last
            repo = AutomatedWorkflows::Actions::Repos.create(directory,
                                                             :owner => AutomatedWorkflows::OPenn::Csv.config.owner,
                                                             :description => AutomatedWorkflows::OPenn::Csv.config.description,
                                                             :last_external_update => last_updated,
                                                             :initial_stop => AutomatedWorkflows::OPenn::Csv.config.initial_stop,
                                                             :type =>'directory')
            desc = Endpoint.where(:repo => repo, :source => "#{AutomatedWorkflows::OPenn::Csv.config.endpoint}/#{directory}/#{AutomatedWorkflows::OPenn::Csv.config.metadata_suffix}").first_or_create
            desc.update_attributes( :destination => repo.metadata_subdirectory,
                                    :content_type => 'metadata',
                                    :fetch_method => AutomatedWorkflows::OPenn::Csv.config.metadata_fetch_method,
                                    :protocol => AutomatedWorkflows::OPenn::Csv.config.metadata_protocol,
                                    :problems => {} )
            desc.save!
            struct = Endpoint.where(:repo => repo, :source => "#{AutomatedWorkflows::OPenn::Csv.config.endpoint}/#{directory}/#{AutomatedWorkflows::OPenn::Csv.config.assets_suffix}").first_or_create
            struct.update_attributes( :destination => repo.assets_subdirectory,
                                      :content_type => 'assets',
                                      :fetch_method => AutomatedWorkflows::OPenn::Csv.config.assets_fetch_method,
                                      :protocol => AutomatedWorkflows::OPenn::Csv.config.assets_protocol,
                                      :problems => {} )
            struct.save!
            repo.endpoint += [desc, struct]
            AutomatedWorkflows::Agent.verify_sources(repo)
            repo.save!
            identifiers << repo.unique_identifier
          end
          identifiers
        end

      end

    end
  end
end