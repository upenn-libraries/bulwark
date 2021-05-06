# frozen_string_literal: true

RSpec.describe MarmiteClient do
  describe '#marc21' do
    let(:bibnumber) { '9923478503503681' }

    context 'when request is successful' do
      before do
        stub_request(:get, "https://marmite.library.upenn.edu:9292/records/#{bibnumber}/create?format=marc21").to_return(status: 302)
        stub_request(:get, "https://marmite.library.upenn.edu:9292/records/#{bibnumber}/show?format=marc21")
          .to_return(status: 200, body: fixture_to_str('marmite', 'marc_xml', "#{bibnumber}.xml"), headers: {})
      end

      it 'returns expected MARC XML' do
        expect(described_class.marc21(bibnumber)).to eql fixture_to_str('marmite', 'marc_xml', "#{bibnumber}.xml")
      end
    end

    context 'when request is unsuccessful' do
      before do
        stub_request(:get, "https://marmite.library.upenn.edu:9292/records/#{bibnumber}/create?format=marc21").to_return(status: 404)
        stub_request(:get, "https://marmite.library.upenn.edu:9292/records/#{bibnumber}/show?format=marc21")
          .to_return(status: 404, body: "Record #{bibnumber} in marc21 format not found", headers: {})
      end

      it 'raises exception' do
        expect {
          described_class.marc21(bibnumber)
        }.to raise_error(MarmiteClient::Error, "Could not retrieve MARC for #{bibnumber}. Error: Record #{bibnumber} in marc21 format not found")
      end
    end
  end

  describe '#iiif_presentation' do
    include_context 'stub successful EZID requests'

    let(:repo) { FactoryBot.create(:repo) }

    context 'when request is successful' do
      before do
        stub_request(:get, "https://marmite.library.upenn.edu:9292/records/#{repo.names.fedora}/create?format=iiif_presentation").to_return(status: 302)
        stub_request(:get, "https://marmite.library.upenn.edu:9292/records/#{repo.names.fedora}/show?format=iiif_presentation")
          .to_return(status: 200, body: "{}")
      end

      it 'returns response body' do
        expect(described_class.iiif_presentation(repo.names.fedora)).to eql "{}"
      end
    end

    context 'when request is unsuccessful' do
      before do
        stub_request(:get, "https://marmite.library.upenn.edu:9292/records/#{repo.names.fedora}/create?format=iiif_presentation").to_return(status: 500)
        stub_request(:get, "https://marmite.library.upenn.edu:9292/records/#{repo.names.fedora}/show?format=iiif_presentation")
          .to_return(status: 404, body: "Record #{repo.names.fedora} in iiif_presentation format not found")
      end

      it 'raises exception' do
        expect {
          described_class.iiif_presentation(repo.names.fedora)
        }.to raise_error(MarmiteClient::Error, "Could not create IIIF Presentation Manifest for #{repo.names.fedora}. Error: Record #{repo.names.fedora} in iiif_presentation format not found")
      end
    end
  end

  describe '#structural' do
    let(:bibnumber) { '9960927563503681' }

    context 'when request is successful' do
      let(:xml) { fixture_to_str('marmite', 'structural', "with_table_of_contents.xml") }
      before do
        stub_request(:get, "https://marmite.library.upenn.edu:9292/records/#{bibnumber}/create?format=structural").to_return(status: 302)
        stub_request(:get, "https://marmite.library.upenn.edu:9292/records/#{bibnumber}/show?format=structural")
          .to_return(status: 200, body: xml, headers: {})
      end

      it 'returns expected XML' do
        expect(described_class.structural(bibnumber)).to eql xml
      end
    end

    context 'when request is unsuccessful' do
      before do
        stub_request(:get, "https://marmite.library.upenn.edu:9292/records/#{bibnumber}/create?format=structural").to_return(status: 404)
        stub_request(:get, "https://marmite.library.upenn.edu:9292/records/#{bibnumber}/show?format=structural")
          .to_return(status: 404, body: "Record #{bibnumber} in structural format not found", headers: {})
      end

      it 'raises exception' do
        expect {
          described_class.structural(bibnumber)
        }.to raise_error(MarmiteClient::Error, "Could not retrieve Structural for #{bibnumber}. Error: Record #{bibnumber} in structural format not found")
      end
    end
  end

  describe '#config' do
    context 'when all configuration is present' do
      it 'returns configuration' do
        expect(described_class.config).to eql('url' => 'https://marmite.library.upenn.edu:9292')
      end
    end

    context 'when missing url' do
      before do
        allow(Rails.application).to receive(:config_for).with(:bulwark).and_return('marmite' => {})
      end

      it 'raises error' do
        expect { described_class.config }.to raise_error MarmiteClient::MissingConfiguration, 'Missing Marmite URL'
      end
    end
  end
end
