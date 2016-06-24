require 'rails_helper'

RSpec.describe Repo, type: :model do
  it "has a valid factory" do
    expect(FactoryGirl.create(:repo)).to be_valid
  end

  let(:repo_instance) { FactoryGirl.create(:repo) }

  it "is invalid without a title" do
    expect(FactoryGirl.build(:repo, :title => nil)).not_to be_valid
  end
  it "is invalid without a directory" do
    expect(FactoryGirl.build(:repo, :directory => nil)).not_to be_valid
  end
  it "is invalid without a metadata subdirectory" do
    expect(FactoryGirl.build(:repo, :metadata_subdirectory => nil)).not_to be_valid
  end
  it "is invalid without an assets subdirectory" do
    expect(FactoryGirl.build(:repo, :assets_subdirectory => nil)).not_to be_valid
  end
  it "is invalid without a metadata filename" do
    expect(FactoryGirl.build(:repo, :metadata_filename => nil)).not_to be_valid
  end
  it "is invalid without file extensions" do
    expect(FactoryGirl.build(:repo, :file_extensions => nil)).not_to be_valid
  end

  describe "public instance methods" do
    context "responds to" do
      it "create_remote" do
        expect(repo_instance).to respond_to(:create_remote)
      end
    end

    context "executes model methods correctly" do
      context "create_remote" do
        it "can create a remote directory" do
          expect(repo_instance.create_remote).to eq({ :success => "Remote successfully created" })
        end
      end
    end
  end

end
