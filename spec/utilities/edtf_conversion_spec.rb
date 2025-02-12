# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EDTFConversion do
  describe '.humanize' do
    subject(:date) { EDTFConversion.new(value).humanize }

    context 'with a single year, month and day' do
      let(:value) { '1985-04-12' }

      it { is_expected.to eql value }
    end

    context 'with a single year and month' do
      let(:value) { '1985-04' }

      it { is_expected.to eql value }
    end

    context 'with a single year' do
      let(:value) { '1985' }

      it { is_expected.to eql value }
    end

    context 'with single date range' do
      let(:value) { '1994-01-06/2004-01-06' }

      it { is_expected.to eql '1994-01-06 to 2004-01-06'}
    end

    context 'with an open-ended date range (open end)' do
      let(:value) { '1994-01-06/..' }

      it { is_expected.to eql '1994-01-06 to unknown date'}
    end

    context 'with an open-ended date range (open start)' do
      let(:value) { '../1994-01-06' }

      it { is_expected.to eql 'unknown date to 1994-01-06' }
    end

    context 'with a date range with an unknown end' do
      let(:value) { '2004-01-06/' }

      it { is_expected.to eql '2004-01-06 to unknown date' }
    end

    context 'with a date range with an unknown start' do
      let(:value) { '/2004-01-06' }

      it { is_expected.to eql 'unknown date to 2004-01-06'}
    end

    context 'with an approximate date' do
      let(:value) { '1852-05-14~' }

      it { is_expected.to eql 'circa 1852-05-14' }
    end

    context 'with an approximate range of dates' do
      let(:value) { '1512-03-01~/1512-04-01~' }

      it { is_expected.to eql 'circa 1512-03-01 to circa 1512-04-01' }
    end

    context 'with an uncertain date' do
      let(:value) { '1623-09-19?' }

      it { is_expected.to eql 'possibly 1623-09-19' }
    end

    context 'with an uncertain range of dates' do
      let(:value) { '1788-02-01?/1788-02-28?' }

      it { is_expected.to eql 'possibly 1788-02-01 to possibly 1788-02-28' }
    end

    context 'with an approximate and uncertain date' do
      let(:value) { '2004-07-08%' }

      it { is_expected.to eql 'circa possibly 2004-07-08' }
    end

    context 'with a known decade' do
      let(:value) { '192X' }

      it { is_expected.to eql 'between 1920 and 1929' }
    end

    context 'with a known century' do
      let(:value) { '19XX' }

      it { is_expected.to eql 'between 1900 and 1999' }
    end

    context 'with a specific date with an unknown day' do
      let(:value) { '1922-10-XX' }

      it { is_expected.to eql value }
    end

    context 'with a year within a known set' do
      let(:value) { '[1667,1670,1672]' }

      it { is_expected.to eql '1667, 1670 or 1672' }
    end

    context 'with a month or day within a known set' do
      let(:value) { '[1960-12,1961-12]' }

      it { is_expected.to eql '1960-12 or 1961-12' }
    end

    context 'with a single date within a known range' do
      let(:value) { '[1701..1703]' }

      it { is_expected.to eql 'unknown date between 1701 and 1703' }
    end

    context 'with a single date during or after a known date' do
      let(:value) { '[1701..]' }

      it { is_expected.to eql 'unknown date during or after 1701' }
    end

    context 'with a single date before or during a known date' do
      let(:value) { '[..1703]' }

      it { is_expected.to eql 'unknown date before or during 1703' }
    end

    context 'with multiple years that are not part of a range' do
      let(:value) { '{1667,1670,1672}' }

      it { is_expected.to eql '1667, 1670 and 1672' }
    end

    context 'with multiple months or dates that are not part of a range' do
      let(:value) { '{1960-12,1961-12}' }

      it { is_expected.to eql '1960-12 and 1961-12' }
    end

    context 'with multiple dates and date ranges' do
      let(:value) { '{1701..1702,1705}' }

      it { is_expected.to eql '1701, 1702 and 1705' }
    end

    context 'with a "B.C." date with 4 digits' do
      let(:value) { '-0601' }

      it { is_expected.to eql '601 B.C.' }
    end

    context 'with a "B.C." date with 5 digits' do
      let(:value) { '-50000' }

      it { is_expected.to eql '50000 B.C.' }
    end

    context 'with a known time of year' do
      context 'when spring' do
        let(:value) { '1994-21' }

        it { is_expected.to eql 'Spring 1994' }
      end

      context 'when summer' do
        let(:value) { '1986-22' }

        it { is_expected.to eql 'Summer 1986' }
      end

      context 'when fall' do
        let(:value) { '1902-23' }

        it { is_expected.to eql 'Fall 1902' }
      end

      context 'when winter' do
        let(:value) { '1867-24' }

        it { is_expected.to eql 'Winter 1867' }
      end
    end

    context 'with a single calendar date and (local) time of day' do
      let(:value) { '1985-04-12T23:20:30' }

      it { is_expected.to eql '1985-04-12 23:20:30' }
    end
  end

  describe '.years' do
    subject(:years) { EDTFConversion.new(value).years }

    context 'with a single year, month and day' do
      let(:value) { '1985-04-12' }

      it { is_expected.to contain_exactly('1985') }
    end

    context 'with a single year and month' do
      let(:value) { '1985-04' }

      it { is_expected.to contain_exactly('1985') }
    end

    context 'with a single year' do
      let(:value) { '1985' }

      it { is_expected.to contain_exactly(value) }
    end

    context 'with single date range' do
      let(:value) { '1994-01-06/2004-01-06' }

      it { is_expected.to match_array((1994..2004).map(&:to_s)) }
    end

    context 'with an open-ended date range (open end)' do
      let(:value) { '1994-01-06/..' }

      it { is_expected.to contain_exactly('1994') }
    end

    context 'with an open-ended date range (open start)' do
      let(:value) { '../1994-01-06' }

      it { is_expected.to contain_exactly('1994') }
    end

    context 'with a date range with an unknown end' do
      let(:value) { '2004-01-06/' }

      it { is_expected.to contain_exactly('2004') }
    end

    context 'with a date range with an unknown start' do
      let(:value) { '/2004-01-06' }

      it { is_expected.to contain_exactly('2004') }
    end

    context 'with an approximate date' do
      let(:value) { '1852-05-14~' }

      it { is_expected.to contain_exactly('1852') }
    end

    context 'with an approximate range of dates' do
      let(:value) { '1512-03-01~/1512-04-01~' }

      it { is_expected.to contain_exactly('1512') }
    end

    context 'with an uncertain date' do
      let(:value) { '1623-09-19?' }

      it { is_expected.to contain_exactly('1623') }
    end

    context 'with an uncertain range of dates' do
      let(:value) { '1788-02-01?/1788-02-28?' }

      it { is_expected.to contain_exactly('1788') }
    end

    context 'with an approximate and uncertain date' do
      let(:value) { '2004-07-08%' }

      it { is_expected.to contain_exactly('2004') }
    end

    context 'with a known decade' do
      let(:value) { '192X' }

      it { is_expected.to match_array((1920..1929).map(&:to_s)) }
    end

    context 'with a known century' do
      let(:value) { '19XX' }

      it { is_expected.to match_array((1900..1999).map(&:to_s)) }
    end

    context 'with a specific date with an unknown day' do
      let(:value) { '1922-10-XX' }

      it { is_expected.to contain_exactly('1922') }
    end

    context 'with a year within a known set' do
      let(:value) { '[1667,1670,1672]' }

      it { is_expected.to contain_exactly('1667', '1670', '1672') }
    end

    context 'with a month or day within a known set' do
      let(:value) { '[1960-12,1961-12]' }

      it { is_expected.to contain_exactly('1960', '1961') }
    end

    context 'with a single date within a known range' do
      let(:value) { '[1701..1703]' }

      it { is_expected.to contain_exactly('1701', '1702', '1703') }
    end

    context 'with a single date during or after a known date' do
      let(:value) { '[1701..]' }

      it { is_expected.to contain_exactly('1701') }
    end

    context 'with a single date before or during a known date' do
      let(:value) { '[..1703]' }

      it { is_expected.to contain_exactly '1703' }
    end

    context 'with multiple years that are not part of a range' do
      let(:value) { '{1667,1670,1672}' }

      it { is_expected.to contain_exactly('1667', '1670', '1672') }
    end

    context 'with multiple months or dates that are not part of a range' do
      let(:value) { '{1960-12,1961-12}' }

      it { is_expected.to contain_exactly('1960', '1961') }
    end

    context 'with multiple dates and date ranges' do
      let(:value) { '{1701..1702,1705}' }

      it { is_expected.to contain_exactly('1701', '1702', '1705') }
    end

    context 'with a "B.C." date with 4 digits' do
      let(:value) { '-0601' }

      it { is_expected.to contain_exactly('-601') }
    end

    context 'with a "B.C." date with 5 digits' do
      let(:value) { '-50000' }

      it { is_expected.to contain_exactly('-50000') }
    end

    context 'with a known time of year' do
      context 'when spring' do
        let(:value) { '1994-21' }

        it { is_expected.to contain_exactly('1994') }
      end

      context 'when summer' do
        let(:value) { '1986-22' }

        it { is_expected.to contain_exactly('1986') }
      end

      context 'when fall' do
        let(:value) { '1902-23' }

        it { is_expected.to contain_exactly('1902') }
      end

      context 'when winter' do
        let(:value) { '1867-24' }

        it { is_expected.to contain_exactly('1867') }
      end
    end

    context 'with a single calendar date and (local) time of day' do
      let(:value) { '1985-04-12T23:20:30' }

      it { is_expected.to contain_exactly('1985') }
    end
  end
end
