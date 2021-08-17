# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Bulwark::Import::StructuralMetadataGenerator do
  describe '#valid?' do
    context 'when structural drive is provided without path' do
      subject(:generator) { described_class.new(drive: 'test') }

      it 'adds error' do
        expect(generator.valid?).to be false
        expect(generator.errors).to include 'structural drive and path must both be provided'
      end
    end

    context 'when structural path is provided without drive' do
      subject(:generator) { described_class.new(path: 'to/file.jpeg') }

      it 'adds error' do
        expect(generator.valid?).to be false
        expect(generator.errors).to include 'structural drive and path must both be provided'
      end
    end

    context 'when structural filenames and file are provided' do
      subject(:generator) { described_class.new(filenames: 'something', path: 'something', drive: 'test') }

      it 'adds error' do
        expect(generator.valid?).to be false
        expect(generator.errors).to include 'structural metadata cannot be provided multiple ways'
      end
    end

    context 'when structural filenames and bibnumber are provided' do
      subject(:generator) { described_class.new(filenames: 'something', bibnumber: '1234567890') }

      it 'adds error' do
        expect(generator.valid?).to be false
        expect(generator.errors).to include 'structural metadata cannot be provided multiple ways'
      end
    end

    context 'when structural filenames and sequence are provided' do
      subject(:generator) { described_class.new(filenames: 'something', sequence: [{ filename: 'first.tiff' }]) }

      it 'adds error' do
        expect(generator.valid?).to be false
        expect(generator.errors).to include 'structural metadata cannot be provided multiple ways'
      end
    end

    context 'when structural file and bibnumber are provided' do
      subject(:generator) { described_class.new(drive: 'test', path: 'something', bibnumber: '1234567890') }

      it 'adds error' do
        expect(generator.valid?).to be false
        expect(generator.errors).to include 'structural metadata cannot be provided multiple ways'
      end
    end

    context 'when structural viewing_direction is provided without filenames' do
      subject(:generator) { described_class.new(viewing_direction: 'top-to-bottom', bibnumber: '1234567890') }

      it 'adds error' do
        expect(generator.valid?).to be false
        expect(generator.errors).to include 'structural viewing_direction cannot be provided without filenames or sequence'
      end
    end

    context 'when structural display is provided without filenames' do
      subject(:generator) { described_class.new(display: 'paged', bibnumber: '1234567890') }

      it 'adds error' do
        expect(generator.valid?).to be false
        expect(generator.errors).to include 'structural display cannot be provided without filenames or sequence'
      end
    end

    context 'when structural drive is invalid' do
      subject(:generator) { described_class.new(drive: 'invalid') }

      it 'adds error' do
        expect(generator.valid?).to be false
        expect(generator.errors).to include 'structural drive invalid'
      end
    end

    context 'when structural viewing_direction is invalid' do
      subject(:generator) { described_class.new(viewing_direction: 'invalid') }

      it 'adds error' do
        expect(generator.valid?).to be false
        expect(generator.errors).to include 'structural viewing direction is not valid'
      end
    end

    context 'when structural display is invalid' do
      subject(:generator) { described_class.new(display: 'invalid') }

      it 'adds error' do
        expect(generator.valid?).to be false
        expect(generator.errors).to include 'structural display is not valid'
      end
    end

    context 'when sequence is provided with a missing filename' do
      subject(:generator) { described_class.new(filenames: 'something', sequence: [{ filename: 'first.tiff' }, { label: 'Second file' }]) }

      it 'adds error' do
        expect(generator.valid?).to be false
        expect(generator.errors).to include 'structural sequence must contain filename for every file in sequence'
      end
    end
  end

  describe '#extract_metadata' do
    context 'when extracting data with bibnumber' do
      let(:generator) { described_class.new(bibnumber: '1234567890') }

      it 'calls from_bibnumber' do
        expect(generator).to receive(:from_bibnumber).with('1234567890')
        generator.extract_metadata
      end
    end

    context 'when extracting data from file' do
      let(:generator) { described_class.new(drive: 'test', path: 'to/file.csv') }

      it 'calls from_file' do
        expect(generator).to receive(:from_file).with(File.join(Bulwark::Import::MountedDrives.path_to('test'), 'to/file.csv'))
        generator.extract_metadata
      end
    end

    context 'when extracting data from filenames' do
      let(:generator) { described_class.new(filenames: 'something.tif', viewing_direction: 'right-to-left') }

      it 'calls from_ordered_filenames' do
        expect(generator).to receive(:from_ordered_filenames).with('something.tif', nil, 'right-to-left')
        generator.extract_metadata
      end
    end

    context 'when extracting data from sequence' do
      let(:generator) { described_class.new(sequence: sequence) }

      let(:sequence) do
        [
          { filename: 'first.tif', label: 'First', table_of_contents: ['First Illuminated Image', 'Second Illuminated Image'] },
          { filename: 'second.tif', label: 'Second' },
          { filename: 'third.tif', label: 'Third' }
        ]
      end

      it 'calls from_sequence' do
        expect(generator).to receive(:from_sequence).with(sequence, nil, nil)
        generator.extract_metadata
      end
    end
  end

  describe '#csv' do
    context 'when generating csv with filenames' do
      let(:filenames) { 'first.tif; second.tif; thrid.tif' }
      let(:generator) { described_class.new(filenames: filenames, viewing_direction: 'right-to-left') }
      let(:expected_csv) do
        <<~CSV
          filename,sequence,viewing_direction
          first.tif,1,right-to-left
          second.tif,2,right-to-left
          thrid.tif,3,right-to-left
        CSV
      end

      it 'generates expected csv' do
        expect(generator.csv).to eql expected_csv
      end
    end

    context 'when generating csv with sequence' do
      let(:generator) { described_class.new(sequence: sequence) }

      let(:sequence) do
        [
          { filename: 'first.tif', label: 'First', table_of_contents: ['First Illuminated Image', 'Second Illuminated Image'] },
          { filename: 'second.tif', label: 'Second' },
          { filename: 'third.tif', label: 'Third' }
        ]
      end
      let(:expected_csv) do
        <<~CSV
          filename,label,sequence,table_of_contents[1],table_of_contents[2]
          first.tif,First,1,First Illuminated Image,Second Illuminated Image
          second.tif,Second,2,,
          third.tif,Third,3,,
        CSV
      end

      it 'generates expected csv' do
        expect(generator.csv).to eql expected_csv
      end
    end
  end

  describe '#all_filenames' do
    context 'when providing sequence' do
      let(:generator) { described_class.new(sequence: [{ filename: 'other.tif' }, { filename: 'this.tif' }]) }
      it 'returns all filenames' do
        expect(generator.all_filenames).to eql ['other.tif', 'this.tif']
      end
    end

    context 'when providing list of filenames' do
      let(:generator) { described_class.new(filenames: 'first.tif;second.tif;third.tif') }

      it 'returns all filenames' do
        expect(generator.all_filenames).to eql ['first.tif', 'second.tif', 'third.tif']
      end
    end
  end

  describe '#from_bibnumber' do
    let(:bibnumber) { '6092756' }
    let(:generator) { described_class.new }

    context 'when invalid bibnumber' do
      before do
        stub_request(:get, "https://marmite.library.upenn.edu:9292/api/v2/records/99#{bibnumber}3503681/marc21?update=always")
          .to_return(status: 404, body: "Record #{bibnumber} in marc21 format not found", headers: {})
      end

      it 'raises error' do
        expect { generator.send(:from_bibnumber, bibnumber) }.to raise_error MarmiteClient::Error
      end
    end

    context 'when valid bibnumber' do
      before do
        # Mock structural metadata request to Marmite
        stub_request(:get, "https://marmite.library.upenn.edu:9292/records/#{bibnumber}/create?format=structural").to_return(status: 302)
        stub_request(:get, "https://marmite.library.upenn.edu:9292/records/#{bibnumber}/show?format=structural")
          .to_return(status: 200, body: fixture_to_str('marmite', 'structural', "with_table_of_contents.xml"), headers: {})

        # Mock descriptive metadata request to Marmite
        stub_request(:get, "https://marmite.library.upenn.edu:9292/api/v2/records/99#{bibnumber}3503681/marc21?update=always")
          .to_return(status: 200, body: descriptive_metadata, headers: {})
      end

      context 'when descriptive metadata does not contain reading direction' do
        let(:descriptive_metadata) do
          <<~METADATA
            <marc:records xmlns:marc="http://www.loc.gov/MARC21/slim" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.loc.gov/MARC21/slim http://www.loc.gov/standards/marcxml/schema/MARC21slim.xsd">
              <marc:record></marc:record>
            </marc:records>
          METADATA
        end

        let(:expected_data) do
          [
            { display: 'paged', filename: 'ljs501_wk1_front0001.tif', label: 'Front cover', sequence: 1, table_of_contents: [], viewing_direction: 'left-to-right' },
            { display: 'paged', filename: 'ljs501_wk1_front0002.tif', label: 'Inside front cover', sequence: 2, table_of_contents: ["Seller's description, Inside front cover"], viewing_direction: 'left-to-right' },
            { display: 'paged', filename: 'ljs501_wk1_front0003.tif', label: '[Flyleaf 1 recto]', sequence: 3, table_of_contents: ["Seller's note, Flyleaf 1 recto"], viewing_direction: 'left-to-right' },
            { display: 'paged', filename: 'ljs501_wk1_front0004.tif', label: '[Flyleaf 1 verso]', sequence: 4, table_of_contents: [], viewing_direction: 'left-to-right' },
            { display: 'paged', filename: 'ljs501_wk1_body0001.tif', label: '1r', sequence: 5, table_of_contents: ["Historiated initial, Initial I, Woman and monk holding armillary sphere, f. 1r", "Puzzle initial, Initial C, f. 1r"], viewing_direction: 'left-to-right' },
            { display: 'paged', filename: 'ljs501_wk1_body0002.tif', label: '1v', sequence: 6, table_of_contents: ["Decorated initial, Initial C, f. 1v"], viewing_direction: 'left-to-right' },
            { display: 'paged', filename: 'ljs501_wk1_body0003.tif', label: '2r', sequence: 7, table_of_contents: [], viewing_direction: 'left-to-right' },
            { display: 'paged', filename: 'ljs501_wk1_body0004.tif', label: '2v', sequence: 8, table_of_contents: [], viewing_direction: 'left-to-right' },
            { display: 'paged', filename: 'ljs501_wk1_back0001.tif', label: '[Flyleaf 1 recto]', sequence: 9, table_of_contents: [], viewing_direction: 'left-to-right' },
            { display: 'paged', filename: 'ljs501_wk1_back0002.tif', label: '[Flyleaf 1 verso]', sequence: 10, table_of_contents: [], viewing_direction: 'left-to-right' },
            { display: 'paged', filename: 'ljs501_wk1_back0003.tif', label: 'Inside back cover', sequence: 11, table_of_contents: [], viewing_direction: 'left-to-right' },
            { display: 'paged', filename: 'ljs501_wk1_back0004.tif', label: 'Back cover', sequence: 12, table_of_contents: [], viewing_direction: 'left-to-right' },
            { display: 'paged', filename: 'ljs501_wk1_back0005.tif', label: 'Spine', sequence: 13, table_of_contents: [], viewing_direction: 'left-to-right' }
          ]
        end

        it 'generates expected data' do
          expect(generator.send(:from_bibnumber, bibnumber)).to eql expected_data
        end
      end

      context 'when descriptive metadata contains a reading direction in the 996 field' do
        let(:descriptive_metadata) do
          <<~METADATA
            <marc:records xmlns:marc="http://www.loc.gov/MARC21/slim" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.loc.gov/MARC21/slim http://www.loc.gov/standards/marcxml/schema/MARC21slim.xsd">
              <marc:record>
                <marc:datafield ind1=" " ind2=" " tag="996">
                  <marc:subfield code="a">hinge-right</marc:subfield>
                </marc:datafield>
              </marc:record>
            </marc:records>
          METADATA
        end

        let(:expected_data) do
          [
            { display: 'paged', filename: 'ljs501_wk1_front0001.tif', label: 'Front cover', sequence: 1, table_of_contents: [], viewing_direction: 'right-to-left' },
            { display: 'paged', filename: 'ljs501_wk1_front0002.tif', label: 'Inside front cover', sequence: 2, table_of_contents: ["Seller's description, Inside front cover"], viewing_direction: 'right-to-left' },
            { display: 'paged', filename: 'ljs501_wk1_front0003.tif', label: '[Flyleaf 1 recto]', sequence: 3, table_of_contents: ["Seller's note, Flyleaf 1 recto"], viewing_direction: 'right-to-left' },
            { display: 'paged', filename: 'ljs501_wk1_front0004.tif', label: '[Flyleaf 1 verso]', sequence: 4, table_of_contents: [], viewing_direction: 'right-to-left' },
            { display: 'paged', filename: 'ljs501_wk1_body0001.tif', label: '1r', sequence: 5, table_of_contents: ["Historiated initial, Initial I, Woman and monk holding armillary sphere, f. 1r", "Puzzle initial, Initial C, f. 1r"], viewing_direction: 'right-to-left' },
            { display: 'paged', filename: 'ljs501_wk1_body0002.tif', label: '1v', sequence: 6, table_of_contents: ["Decorated initial, Initial C, f. 1v"], viewing_direction: 'right-to-left' },
            { display: 'paged', filename: 'ljs501_wk1_body0003.tif', label: '2r', sequence: 7, table_of_contents: [], viewing_direction: 'right-to-left' },
            { display: 'paged', filename: 'ljs501_wk1_body0004.tif', label: '2v', sequence: 8, table_of_contents: [], viewing_direction: 'right-to-left' },
            { display: 'paged', filename: 'ljs501_wk1_back0001.tif', label: '[Flyleaf 1 recto]', sequence: 9, table_of_contents: [], viewing_direction: 'right-to-left' },
            { display: 'paged', filename: 'ljs501_wk1_back0002.tif', label: '[Flyleaf 1 verso]', sequence: 10, table_of_contents: [], viewing_direction: 'right-to-left' },
            { display: 'paged', filename: 'ljs501_wk1_back0003.tif', label: 'Inside back cover', sequence: 11, table_of_contents: [], viewing_direction: 'right-to-left' },
            { display: 'paged', filename: 'ljs501_wk1_back0004.tif', label: 'Back cover', sequence: 12, table_of_contents: [], viewing_direction: 'right-to-left' },
            { display: 'paged', filename: 'ljs501_wk1_back0005.tif', label: 'Spine', sequence: 13, table_of_contents: [], viewing_direction: 'right-to-left' }
          ]
        end

        it 'generates expected data' do
          expect(generator.send(:from_bibnumber, bibnumber)).to eql expected_data
        end
      end

      context 'when descriptive metadata contains "unbound" in the 996 field' do
        let(:descriptive_metadata) do
          <<~METADATA
            <marc:records xmlns:marc="http://www.loc.gov/MARC21/slim" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.loc.gov/MARC21/slim http://www.loc.gov/standards/marcxml/schema/MARC21slim.xsd">
              <marc:record>
                <marc:datafield ind1=" " ind2=" " tag="996">
                  <marc:subfield code="a">unbound</marc:subfield>
                </marc:datafield>
              </marc:record>
            </marc:records>
          METADATA
        end

        let(:expected_data) do
          [
            { display: 'individuals', filename: 'ljs501_wk1_front0001.tif', label: 'Front cover', sequence: 1, table_of_contents: [], viewing_direction: 'left-to-right' },
            { display: 'individuals', filename: 'ljs501_wk1_front0002.tif', label: 'Inside front cover', sequence: 2, table_of_contents: ["Seller's description, Inside front cover"], viewing_direction: 'left-to-right' },
            { display: 'individuals', filename: 'ljs501_wk1_front0003.tif', label: '[Flyleaf 1 recto]', sequence: 3, table_of_contents: ["Seller's note, Flyleaf 1 recto"], viewing_direction: 'left-to-right' },
            { display: 'individuals', filename: 'ljs501_wk1_front0004.tif', label: '[Flyleaf 1 verso]', sequence: 4, table_of_contents: [], viewing_direction: 'left-to-right' },
            { display: 'individuals', filename: 'ljs501_wk1_body0001.tif', label: '1r', sequence: 5, table_of_contents: ["Historiated initial, Initial I, Woman and monk holding armillary sphere, f. 1r", "Puzzle initial, Initial C, f. 1r"], viewing_direction: 'left-to-right' },
            { display: 'individuals', filename: 'ljs501_wk1_body0002.tif', label: '1v', sequence: 6, table_of_contents: ["Decorated initial, Initial C, f. 1v"], viewing_direction: 'left-to-right' },
            { display: 'individuals', filename: 'ljs501_wk1_body0003.tif', label: '2r', sequence: 7, table_of_contents: [], viewing_direction: 'left-to-right' },
            { display: 'individuals', filename: 'ljs501_wk1_body0004.tif', label: '2v', sequence: 8, table_of_contents: [], viewing_direction: 'left-to-right' },
            { display: 'individuals', filename: 'ljs501_wk1_back0001.tif', label: '[Flyleaf 1 recto]', sequence: 9, table_of_contents: [], viewing_direction: 'left-to-right' },
            { display: 'individuals', filename: 'ljs501_wk1_back0002.tif', label: '[Flyleaf 1 verso]', sequence: 10, table_of_contents: [], viewing_direction: 'left-to-right' },
            { display: 'individuals', filename: 'ljs501_wk1_back0003.tif', label: 'Inside back cover', sequence: 11, table_of_contents: [], viewing_direction: 'left-to-right' },
            { display: 'individuals', filename: 'ljs501_wk1_back0004.tif', label: 'Back cover', sequence: 12, table_of_contents: [], viewing_direction: 'left-to-right' },
            { display: 'individuals', filename: 'ljs501_wk1_back0005.tif', label: 'Spine', sequence: 13, table_of_contents: [], viewing_direction: 'left-to-right' }
          ]
        end

        it 'generates expected data' do
          expect(generator.send(:from_bibnumber, bibnumber)).to eql expected_data
        end
      end
    end
  end

  describe '#from_ordered_filenames' do
    let(:generator) { described_class.new }

    context 'when only providing filenames' do
      let(:expected_csv) do
        [
          { filename: 'first.tif', sequence: 1 },
          { filename: 'second.tif', sequence: 2 },
          { filename: 'third.tif', sequence: 3 }
        ]
      end

      it 'generates expected csv data' do
        expect(generator.send(:from_ordered_filenames, 'first.tif; second.tif; third.tif')).to eql expected_csv
      end
    end

    context 'when providing filenames and display' do
      let(:expected_csv) do
        [
          { filename: 'first.tif', sequence: 1, display: 'paged' },
          { filename: 'second.tif', sequence: 2, display: 'paged' },
          { filename: 'thrid.tif', sequence: 3, display: 'paged' }
        ]
      end

      it 'generates expected csv data' do
        expect(generator.send(:from_ordered_filenames, 'first.tif; second.tif; thrid.tif', 'paged')).to eql expected_csv
      end
    end

    context 'when providing filenames and viewing_direction' do
      let(:expected_data) do
        [
          { filename: 'first.tif', sequence: 1, viewing_direction: 'top-to-bottom' },
          { filename: 'second.tif', sequence: 2, viewing_direction: 'top-to-bottom' },
          { filename: 'thrid.tif', sequence: 3, viewing_direction: 'top-to-bottom' }
        ]
      end

      it 'generates expected data' do
        expect(generator.send(:from_ordered_filenames, 'first.tif; second.tif; thrid.tif', nil, 'top-to-bottom')).to eql expected_data
      end
    end

    context 'when providing filenames, display and viewing_direction' do
      let(:expected_data) do
        [
          { filename: 'first.tif', sequence: 1, display: 'paged', viewing_direction: 'top-to-bottom' },
          { filename: 'second.tif', sequence: 2, display: 'paged', viewing_direction: 'top-to-bottom' },
          { filename: 'thrid.tif', sequence: 3, display: 'paged', viewing_direction: 'top-to-bottom' }
        ]
      end

      it 'generates expected data' do
        expect(generator.send(:from_ordered_filenames, 'first.tif; second.tif; thrid.tif', 'paged', 'top-to-bottom')).to eql expected_data
      end
    end
  end

  describe '#from_sequence' do
    let(:generator) { described_class.new }

    context 'when only providing sequenced files' do
      let(:sequence) do
        [
          { filename: 'first.tif', label: 'First', table_of_contents: ['First Illuminated Image', 'Second Illuminated Image'] },
          { filename: 'second.tif', label: 'Second' },
          { filename: 'thrid.tif', label: 'Thrid' }
        ]
      end
      let(:expected_data) do
        [
          { filename: 'first.tif', label: 'First', sequence: 1, table_of_contents: ['First Illuminated Image', 'Second Illuminated Image'] },
          { filename: 'second.tif', label: 'Second', sequence: 2 },
          { filename: 'thrid.tif', label: 'Thrid', sequence: 3 }
        ]
      end

      it 'generates expected data' do
        expect(generator.send(:from_sequence, sequence)).to eql expected_data
      end
    end

    context 'when providing sequenced files and viewing_direction' do
      let(:sequence) do
        [
          { filename: 'first.tif', label: 'First', table_of_contents: ['First Illuminated Image', 'Second Illuminated Image'] },
          { filename: 'second.tif', label: 'Second' },
          { filename: 'thrid.tif', label: 'Thrid' }
        ]
      end
      let(:expected_data) do
        [
          { filename: 'first.tif', label: 'First', sequence: 1, table_of_contents: ['First Illuminated Image', 'Second Illuminated Image'], viewing_direction: 'left-to-right' },
          { filename: 'second.tif', label: 'Second', sequence: 2, viewing_direction: 'left-to-right' },
          { filename: 'thrid.tif', label: 'Thrid', sequence: 3, viewing_direction: 'left-to-right' }
        ]
      end

      it 'generates expected data' do
        expect(generator.send(:from_sequence, sequence, nil, 'left-to-right')).to eql expected_data
      end
    end

    context 'when providing sequenced files, viewing_direction and display' do
      let(:sequence) do
        [
          { filename: 'first.tif', label: 'First', table_of_contents: ['First Illuminated Image', 'Second Illuminated Image'] },
          { filename: 'second.tif', label: 'Second' },
          { filename: 'thrid.tif', label: 'Thrid' }
        ]
      end
      let(:expected_data) do
        [
          { display: 'paged', filename: 'first.tif', label: 'First', sequence: 1, table_of_contents: ['First Illuminated Image', 'Second Illuminated Image'], viewing_direction: 'left-to-right' },
          { display: 'paged', filename: 'second.tif', label: 'Second', sequence: 2, viewing_direction: 'left-to-right' },
          { display: 'paged', filename: 'thrid.tif', label: 'Thrid', sequence: 3, viewing_direction: 'left-to-right' }
        ]
      end

      it 'generates expected data' do
        expect(generator.send(:from_sequence, sequence, 'paged', 'left-to-right')).to eql expected_data
      end
    end
  end
end
