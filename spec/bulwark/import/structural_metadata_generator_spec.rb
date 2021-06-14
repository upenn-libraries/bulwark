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

  describe '#csv' do
    context 'when generating csv with bibnumber' do
      let(:generator) { described_class.new(bibnumber: '1234567890') }

      it 'calls from_bibnumber' do
        expect(generator).to receive(:from_bibnumber).with('1234567890')
        generator.csv
      end
    end

    context 'when generating csv with file' do
      let(:generator) { described_class.new(drive: 'test', path: 'to/file.csv') }

      it 'calls from_file' do
        expect(generator).to receive(:from_file).with(File.join(Bulwark::Import::MountedDrives.path_to('test'), 'to/file.csv'))
        generator.csv
      end
    end

    context 'when generating csv with filenames' do
      let(:generator) { described_class.new(filenames: 'something') }

      it 'calls from_ordered_filenames' do
        expect(generator).to receive(:from_ordered_filenames).with('something', nil, nil)
        generator.csv
      end
    end
  end

  describe '#from_bibnumber' do
    let(:bibnumber) { '9960927563503681' }
    let(:generator) { described_class.new }

    context 'when invalid bibnumber' do
      before do
        stub_request(:get, "https://marmite.library.upenn.edu:9292/records/#{bibnumber}/create?format=marc21").to_return(status: 404)
        stub_request(:get, "https://marmite.library.upenn.edu:9292/records/#{bibnumber}/show?format=marc21")
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
        stub_request(:get, "https://marmite.library.upenn.edu:9292/records/#{bibnumber}/create?format=marc21").to_return(status: 302)
        stub_request(:get, "https://marmite.library.upenn.edu:9292/records/#{bibnumber}/show?format=marc21")
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
          <<~CSV
            display,filename,label,sequence,table_of_contents[1],table_of_contents[2],viewing_direction
            paged,ljs501_wk1_front0001.tif,Front cover,1,,,left-to-right
            paged,ljs501_wk1_front0002.tif,Inside front cover,2,"Seller's description, Inside front cover",,left-to-right
            paged,ljs501_wk1_front0003.tif,[Flyleaf 1 recto],3,"Seller's note, Flyleaf 1 recto",,left-to-right
            paged,ljs501_wk1_front0004.tif,[Flyleaf 1 verso],4,,,left-to-right
            paged,ljs501_wk1_body0001.tif,1r,5,"Historiated initial, Initial I, Woman and monk holding armillary sphere, f. 1r","Puzzle initial, Initial C, f. 1r",left-to-right
            paged,ljs501_wk1_body0002.tif,1v,6,"Decorated initial, Initial C, f. 1v",,left-to-right
            paged,ljs501_wk1_body0003.tif,2r,7,,,left-to-right
            paged,ljs501_wk1_body0004.tif,2v,8,,,left-to-right
            paged,ljs501_wk1_back0001.tif,[Flyleaf 1 recto],9,,,left-to-right
            paged,ljs501_wk1_back0002.tif,[Flyleaf 1 verso],10,,,left-to-right
            paged,ljs501_wk1_back0003.tif,Inside back cover,11,,,left-to-right
            paged,ljs501_wk1_back0004.tif,Back cover,12,,,left-to-right
            paged,ljs501_wk1_back0005.tif,Spine,13,,,left-to-right
          CSV
        end

        it 'generates expected csv data' do
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
          <<~CSV
            display,filename,label,sequence,table_of_contents[1],table_of_contents[2],viewing_direction
            paged,ljs501_wk1_front0001.tif,Front cover,1,,,right-to-left
            paged,ljs501_wk1_front0002.tif,Inside front cover,2,"Seller's description, Inside front cover",,right-to-left
            paged,ljs501_wk1_front0003.tif,[Flyleaf 1 recto],3,"Seller's note, Flyleaf 1 recto",,right-to-left
            paged,ljs501_wk1_front0004.tif,[Flyleaf 1 verso],4,,,right-to-left
            paged,ljs501_wk1_body0001.tif,1r,5,"Historiated initial, Initial I, Woman and monk holding armillary sphere, f. 1r","Puzzle initial, Initial C, f. 1r",right-to-left
            paged,ljs501_wk1_body0002.tif,1v,6,"Decorated initial, Initial C, f. 1v",,right-to-left
            paged,ljs501_wk1_body0003.tif,2r,7,,,right-to-left
            paged,ljs501_wk1_body0004.tif,2v,8,,,right-to-left
            paged,ljs501_wk1_back0001.tif,[Flyleaf 1 recto],9,,,right-to-left
            paged,ljs501_wk1_back0002.tif,[Flyleaf 1 verso],10,,,right-to-left
            paged,ljs501_wk1_back0003.tif,Inside back cover,11,,,right-to-left
            paged,ljs501_wk1_back0004.tif,Back cover,12,,,right-to-left
            paged,ljs501_wk1_back0005.tif,Spine,13,,,right-to-left
          CSV
        end

        it 'generates expected csv data' do
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
          <<~CSV
            display,filename,label,sequence,table_of_contents[1],table_of_contents[2],viewing_direction
            individuals,ljs501_wk1_front0001.tif,Front cover,1,,,left-to-right
            individuals,ljs501_wk1_front0002.tif,Inside front cover,2,"Seller's description, Inside front cover",,left-to-right
            individuals,ljs501_wk1_front0003.tif,[Flyleaf 1 recto],3,"Seller's note, Flyleaf 1 recto",,left-to-right
            individuals,ljs501_wk1_front0004.tif,[Flyleaf 1 verso],4,,,left-to-right
            individuals,ljs501_wk1_body0001.tif,1r,5,"Historiated initial, Initial I, Woman and monk holding armillary sphere, f. 1r","Puzzle initial, Initial C, f. 1r",left-to-right
            individuals,ljs501_wk1_body0002.tif,1v,6,"Decorated initial, Initial C, f. 1v",,left-to-right
            individuals,ljs501_wk1_body0003.tif,2r,7,,,left-to-right
            individuals,ljs501_wk1_body0004.tif,2v,8,,,left-to-right
            individuals,ljs501_wk1_back0001.tif,[Flyleaf 1 recto],9,,,left-to-right
            individuals,ljs501_wk1_back0002.tif,[Flyleaf 1 verso],10,,,left-to-right
            individuals,ljs501_wk1_back0003.tif,Inside back cover,11,,,left-to-right
            individuals,ljs501_wk1_back0004.tif,Back cover,12,,,left-to-right
            individuals,ljs501_wk1_back0005.tif,Spine,13,,,left-to-right
          CSV
        end

        it 'generates expected csv data' do
          expect(generator.send(:from_bibnumber, bibnumber)).to eql expected_data
        end
      end
    end
  end

  describe '#from_ordered_filenames' do
    let(:generator) { described_class.new }

    context 'when only providing filenames' do
      let(:expected_csv) do
        <<~CSV
          filename,sequence
          first.tif,1
          second.tif,2
          thrid.tif,3
        CSV
      end

      it 'generates expected csv data' do
        expect(generator.send(:from_ordered_filenames, 'first.tif; second.tif; thrid.tif')).to eql expected_csv
      end
    end

    context 'when providing filenames and display' do
      let(:expected_csv) do
        <<~CSV
          filename,sequence,display
          first.tif,1,paged
          second.tif,2,paged
          thrid.tif,3,paged
        CSV
      end

      it 'generates expected csv data' do
        expect(generator.send(:from_ordered_filenames, 'first.tif; second.tif; thrid.tif', 'paged')).to eql expected_csv
      end
    end

    context 'when providing filenames and viewing_direction' do
      let(:expected_csv) do
        <<~CSV
          filename,sequence,viewing_direction
          first.tif,1,top-to-bottom
          second.tif,2,top-to-bottom
          thrid.tif,3,top-to-bottom
        CSV
      end

      it 'generates expected csv data' do
        expect(generator.send(:from_ordered_filenames, 'first.tif; second.tif; thrid.tif', nil, 'top-to-bottom')).to eql expected_csv
      end
    end

    context 'when providing filenames, display and viewing_direction' do
      let(:expected_csv) do
        <<~CSV
          filename,sequence,display,viewing_direction
          first.tif,1,paged,top-to-bottom
          second.tif,2,paged,top-to-bottom
          thrid.tif,3,paged,top-to-bottom
        CSV
      end

      it 'generates expected csv data' do
        expect(generator.send(:from_ordered_filenames, 'first.tif; second.tif; thrid.tif', 'paged', 'top-to-bottom')).to eql expected_csv
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
      let(:expected_csv) do
        <<~CSV
          filename,label,sequence,table_of_contents[1],table_of_contents[2]
          first.tif,First,1,First Illuminated Image,Second Illuminated Image
          second.tif,Second,2,,
          thrid.tif,Thrid,3,,
        CSV
      end

      it 'generates expected csv data' do
        expect(generator.send(:from_sequence, sequence)).to eql expected_csv
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
      let(:expected_csv) do
        <<~CSV
          filename,label,sequence,table_of_contents[1],table_of_contents[2],viewing_direction
          first.tif,First,1,First Illuminated Image,Second Illuminated Image,left-to-right
          second.tif,Second,2,,,left-to-right
          thrid.tif,Thrid,3,,,left-to-right
        CSV
      end

      it 'generates expected csv data' do
        expect(generator.send(:from_sequence, sequence, nil, 'left-to-right')).to eql expected_csv
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
      let(:expected_csv) do
        <<~CSV
          display,filename,label,sequence,table_of_contents[1],table_of_contents[2],viewing_direction
          paged,first.tif,First,1,First Illuminated Image,Second Illuminated Image,left-to-right
          paged,second.tif,Second,2,,,left-to-right
          paged,thrid.tif,Thrid,3,,,left-to-right
        CSV
      end

      it 'generates expected csv data' do
        expect(generator.send(:from_sequence, sequence, 'paged', 'left-to-right')).to eql expected_csv
      end
    end
  end
end
