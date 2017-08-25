require 'smarter_csv'

module AutomatedWorkflows
  module Pap

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
        @owner = ENV['PAP_OWNER'] || AutomatedWorkflows.config['pap']['csv']['owner']
        @description = ENV['PAP_DESCRIPTION'] || AutomatedWorkflows.config['pap']['csv']['description']
        @initial_stop = ENV['PAP_INITIAL_STOP'] || AutomatedWorkflows.config['pap']['csv']['initial_stop']
        @endpoint = ENV['PAP_HARVESTING_ENDPOINT_REMOTE'] || ''
        @metadata_suffix = ENV['PAP_METADATA_SUFFIX'] || AutomatedWorkflows.config['pap']['csv']['metadata_suffix']
        @assets_suffix = ENV['PAP_ASSETS_SUFFIX'] || AutomatedWorkflows.config['pap']['csv']['assets_suffix']
        @metadata_fetch_method = AutomatedWorkflows.config['pap']['csv']['endpoints']['metadata_fetch_method'] || ''
        @metadata_protocol = AutomatedWorkflows.config['pap']['csv']['endpoints']['metadata_protocol'] || ''
        @assets_fetch_method = AutomatedWorkflows.config['pap']['csv']['endpoints']['assets_fetch_method'] || ''
        @assets_protocol = AutomatedWorkflows.config['pap']['csv']['endpoints']['assets_protocol'] || ''
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
          listing.each { |row| directories << "#{row[:path]}|#{row[:updated]}" }
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
            repo = AutomatedWorkflows::Actions::Repos.create(directory,
                                                             :owner => AutomatedWorkflows::Pap::Csv.config.owner,
                                                             :description => AutomatedWorkflows::Pap::Csv.config.description,
                                                             :last_external_update => last_updated,
                                                             :initial_stop => AutomatedWorkflows::Pap::Csv.config.initial_stop,
                                                             :type =>'directory')
            desc = Endpoint.where(:repo => repo, :source => "#{AutomatedWorkflows::Pap::Csv.config.endpoint}/#{directory}/#{AutomatedWorkflows::Pap::Csv.config.metadata_suffix}").first_or_create
            desc.update_attributes( :destination => repo.metadata_subdirectory,
                                    :content_type => 'metadata',
                                    :fetch_method => AutomatedWorkflows::Pap::Csv.config.metadata_fetch_method,
                                    :protocol => AutomatedWorkflows::Pap::Csv.config.metadata_protocol,
                                    :problems => {} )
            desc.save!
            struct = Endpoint.where(:repo => repo, :source => "#{AutomatedWorkflows::Pap::Csv.config.endpoint}/#{directory}/#{AutomatedWorkflows::Pap::Csv.config.assets_suffix}").first_or_create
            struct.update_attributes( :destination => repo.assets_subdirectory,
                                      :content_type => 'assets',
                                      :fetch_method => AutomatedWorkflows::Pap::Csv.config.assets_fetch_method,
                                      :protocol => AutomatedWorkflows::Pap::Csv.config.assets_protocol,
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