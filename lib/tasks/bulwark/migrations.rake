# frozen_string_literal: true

namespace :bulwark do
  namespace :migrations do
    desc 'Retrieving thumbnail_location from Fedora and storing it in the database'
    task add_thumbnail_location: :environment do
      Repo.find_each do |repo|
        begin
          fedora_object = ActiveFedora::Base.find(repo.names.fedora)
          if (url = fedora_object.thumbnail.ldp_source.head.headers['Content-Type'].match(/url="(?<url>[^"]*)"/)[:url])
            repo.thumbnail_location = Addressable::URI.parse(url).path # Removing host and scheme
            repo.save!
          else
            puts Rainbow("Was not able to update thumbnail location for #{repo.id}. URL not found in expected location.").red
          end
        rescue => e
          puts Rainbow("Was not able to update thumbnail_location for #{repo.id}. Error: #{e.message}").red
        end
      end
    end

    desc 'Export of "Kaplan-style" objects'
    task export_kaplan_style_items: :environment do
      # Param to limit the number of results returned.
      limit = ENV['limit'].present? ? ENV['limit'] : nil

      kaplan_style_items = Repo.where(ingested: true).select do |r|
        types = r.metadata_builder.metadata_source.map(&:source_type)
        types.count == 2 && types.include?('kaplan_structural') && types.include?('kaplan')
      end

      kaplan_style_items = kaplan_style_items.first(limit) if limit

      hashes = kaplan_style_items.map do |r|
        descriptive = r.metadata_builder.metadata_source.where(source_type: 'kaplan').first.original_mappings
        structural = r.metadata_builder.metadata_source.where(source_type: 'kaplan_structural').first.user_defined_mappings

        metadata = descriptive.transform_keys { |k| k.downcase.tr(' ', '_') }
        filenames = []
        structural.each { |key, value| filenames[key] = value['file_name'] }

        {
          'unique_identifier' => r.unique_identifier,
          'action' => 'MIGRATE',
          'metadata' => metadata,
          'structural' => { 'filenames' => filenames.compact.join('; ') }
        }
      end

      csv_data = Bulwark::StructuredCSV.generate(hashes)

      # Write to CSV
      filename = File.join("/fs/priv/workspace/migration_csvs/kaplan-export-#{Time.current.to_s(:number)}.csv")
      File.write(filename, csv_data)
    end
  end
end
