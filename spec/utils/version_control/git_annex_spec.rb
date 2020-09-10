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

    after { git_annex.remove_working_directory(cloned_repo_path) }

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

  describe '#add' do
    let(:cloned_repo_path) { git_annex.clone }
    let(:new_file_path) { File.join(cloned_repo_path, 'new_file.txt') }

    after { git_annex.remove_working_directory(cloned_repo_path) }

    [:store, :git].each do |type|
      before do
        FileUtils.touch(new_file_path)
        git_annex.add({ content: new_file_path, add_type: type }, cloned_repo_path)
      end

      it "adds files when adding through #{type}" do
        git = ExtendedGit.open(cloned_repo_path)
        expect(git.status.added?('new_file.txt')).to be true
      end
    end
  end

  describe '#commit' do
    after { git_annex.remove_working_directory(cloned_repo_path) }

    context 'after adding a file' do
      let(:cloned_repo_path) { git_annex.clone }
      let(:git) { ExtendedGit.open(cloned_repo_path) }
      let(:commit_message) { 'New commit.' }

      before do
        new_file_path = File.join(cloned_repo_path, 'new_file.txt')
        FileUtils.touch(new_file_path)
        git.add(new_file_path)
        git_annex.commit(commit_message, cloned_repo_path)
      end

      it 'correctly commits new file' do
        expect(git.log.first.message).to eql commit_message
        expect(git.status['new_file.txt']).not_to be nil
        expect(git.status.untracked?('new_file.txt')).to be false
      end
    end
  end

  describe '#push' do
    let(:cloned_repo_path) { git_annex.clone }
    let(:git) { ExtendedGit.open(cloned_repo_path) }
    let(:first_new_file) { 'first_new_file.txt' }
    let(:second_new_file) { 'second_new_file.txt' }

    before do
      [first_new_file, second_new_file].each do |new_file|
        new_file_path = File.join(cloned_repo_path, new_file )
        # Each file needs to have different content.
        File.open(new_file_path, 'w') { |f| f.write("New file -- #{new_file}") }
        git.add(new_file_path)
      end

      git_annex.commit('New files.', cloned_repo_path)
    end

    after { git_annex.remove_working_directory(cloned_repo_path) }

    context 'when pushing all new content' do
      before { git_annex.push({}, cloned_repo_path) }

      it 'content is stored in special remote' do
        expect(git.annex.whereis[first_new_file].locations.map(&:description)).to include '[local]'
        expect(git.annex.whereis[second_new_file].locations.map(&:description)).to include '[local]'
      end
    end

    context 'when only pushing specified content' do
      before do
        git_annex.push({ content: second_new_file }, cloned_repo_path)
      end

      it 'expected content is stored in special remote' do
        expect(git.annex.whereis[second_new_file].locations.map(&:description)).to include '[local]'
      end

      it 'expected content is NOT stored in special remote' do
        expect(git.annex.whereis[first_new_file].locations.map(&:description)).not_to include '[local]'
      end
    end
  end

  describe '#drop' do
    let(:cloned_repo_path) { git_annex.clone }
    let(:git) { ExtendedGit.open(cloned_repo_path) }
    let(:new_file) { 'new_file.txt' }

    # Adding an additional file.
    before do
      new_file_path = File.join(cloned_repo_path, new_file)
      FileUtils.touch(new_file_path)
      git.add(new_file_path)
      git_annex.commit('Adding new file.', cloned_repo_path)
      git_annex.push({}, cloned_repo_path)
    end

    after { git_annex.remove_working_directory(cloned_repo_path) }

    # Checking that files are present in working directory.
    it 'contains files in current working directory' do
      expect(git.annex.whereis.all?(&:here?)).to be true
    end

    context 'when dropping everything' do
      before { git_annex.drop({}, cloned_repo_path) }

      it 'drops all files' do
        expect(git.annex.whereis.any?(&:here?)).to be false
      end
    end

    context 'when dropping specific content' do
      let(:filename) { 'README.md' }

      before { git_annex.drop({ content: filename }, cloned_repo_path) }

      it 'only drops README.md' do
        expect(git.annex.whereis[filename].here?).to be false # README.md dropped.
        expect(git.annex.whereis[new_file].here?).to be true # Other files NOT dropped.
      end
    end

    context 'when imaging user configured' do
      it 'changes permissions'
    end
  end

  describe '#remove_working_directory' do
    let!(:cloned_repo_path) { git_annex.clone }
    let!(:cloned_repo) { ExtendedGit.open(cloned_repo_path) }
    let!(:cloned_repo_annex_uuid) { cloned_repo.config('annex.uuid') }

    before do
      cloned_repo.annex.get('README.md')
      git_annex.remove_working_directory(cloned_repo_path)
    end

    context 'when cloning repository again' do
      let(:temp_location) { Rails.root.join('tmp', 'test_directory') }
      let(:new_clone) do
        new_clone = ExtendedGit.clone(git_annex.remote_repo_path, temp_location)
        new_clone.annex.init
        new_clone
      end

      after { FileUtils.remove_dir(new_clone.dir.path) }

      it 'does not have references to old working repo' do
        expect(
          new_clone.annex.whereis['README.md'].locations.map(&:uuid)
        ).not_to include cloned_repo_annex_uuid
      end
    end

    it 'deletes directory' do
      expect(File.directory?(cloned_repo_path)).to be false
    end
  end

  describe '#get' do
    let(:cloned_repo_path) { git_annex.clone }
    let(:git) { ExtendedGit.open(cloned_repo_path) }

    let(:first_file) { File.join('data', 'assets', 'new_file.txt') }
    let(:second_file) { File.join('data', 'assets', 'other_new_file.txt') }

    # Adding files to remote and special remote, then dropping them to test `get`.
    before do
      [first_file, second_file].each do |file|
        new_file_path = File.join(cloned_repo_path, file)
        File.open(new_file_path, 'w') { |f| f.write("New file -- #{file}") }
        git.add(new_file_path)
      end
      git_annex.commit('Adding new files.', cloned_repo_path)
      git_annex.push({}, cloned_repo_path)
      git_annex.drop({}, cloned_repo_path)
    end

    it 'retrieves a file' do
      expect(File.exist?(File.join(cloned_repo_path, 'README.md'))).to be false
      git_annex.get({ location: 'README.md'}, cloned_repo_path)
      expect(File.exist?(File.join(cloned_repo_path, 'README.md'))).to be true
      expect(git.annex.whereis['README.md'].here?).to be true
    end

    it 'retrieves all files within directory' do
      expect(git.annex.whereis.any?(&:here?)).to be false
      git_annex.get({ location: File.join(cloned_repo_path, 'data', 'assets') }, cloned_repo_path)
      FileUtils.chdir(cloned_repo_path) # `get` changes the directory, have to change it back.
      expect(git.annex.whereis[first_file].here?).to be true
      expect(git.annex.whereis[second_file].here?).to be true
      expect(git.annex.whereis['README.md'].here?).to be false
    end

    it 'retrieves all files' do
      expect(git.annex.whereis.any?(&:here?)).to be false
      git_annex.get({ location: '.' }, cloned_repo_path)
      FileUtils.chdir(cloned_repo_path) # `get` changes the directory, have to change it back.
      expect(git.annex.whereis.all?(&:here?)).to be true
    end
  end

  describe '#unlock' do
    let(:cloned_repo_path) { git_annex.clone }
    let(:git) { ExtendedGit.open(cloned_repo_path) }

    it 'unlocks file' do
      expect(git.annex.whereis(locked: true).includes_file?('README.md')).to be true
      git_annex.unlock({ content: 'README.md' }, cloned_repo_path)
      expect(git.annex.whereis(unlocked: true).includes_file?('README.md')).to be true
    end
  end

  describe '#lock' do
    let(:cloned_repo_path) { git_annex.clone }
    let(:git) { ExtendedGit.open(cloned_repo_path) }

    before { git.annex.unlock('README.md') }

    it 'locks file' do
      expect(git.annex.whereis(unlocked: true).includes_file?('README.md')).to be true
      git_annex.lock('README.md', cloned_repo_path)
      expect(git.annex.whereis(locked: true).includes_file?('README.md')).to be true
    end
  end
end
