require 'rails_helper'
require 'faker'

RSpec.describe ExtendedGit do
  let(:repo_location) do
    Rails.root.join('tmp', "test_bare_#{Faker::Alphanumeric.alphanumeric(number: 10)}.git").to_s
  end
  let!(:git_repo) { ExtendedGit.init(nil, bare: true, repository: repo_location) }

  after { FileUtils.remove_dir(repo_location) }

  describe '.init' do
    it 'returns a ExtendedGit::Base object' do
      expect(git_repo).to be_a ExtendedGit::Base
    end

    it 'correctly creates git repository' do
      expect(ExtendedGit.is_git_directory?(repo_location)).to be true
    end
  end

  describe '.clone' do
    let(:working_directory) { Rails.root.join('tmp', "test_working_#{Faker::Alphanumeric.alphanumeric(number: 10)}") }

    after { FileUtils.remove_dir(working_directory) }

    it 'returns a ExtendedGit::Base object' do
      expect(ExtendedGit.clone(repo_location, working_directory)).to be_a ExtendedGit::Base
    end
  end

  describe '.open' do
    let(:working_directory) { Rails.root.join('tmp', "test_working_#{Faker::Alphanumeric.alphanumeric(number: 10)}") }
    let(:clone) { ExtendedGit.clone(repo_location, working_directory) }
    let(:open) { ExtendedGit.open(clone.dir.path) }
    after { FileUtils.remove_dir(working_directory) }

    it 'references correct working path' do
      expect(open.dir.path).to eql working_directory.to_s
    end

    it 'returns a ExtendedGit::Base object' do
      expect(open).to be_a ExtendedGit::Base
    end
  end
end
