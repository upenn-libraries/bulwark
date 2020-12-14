# frozen_string_literal: true

module Bulwark
  module PennQualifiedCore
    module TransformMarc
      # Converts marc xml (provided by Marmite) to PQC fields.
      # TODO: This should be broken up in smaller methods. This mapping will
      # probably change, so I'll save the refactoring for when I know what those
      # changes are.
      def self.from_marc_xml(marc_xml)
        data = Nokogiri::XML(marc_xml)
        data.remove_namespaces!

        mapped_values = {}

        data.xpath('//records/record/datafield').each do |element|
          tag = element.attributes['tag'].value
          next unless MarcMappings::TAGS[tag].present?

          if MarcMappings::TAGS[tag]['*'].present? # selecting all fields under the given tag
            header = pqc_field(tag, '*')
            mapped_values[header] ||= []
            values = element.children.map(&:text).delete_if { |v| v.strip.empty? }

            # Joining fields with a configured seperator and appending, otherwise concating values to array.
            if MarcMappings::ROLLUP_FIELDS[tag].present?
              seperator = MarcMappings::ROLLUP_FIELDS[tag]['separator']
              mapped_values[header].push(values.join(seperator))
            else
              mapped_values[header].concat(values)
            end
          else
            # if not selecting all
            if MarcMappings::ROLLUP_FIELDS[tag].present?
              rollup_values = []
              header = ''
              element.xpath('subfield').each do |subfield|
                # FIXME: If the headers are different for a field that rolls up, there are going to be problems.
                header = pqc_field(tag, subfield.attributes['code'].value)
                if header.present?
                  mapped_values[header] ||= []
                  values = subfield.children.map(&:text).delete_if { |v| v.strip.empty? }
                  rollup_values.concat(values)
                end
              end
              mapped_values[header] << rollup_values.join(MarcMappings::ROLLUP_FIELDS[tag]['separator']) if rollup_values
            else
              element.xpath('subfield').each do |subfield|
                header = pqc_field(tag, subfield.attributes['code'].value)
                if header.present?
                  mapped_values[header] ||= []
                  mapped_values[header].concat(subfield.children.map(&:text))
                end
              end
            end
          end
        end

        bibnumber = data.at_xpath('//records/record/controlfield[@tag=001]').text
        mapped_values['identifier'] ||= ["#{Utils.config[:repository_prefix]}_#{bibnumber}"]
        mapped_values['display_call_number'] = data.xpath('//records/record/holdings/holding/call_number')
                                                   .map(&:text)
                                                   .compact
        # Cleanup
        mapped_values.transform_values! { |values| values.map(&:strip).reject(&:empty?) }

        # Join fields if they aren't multivalued.
        mapped_values.each do |k, v|
          next if MarcMappings::MULTIVALUED_FIELDS.include?(k)
          mapped_values[k] = [v.join(' ')]
        end

        mapped_values
      end

      def self.pqc_field(marc_field, code = '*')
        MarcMappings::TAGS[marc_field][code]
      end
    end
  end
end
