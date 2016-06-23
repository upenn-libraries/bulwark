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

  it "is invalid without a preservation filename" do
    expect(FactoryGirl.build(:repo, :preservation_filename => nil)).not_to be_valid
  end

  describe "public instance methods" do

    context "executes model methods correctly on creation" do
      context "create_remote" do
        it "can create a remote directory" do
          expect(repo_instance.create_remote).to be_in([{ :success => "Remote successfully created" }, { :error => "Remote already exists" }])
        end
      end
    end
  end

end
