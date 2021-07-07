module Bulwark
  # A Structured CSV offers the ability to namespace headers in the csv and
  # allow for fields to have array or string values.
  module StructuredCSV
    # Parses CSV string and returns an array of hashes. One hash for each row.
    # For each row, values are combined into an array if the column heading is
    # suffixed with an index. For example, if columns are named `task[1]`
    # and `task[2]` the output hash will return both values in an
    # array, ie: `{ 'task' => [value1, value2] }`. Additionally, values can be
    # nested within hashes when the header names contain words seperated
    # by `.`. For example, a header with the value `structural.files.number` will
    # be returned as `{ 'structural' => { 'files' => { 'number' => value } } }`.
    #
    # @param csv_data [String]
    # @return [Array<Hash>]
    def self.parse(csv_data)
      rows = CSV.parse(csv_data, headers: true)
      rows.map { |row| parse_row(row) }
    end

    def self.parse_row(hash)
      structured_hash = {}
      hash.each do |field, value|
        parse_field(field, value, structured_hash)
      end
      structured_hash
    end

    def self.parse_field(field, value, hash)
      if /\A[^\[\]]+\./.match(field) # if matches field.second_field
        parent, child = field.split('.', 2)
        hash[parent] ||= {}
        parse_field(child, value, hash[parent])
      elsif (header = /\A(?<key>.+?)\[(?<index>\d+)\](?<rest>\.(?<child>.+))?/.match(field)) # if matches field[1].second_field or field[1]
        key = header[:key]
        index = header[:index].to_i - 1 # Array start at zero
        hash[key] ||= []

        return if value.nil?

        if header[:child] # if matches field[1].second_field
          hash[key][index] ||= {}
          parse_field(header[:child], value, hash[key][index])
        else # if matches field[1]
          hash[key][index] = value
        end
      else
        hash[field] = value unless value.nil?
      end
    rescue IndexError => e
      raise "Error parsing field '#{field}': #{e.message}"
    end

    # Generates CSV string from an array of hash.
    #
    # @param csv_data [Array<Hash>]
    # @return [String] csv formatted string
    def self.generate(csv_data)
      csv_data = csv_data.map(&:deep_stringify_keys) # Ensure all keys are strings.

      hashes = csv_data.map { |hash| generate_row(hash) }

      headers = hashes.sum([], &:keys).uniq.sort

      CSV.generate(headers: true) do |csv|
        csv << headers

        hashes.each do |hash|
          row = headers.map { |header| hash[header] }
          csv << row
        end
      end
    end

    def self.generate_row(original_hash)
      expanded_hash = {}
      original_hash.each do |k, v|
        generate_field(k, v, expanded_hash)
      end
      expanded_hash
    end

    def self.generate_field(field, value, hash)
      if value.is_a? Hash
        value.each do |k, v|
          generate_field("#{field}.#{k}", v, hash)
        end
      elsif value.is_a? Array
        value.each_with_index do |v, i|
          generate_field("#{field}[#{i + 1}]", v, hash)
        end
      else
        hash[field] = value
      end
    end
  end
end
