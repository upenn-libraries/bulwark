module Bulwark
  module HierarchicalCSV
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
      hierarchical_hash = {}
      hash.each do |field, value|
        parse_field(field, value, hierarchical_hash)
      end
      hierarchical_hash
    end

    def self.parse_field(field, value, hash)
      return if value.nil?

      if /\./.match(field)
        parent, child = field.split('.', 2)
        hash[parent] ||= {}
        parse_field(child, value, hash[parent])
      else
        # If header ends in `[1]` it represents a specific location in array, parse out index.
        if (header = /^(?<key>.+)\[(?<index>\d+)\]$/.match(field))
          key = header[:key]
          index = header[:index].to_i - 1 # Array start at zero
          hash[key] ||= []
          hash[key][index] = value
        else
          hash[field] = value
        end
      end
    end
  end
end
