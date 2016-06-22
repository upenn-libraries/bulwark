require 'rails_helper'

RSpec.describe MetadataBuilder, type: :model do
  it "has a valid factory" do
    expect(FactoryGirl.create(:metadata_builder)).to be_valid
  end

  let(:metadata_builder_spec) { FactoryGirl.create(:metadata_builder) }

  describe "public instance methods" do
    it "build_xml_files" do
      expect(metadata_builder_spec.build_xml_files).to eq({:success => "Preservation XML generated successfully.  See preview below."})
    end
  end


end
