# frozen_string_literal: true
namespace :bulwark do
  namespace :kaplan do
    desc 'Export of Kaplan Items'
    task export: :environment do
      query = 'collection_tesim:"Arnold and Deanne Kaplan Collection of Modern American Judaica (University of Pennsylvania)" OR ' \
        'collection_tesim:"Arnold and Deanne Kaplan Collection of Early American Judaica (University of Pennsylvania)" OR ' \
        'provenance_tesim:"Gift of Arnold and Deanne Kaplan"'

      # Get list of unique identifiers from Solr.
      kaplan_unique_ids = Blacklight.default_index.search(
        q: query, fl: 'id,unique_identifier_tesim', rows: 100_000
      ).docs.map { |d| d.fetch('unique_identifier_tesim').first }

      # Compile data.
      data = []
      Repo.where(unique_identifier: kaplan_unique_ids).find_each do |record|
        data << record.to_hash
      end

      # Write to file.
      filename = File.join(Settings.digital_object.workspace_path, "kaplan-export-#{Time.current.to_s(:iso8601)}.csv")
      File.write(filename, Bulwark::StructuredCSV.generate(data))

      puts Rainbow("Kaplan CSV written to #{filename}").green
    end
  end
end
