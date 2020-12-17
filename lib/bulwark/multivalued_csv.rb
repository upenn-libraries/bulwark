module Bulwark
  module MultivaluedCSV
    # Parses CSV string and returns an array of hashes. One hash for each row.
    # For each row, values are combined into an array if the column heading is
    # suffixed with an index. For example, if columns are named `task[1]`
    # and `task[2]` the output hash will return both values in an
    # array, ie: `{ 'task' => [value1, value2 ] }`.
    #
    # @param csv_data [String]
    # @return [Array<Hash>]
    def self.parse(csv_data)
      rows = CSV.parse(csv_data, headers: true)

      rows.map do |row|
        values = {}
        row.each do |k, v|
          next if v.blank?
          key = k
          index = nil
          value = v.strip

          # If header ends in `[1]` it represents a specific location in array, parse out index.
          if (header = /^(?<key>.+)\[(?<index>\d+)\]$/.match(k))
            key = header[:key]
            index = header[:index].to_i
          end

          # If there is an index, assume the key should be an array and add the
          # value in the correct index. Otherwise, add the value to the key.
          if index
            values[key] ||= []
            values[key][index] = value
          else
            values[key] = value
          end
        end

        values.map { |k, v| v.compact! if v.is_a?(Array) } # Remove any nil values.
        values
      end
    end

    # Generates CSV string from am array of hash.
    #
    # @param csv_data [Array<Hash>]
    # @return [String] csv formatted string
    def self.generate(csv_data)
      hashes = csv_data.map do |hash|
        expanded_hash = {}
        hash.each do |k, v|
          if v.is_a? Array
            v.each_with_index { |value, i| expanded_hash["#{k}[#{i+1}]"] = value }
          else
            expanded_hash[k] = v
          end
        end
        expanded_hash
      end

      headers = hashes.sum([], &:keys).uniq.sort

      CSV.generate(headers: true) do |csv|
        csv << headers

        hashes.each do |hash|
          row = headers.map { |header| hash[header] }
          csv << row
        end
      end
    end
  end
end
