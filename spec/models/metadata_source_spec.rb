require 'rails_helper'

RSpec.describe MetadataSource, type: :model do
  it "has a valid factory" do
    expect(FactoryGirl.create(:metadata_source)).to be_valid
  end
  
end
