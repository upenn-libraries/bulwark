# frozen_string_literal: true
require 'rails_helper'

RSpec.describe DownloadHelper, type: :helper do
  let(:bucket) { 'bucket' }
  let(:file) { 'image.jpeg' }
  let(:phalt) { 'https://example.com/phalt' }

  describe '#download_link' do
    context 'when using S3 special remote' do
      before do
        allow(Bulwark::Config).to receive(:special_remote).and_return(type: 'S3')
        allow(Bulwark::Config).to receive(:phalt).and_return(url: phalt)
      end

      it 'return correct link when no filename or disposition are provided' do
        expect(download_link(bucket, file)).to eql "#{phalt}/download/#{bucket}/#{file}"
      end

      it 'returns correct link when filename is provided' do
        expect(download_link(bucket, file, filename: 'new_file')).to eql "#{phalt}/download/#{bucket}/#{file}?filename=new_file"
      end

      it 'returns correct link when disposition is provided' do
        expect(download_link(bucket, file, disposition: 'inline')).to eql "#{phalt}/download/#{bucket}/#{file}?disposition=inline"
      end

      it 'returns correct link when disposition and inline is provided' do
        expect(
          download_link(bucket, file, disposition: 'inline', filename: 'new_file')
        ).to eql "#{phalt}/download/#{bucket}/#{file}?disposition=inline&filename=new_file"
      end
    end

    context 'when using directory special remote' do
      before do
        allow(Bulwark::Config).to receive(:special_remote).and_return(type: 'directory')
      end

      it 'return correct link when no filename or disposition are provided' do
        expect(download_link(bucket, file)).to eql "#{root_url}special_remote_download/#{bucket}/#{file}"
      end

      it 'returns correct link when filename is provided' do
        expect(download_link(bucket, file, filename: 'new_file')).to eql "#{root_url}special_remote_download/#{bucket}/#{file}?filename=new_file"
      end

      it 'returns correct link when disposition is provided' do
        expect(download_link(bucket, file, disposition: 'inline')).to eql "#{root_url}special_remote_download/#{bucket}/#{file}?disposition=inline"
      end

      it 'returns correct link when disposition and inline is provided' do
        expect(
          download_link(bucket, file, disposition: 'inline', filename: 'new_file')
        ).to eql "#{root_url}special_remote_download/#{bucket}/#{file}?disposition=inline&filename=new_file"
      end
    end
  end
end
