# frozen_string_literal: true

namespace :bulwark do
  namespace :reports do
    desc 'Report listing all records with MMS IDs'
    task arks_to_bibs: :environment do
      data = []

      Repo.all.find_each do |repo|
        bibnumber = repo&.descriptive_metadata&.original_mappings&.dig('bibnumber', 0)
        data << { mms_id: bibnumber, unique_identifier: repo.unique_identifier } if bibnumber
      end

      filename = File.join(Utils.config[:workspace], "arks-to-bibs-#{Time.current.to_s(:number)}.csv")
      File.write(filename, Bulwark::StructuredCSV.generate(data))

      puts Rainbow("CSV written to #{filename}").green
    end

    desc 'Reports whether or not items with MMS IDs have a Colenda link in the Alma record'
    task check_for_alma_links: :environment do
      # Generate a CSV with the following columns:
      #   - MMS ID
      #   - Ark (unique_identifier)
      #   - Colenda link
      #   - whether or not the Alma record has a link to the record
      #   - the Colenda link the Alma record contains
      # for all published items.

      data = []

      Repo.where(published: true).find_each do |repo|
        bibnumber = repo.descriptive_metadata.original_mappings['bibnumber']&.first

        # Return nil if bibnumber is not present.
        next nil if bibnumber.nil?

        # Fetch MARC record
        retries = 0
        begin
          marc = MarmiteClient.marc21(bibnumber)
        rescue MarmiteClient::Error
          if retries < 3
            retries += 1
            sleep(1)
            retry
          else
            puts Rainbow("Could not find MARC record for #{bibnumber} representing #{repo.unique_identifier}.").red
            next nil
          end
        end

        marc = Nokogiri::XML(marc)
        marc.remove_namespaces!

        # Extract Colenda Links
        online_links = marc.xpath("//records/record/datafield[@tag=856]/subfield[@code='u']").map(&:text)
        online_links.keep_if { |link| link =~ /colenda\.library\.upenn\.edu/ }

        data << {
          mms_id: bibnumber,
          ark: repo.unique_identifier,
          colenda_link: "https://colenda.library.upenn.edu/catalog/#{repo.names.fedora}",
          colenda_link_in_alma_record: online_links,
          has_colenda_link_in_alma_record: !online_links.empty?
        }
      end

      # Write to file
      filename = File.join(Utils.config[:workspace], "colenda-links-in-alma-#{Time.current.to_s(:number)}.csv")
      File.write(filename, Bulwark::StructuredCSV.generate(data))

      puts Rainbow("CSV written to #{filename}").green
    end
  end
end
