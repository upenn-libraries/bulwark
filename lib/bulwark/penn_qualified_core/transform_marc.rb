# frozen_string_literal: true

module Bulwark
  module PennQualifiedCore
    module TransformMarc
      # Converts marc xml (provided by Marmite) to PQC fields.
      def self.from_marc_xml(marc_xml)
        data = Nokogiri::XML(marc_xml)
        data.remove_namespaces!

        mapped_values = {}

        # Map control fields
        data.xpath('//records/record/controlfield').each do |element|
          tag = element.attributes['tag'].value
          mapping_config = MarcMappings::CONTROL_FIELDS[tag]

          next unless mapping_config.present?

          Array.wrap(mapping_config).each do |config|
            field = config[:field]

            mapped_values[field] ||= []

            text = element.text
            text = config[:chars].map { |i| text.slice(i) }.join if config[:chars]

            mapped_values[field].push(text)
          end
        end

        # Map MARC fields
        data.xpath('//records/record/datafield').each do |element|
          tag = element.attributes['tag'].value
          mapping_config = MarcMappings::MARC_FIELDS[tag]

          next unless mapping_config.present?

          Array.wrap(mapping_config).each do |config|
            field = config[:field]
            selected_subfields = Array.wrap(config[:subfields])

            mapped_values[field] ||= []

            values = element.xpath('subfield')
            values = values.select { |s| selected_subfields.include?(s.attributes['code'].value) } if selected_subfields.first != '*'
            values = values.map { |v| v&.text&.strip }.delete_if(&:blank?)

            if (delimeter = config[:join])
              mapped_values[field].push values.join(delimeter)
            else
              mapped_values[field].concat values
            end
          end
        end

        # Adding item_type when conditions are met
        if manuscript?(data)
          mapped_values['item_type'] = ['Manuscripts']
        elsif book?(data)
          mapped_values['item_type'] = ['Books']
        end

        # Converting language codes to english name.
        languages = mapped_values.fetch('language', [])
        mapped_values['language'] = languages.map { |l| ISO_639.find_by_code(l)&.english_name }.compact

        # Adding call number
        mapped_values['call_number'] = data.xpath('//records/record/holdings/holding/call_number')
                                           .map(&:text)
                                           .compact

        # Removing duplicate values from selected fields.
        %w[subject corporate_name personal_name language].each { |f| mapped_values[f]&.uniq! }

        # Cleanup
        mapped_values.transform_values! { |values| values.map(&:strip).reject(&:blank?) }
                     .delete_if { |_, v| v.blank? }

        # Join fields if they aren't multivalued.
        mapped_values.each do |k, v|
          next if MarcMappings::MULTIVALUED_FIELDS.include?(k)
          mapped_values[k] = [v.join(' ')]
        end

        mapped_values
      rescue => e
        raise StandardError, "Error mapping MARC XML to PQC: #{e.class} #{e.message}", e.backtrace
      end

      # Returns true if the MARC data describes the item as a Manuscript
      def self.manuscript?(data)
        manuscript = false

        # Checking for values in field 040 subfield e
        subfield_e = data.xpath("//records/record/datafield[@tag=040]/subfield[@code='e']").map(&:text)
        manuscript = true if subfield_e.any? { |s| ["appm", "appm2", "amremm", "dacs", "dcrmmss"].include? s.downcase }

        # Checking for value in all subfield of field 040
        all_subfields = data.xpath("//records/record/datafield[@tag=040]/subfield").map(&:text)
        manuscript = true if all_subfields.any? { |s| s.casecmp('paulm').zero? }

        manuscript
      end

      # Returns true if the MARC data describes the item as a Book
      def self.book?(data)
        # Checking for `a` in 7th value of the leader field
        leader = data.at_xpath("//records/record/leader")&.text
        return if leader.blank?
        leader[6] == 'a'
      end
    end
  end
end
