require 'rails_helper'

RSpec.describe Manuscript, type: :model do
  xit "has a valid Factory" do
    expect(FactoryBot.create(:manuscript)).to be_valid
  end

  xit "is invalid without a title" do
    expect(FactoryBot.build(:manuscript, title: nil)).not_to be_valid
  end

  xit "is invalid without an identifier" do
    expect(FactoryBot.build(:manuscript, identifier: nil)).not_to be_valid
  end
end
