# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Asset, type: :model do
  include_context 'stub successful EZID requests'

  let(:repo) { FactoryBot.create(:repo) }

  describe '#valid?' do
    context 'when all required fields are present' do
      let(:asset) { FactoryBot.build(:asset, repo: repo) }

      it 'does not return errorrs' do
        expect(asset.valid?).to be true
      end
    end

    context 'when repo_id not present' do
      let(:asset) { FactoryBot.build(:asset) }

      it 'returns error' do
        expect(asset.valid?).to be false
        expect(asset.errors.messages[:repo]).to include "can't be blank"
      end
    end
    context 'when filename are repo id are not unique' do
      let(:asset_1) { FactoryBot.create(:asset, repo: repo, filename: 'cool_file.txt') }
      let(:asset_2) { FactoryBot.build(:asset, repo: repo, filename: 'cool_file.txt') }

      it 'returns error' do
        expect(asset_1).to be_an Asset
        expect(asset_2.valid?).to be false
        expect(asset_2.errors.messages[:filename]).to include 'has already been taken'
      end
    end

    context 'when filename is not present' do
      let(:asset) { FactoryBot.build(:asset, repo: repo, filename: nil) }

      it 'returns error' do
        expect(asset.valid?).to be false
        expect(asset.errors.messages[:filename]).to include "can't be blank"
      end
    end
  end

  describe '#filename_basename' do
    context 'when filename contains one extension' do
      let(:asset) { FactoryBot.build(:asset, repo: repo, filename: 'item_1_body_0001.tif') }

      it 'returns correct basename' do
        expect(asset.filename_basename).to eql 'item_1_body_0001'
      end
    end

    context 'when filename contains multiple extensions' do
      let(:asset) { FactoryBot.build(:asset, repo: repo, filename: 'archive.warc.gz') }

      it 'returns correct basename' do
        expect(asset.filename_basename).to eql 'archive'
      end
    end

    context 'when filename contains a period as part of the filename' do
      let(:asset) { FactoryBot.build(:asset, repo: repo, filename: 'website.archive.warc.gz') }

      it 'returns correct basename' do
        expect(asset.filename_basename).to eql 'website.archive'
      end
    end
  end
end
