require 'rails_helper'

RSpec.describe Utils::VersionControl::GitAnnex do
  let(:repo) { FactoryBot.create(:repo) }
  let(:git_annex) { Utils::VersionControl::GitAnnex.new(repo) }

  describe '.new' do
    it 'assigns repo' do
      expect(git_annex.repo).to be repo
    end

    it 'generates remote_repo_path' do
      expect(git_annex.remote_repo_path).to eql File.join(Utils.config[:assets_path], repo.names.git)
    end
  end

  describe '#clone' do
    let(:cloned_repo_path) { git_annex.clone }
    let(:git) { ExtendedGit.open(cloned_repo_path) }

    it 'is a working directory' do
      expect(ExtendedGit.is_working_directory?(cloned_repo_path)).to be true
    end

    it 'initialized git annex' do
      expect(git.config('annex.uuid')).not_to be_blank
      expect(git.config('annex.version')).to match /^\d{1}$/
    end

    it 'correctly configured special remote' do
      expect {
        git.annex.testremote('local', fast: true)
      }.not_to raise_error
    end

    it 'adds git configuration' do
      expect(git.config('remote.origin.annex-ignore')).to eq 'true'
      expect(git.config('annex.largefiles')).to eq 'not (include=.repoadmin/bin/*.sh)'
    end
  end
end
