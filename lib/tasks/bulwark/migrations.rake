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
      limit = ENV['limit'].present? ? ENV['limit'].to_i : nil

      kaplan_style_items = Repo.where(ingested: true).select do |r|
        types = r.metadata_builder.metadata_source.map(&:source_type)
        types.count == 2 && types.include?('kaplan_structural') && types.include?('kaplan')
      end

      kaplan_style_items = kaplan_style_items.first(limit) if limit

      hashes = kaplan_style_items.map do |r|
        descriptive = r.metadata_builder.metadata_source.where(source_type: 'kaplan').first.original_mappings
        structural = r.metadata_builder.metadata_source.where(source_type: 'kaplan_structural').first.user_defined_mappings

        filenames = []
        structural.each { |key, value| filenames[key] = value['file_name'] }

        {
          'unique_identifier' => r.unique_identifier,
          'action' => 'MIGRATE',
          'metadata' => descriptive,
          'structural' => { 'filenames' => filenames.compact.join('; ') }
        }
      end

      csv_data = Bulwark::StructuredCSV.generate(hashes)

      # Write to CSV
      filename = File.join("/fs/priv/workspace/migration_csvs/kaplan-export-#{Time.current.to_s(:number)}.csv")
      File.write(filename, csv_data)
    end

    # Cleanup tasks for Kaplan items
    task kaplan_cleanup: :environment do
      output = ENV['output']
      filepath = ENV['file']
      if filepath.present? && output.present?
        contents = File.open(filepath, 'r:UTF-8')
        data = Bulwark::StructuredCSV.parse(contents).map do |item|
          metadata = item['metadata']

          # Combine identifiers and remove identifiers that are no longer needed.
          identifiers = metadata.fetch('identifier', []) + metadata.fetch('Object Refno', []) + metadata.fetch('Collectify Identifier(s)', []) + metadata.fetch('UUID', [])

          metadata.delete('identifier')
          metadata.delete('Object Refno')
          metadata.delete('Collectify Identifier(s)')
          metadata.delete('UUID')

          identifiers = identifiers.compact.uniq
          identifiers.delete_if { |i| /^ref|^cid|^\d{2}\..+/ =~ i }

          metadata['identifier'] = identifiers

          # Combine descriptions
          unless metadata['description'].nil?
            description = metadata.delete('description')
            metadata['description'] = description.join('; ')
          end

          item['metadata'] = metadata
          item
        end

        File.open(output, 'w:UTF-8') do |f|
          f.write Bulwark::StructuredCSV.generate(data)
        end

      else
        puts Rainbow('File and output required').red
      end
    end

    # Splits csv into two CSVs, one for Kaplan items and one for non-Kaplan items.
    task split_csv: :environment do
      filepath = ENV['file']

      if filepath
        filepath = File.expand_path(filepath)
        contents = File.open(filepath, 'r:UTF-8')

        kaplan_material = []
        other_material = []

        Bulwark::StructuredCSV.parse(contents).each do |item|
          metadata = item['metadata']
          kaplan = metadata.fetch('collection', []).include?('Arnold and Deanne Kaplan Collection of Modern American Judaica (University of Pennsylvania)') ||
                   metadata.fetch('collection', []).include?('Arnold and Deanne Kaplan Collection of Early American Judaica (University of Pennsylvania)') ||
                   metadata.fetch('provenance', []).include?('Gift of Arnold and Deanne Kaplan')

          if kaplan
            kaplan_material << item
          else
            other_material << item
          end
        end

        # Output to Kaplan file.
        kaplan_filepath = File.join(File.dirname(filepath), 'kaplan_material.csv')
        File.open(kaplan_filepath, 'w:UTF-8') do |f|
          f.write Bulwark::StructuredCSV.generate(kaplan_material)
        end

        # Output to other file
        other_filepath = File.join(File.dirname(filepath), 'other_material.csv')
        File.open(other_filepath, 'w:UTF-8') do |f|
          f.write Bulwark::StructuredCSV.generate(other_material)
        end
      else
        puts Rainbow('File required').red
      end
    end
  end
end
