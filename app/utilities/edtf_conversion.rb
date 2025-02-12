class EDTFConversion
  attr_reader :original, :edtf

  def initialize(date)
    @original = date
    @edtf = generate_edtf_object(date)
  end

  # Returns human-readable interpretation of EDTF date value. If there isn't a better human-readable
  # interpretation, we return the original value.
  #
  # @return [String]
  def humanize
    case edtf
    when EDTF::Century, EDTF::Decade
      "between #{edtf.min.year} and #{edtf.max.year}"
    when DateTime # Date has time
      edtf.strftime('%Y-%m-%d %T')
    when NilClass
      original
    when Date
      if edtf.year.negative?
        edtf.humanize[1..-1].concat(' B.C.')
      else
        edtf.humanize
      end
    else
      edtf.humanize
    end
  end

  # Returns an array containing all the years represented by the EDTF date value. Returns original value if year
  # could not be extracted.
  #
  # @return [Array]
  def years
    case edtf
    when Date, DateTime, EDTF::Season
      [edtf.year.to_s]
    when EDTF::Century, EDTF::Decade, EDTF::Set
      edtf.to_a.map(&:year).map(&:to_s).uniq
    when EDTF::Interval
      if edtf.unknown? || edtf.open?
        year = edtf.to.is_a?(Date) ? edtf.to.year : edtf.from.year
        Array.wrap(year.to_s)
      else
        edtf.to_a.map(&:year).map(&:to_s).uniq
      end
    else
      [original]
    end
  end

  private

  # Returns EDTF date object.
  #
  # @param [String] date
  # @return [Date, DateTime, EDTF::Interval, EDTF::Set, EDTF::Epoch, EDTF::Season]
  def generate_edtf_object(date)
    # Need to normalize the date to match the EDTF specification used by ruby-edtf
    if date =~ /^\d\d\dX$/ # Custom logic for '100X' dates
      EDTF::Decade.new(date.tr('X', '0').to_i)
    elsif date =~ /^\d\dXX$/ # Custom logic for '10XX' dates
      EDTF::Century.new(date.tr('X', '0').to_i)
    elsif date =~ /^-\d{4,5}$/ # Custom logic to create the appropriate object for negative years.
      Date.new(date.to_i).year_precision!
    else
      edtf_date = date.dup
      edtf_date = "unknown#{edtf_date}" if edtf_date.start_with?('/')
      edtf_date = edtf_date.gsub('..', 'unknown') if edtf_date.start_with?('../')
      edtf_date = "#{edtf_date}unknown" if edtf_date.end_with?('/')
      edtf_date = edtf_date.gsub('..', 'open') if edtf_date.end_with?('/..')

      DateTime.edtf(edtf_date)
    end
  end
end