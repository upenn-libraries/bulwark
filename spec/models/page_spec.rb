require 'rails_helper'

RSpec.describe Page, type: :model do
  it "has a valid factory" do
    expect(FactoryGirl.create(:page)).to be_valid
  end
  it "is invalid without a page ID"
  it "is invalid without a manuscript ID"
end
