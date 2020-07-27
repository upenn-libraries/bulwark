require 'rails_helper'

RSpec.describe Image, type: :model do
  it "has a valid factory" do
    expect(FactoryBot.create(:page)).to be_valid
  end
  it "is invalid without a page ID" do
    expect(FactoryBot.build(:page, :page_id => nil)).not_to be_valid
  end
  it "is invalid without a parent manuscript" do
    expect(FactoryBot.build(:page, :parent_manuscript => nil)).not_to be_valid
  end

  describe "relationship to manuscript" do
    before :each do
      @manuscript = FactoryBot.create(:manuscript)
    end

    it "is the child of an existing manuscript" do
      expect(FactoryBot.create(:page, :parent_manuscript => @manuscript.identifier)).to be_valid
    end
  end

end
