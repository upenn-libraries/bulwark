require 'rails_helper'

RSpec.describe VersionControlAgent, type: :model do

  it "has a valid factory" do
    expect(FactoryGirl.create(:version_control_agent)).to be_valid
  end

  let(:version_control_agent_instance) { FactoryGirl.create(:version_control_agent) }

  it "has a valid vc_type" do
    expect(version_control_agent_instance.vc_type).to eq("GitAnnex")

  end

  it "has a working_path" do
    expect(version_control_agent_instance.working_path).not_to be_nil
  end

  it "has a remote_path" do
    expect(version_control_agent_instance.remote_path).not_to be_nil
  end
  
end
