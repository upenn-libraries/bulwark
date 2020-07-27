require 'rails_helper'

RSpec.describe MetadataBuilder, type: :model do
  it "has a valid factory" do
    expect(FactoryBot.create(:metadata_builder)).to be_valid
  end
  context "parent_repo" do
    it "is invalid without a parent repo" do
      expect(FactoryBot.build(:metadata_builder, :parent_repo => nil)).not_to be_valid
    end
    it "belongs to an existing parent repo" do

    end
    it "is deleted when its parent repo is deleted"
  end
  context "source" do
    it "is invalid without at least one source file" do
      expects(FactoryBot.build(:metadata_builder, :source => nil)).not_to be_valid
    end
    it "has a valid source"
  end

end
