# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Asset, type: :model do
  include_context 'stub successful EZID requests'

  let(:repo) { FactoryBot.create(:repo) }

  describe '.valid?' do
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
end
