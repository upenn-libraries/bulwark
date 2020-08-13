require 'rails_helper'

RSpec.describe Image, type: :model do
  xit "has a valid factory" do
    expect(FactoryBot.create(:image)).to be_valid
  end
  xit "is invalid without a page ID" do
    expect(FactoryBot.build(:image, :page_id => nil)).not_to be_valid
  end
  xit "is invalid without a parent manuscript" do
    expect(FactoryBot.build(:image, :parent_manuscript => nil)).not_to be_valid
  end

  describe "relationship to manuscript" do
    before :each do
      @manuscript = FactoryBot.create(:manuscript)
    end

    xit "is the child of an existing manuscript" do
      expect(FactoryBot.create(:image, :parent_manuscript => @manuscript.identifier)).to be_valid
    end
  end

end
