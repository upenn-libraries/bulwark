# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Bulwark::Storage do
  let(:bucket) { 'bucket' }
  let(:file) { 'image.jpeg' }
  let(:phalt) { 'https://example.com/phalt' }

  describe '#url_for' do
    context 'when using S3 special remote' do
      before do
        allow(Settings.digital_object.special_remote).to receive(:type).and_return('S3')
        allow(Settings.phalt).to receive(:url).and_return(phalt)
      end

      it 'return correct link when no filename or disposition are provided' do
        expect(described_class.url_for(bucket, file)).to eql "#{phalt}/download/#{bucket}/#{file}"
      end

      it 'returns correct link when filename is provided' do
        expect(described_class.url_for(bucket, file, filename: 'new_file')).to eql "#{phalt}/download/#{bucket}/#{file}?filename=new_file"
      end

      it 'returns correct link when disposition is provided' do
        expect(described_class.url_for(bucket, file, disposition: 'inline')).to eql "#{phalt}/download/#{bucket}/#{file}?disposition=inline"
      end

      it 'returns correct link when disposition and inline is provided' do
        expect(
          described_class.url_for(bucket, file, disposition: 'inline', filename: 'new_file')
        ).to eql "#{phalt}/download/#{bucket}/#{file}?disposition=inline&filename=new_file"
      end
    end

    context 'when using directory special remote' do
      before do
        allow(Settings.digital_object.special_remote).to receive(:type).and_return('directory')
      end

      it 'return correct link when no filename or disposition are provided' do
        expect(described_class.url_for(bucket, file)).to eql "http://localhost:3000/special_remote_download/#{bucket}/#{file}"
      end

      it 'returns correct link when filename is provided' do
        expect(described_class.url_for(bucket, file, filename: 'new_file')).to eql "http://localhost:3000/special_remote_download/#{bucket}/#{file}?filename=new_file"
      end

      it 'returns correct link when disposition is provided' do
        expect(described_class.url_for(bucket, file, disposition: 'inline')).to eql "http://localhost:3000/special_remote_download/#{bucket}/#{file}?disposition=inline"
      end

      it 'returns correct link when disposition and inline is provided' do
        expect(
          described_class.url_for(bucket, file, disposition: 'inline', filename: 'new_file')
        ).to eql "http://localhost:3000/special_remote_download/#{bucket}/#{file}?disposition=inline&filename=new_file"
      end
    end
  end
end
