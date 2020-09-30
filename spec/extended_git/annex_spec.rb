require 'rails_helper'

RSpec.describe ExtendedGit::Annex, type: :model do
  let(:repo_name) { Faker::File.dir(segment_count: 1) }
  let(:remote_origin) { Rails.root.join('tmp', repo_name + '.git').to_s }
  let(:working_directory) { Rails.root.join('tmp', repo_name) }

  let(:git) { ExtendedGit.clone(remote_origin, repo_name, path: Rails.root.join('tmp')) }

  shared_context 'add readme to repository' do
    let(:readme) { 'README.txt' }

    before do
      temp = ExtendedGit.clone(remote_origin, repo_name + '_temp', path: Rails.root.join('tmp'))
      temp.annex.init
      File.open(File.join(temp.dir.path, readme), 'w') do |f|
        f.write("README for #{repo_name}")
      end
      temp.annex.add(readme)
      temp.commit("Adding #{readme}")
      temp.push('origin', 'master') # TODO: Do we need this?
      temp.push('origin', 'git-annex') # TODO: Do we need this?
      temp.annex.sync(content: true)
      temp.annex.uninit
      FileUtils.rm_r(temp.dir.path)
    end
  end

  shared_context 'add directory special remote' do
    let(:special_remote_name) { 'local_directory' }
    let(:special_remote_dir) { Rails.root.join('tmp', 'test_special_remote', repo_name).to_s }

    before do
      FileUtils.mkdir_p(special_remote_dir)
      temp = ExtendedGit.clone(remote_origin, repo_name + '_temp', path: Rails.root.join('tmp'))
      temp.annex.init
      temp.annex.initremote(special_remote_name, type: 'directory', directory: special_remote_dir, encryption: 'none')
      temp.annex.sync
      temp.annex.uninit
      FileUtils.rm_r(temp.dir.path)
    end

    after do
      FileUtils.chmod_R(0755, special_remote_dir)
      FileUtils.rm_r(special_remote_dir)
    end
  end

  before do
    ExtendedGit.init(nil, repository: remote_origin, bare: true)
  end

  after do
    # Remove working directory
    git.annex.uninit if git.config('annex.uuid').present?
    FileUtils.rm_r(working_directory)

    # Remove remote origin
    FileUtils.chmod_R(0755, remote_origin)
    FileUtils.rm_r(remote_origin)
  end

  describe '#init' do
    it 'initializes repository with description' do
      git.annex.init('test_working_directory')
      expect(git.annex.info.remote?('test_working_directory')).to be true
    end

    it 'initializes repository with git annex' do
      git.annex.init
      expect(git.config('annex.uuid')).not_to be nil
    end
  end

  describe '#version' do
    it 'returns full version output' do
      expect(git.annex.version).to match(/^git-annex version: \d+\.\d+\.\d+$/)
    end

    it 'returns raw version output' do
      expect(git.annex.version(raw: true)).to match(/^\d+\.\d+\.\d+$/)
    end
  end

  describe '#add' do
    # Here because there's a problem with `git.status`, it doesn't work
    # when there isn't an initial commit.
    include_context 'add readme to repository'

    context 'when adding non-dotfile' do
      let(:filename) { 'new_test_file.txt' }
      let(:filepath) { File.join(working_directory, filename) }

      before do
        git.annex.init
        File.open(filepath, 'w') { |f| f.write("New file -- #{filename}") }
      end

      it 'adds file to be committed' do
        git.annex.add(filename)
        expect(git.status.added?(filename)).to be true
        expect(git.annex.whereis.includes_file?(filename)).to be true
      end

      it 'adds entire directory to be committed' do
        git.annex.add('.')
        expect(git.status.added?(filename)).to be true
        expect(git.annex.whereis.includes_file?(filename)).to be true
      end
    end

    context 'when adding dotfile' do
      let(:filename) { '.secret_file' }
      let(:filepath) { File.join(working_directory, filename) }

      before do
        git.annex.init
        File.open(filepath, 'w') { |f| f.write("very important secret") }
      end

      it 'adds file to be committed via git annex' do
        git.annex.add(filename, include_dotfiles: true)
        expect(git.status.added?(filename)).to be true
        expect(git.annex.whereis.includes_file?(filename)).to be true
      end

      it 'adds file to be committed via git' do
        git.annex.add(filename)
        expect(git.status.added?(filename)).to be true
        expect(git.annex.whereis.includes_file?(filename)).to be false
      end
    end
  end

  describe '#get' do
    include_context 'add readme to repository'

    before { git.annex.init }

    it 'retrieves file from remote' do
      expect { git.annex.get(readme) }.not_to raise_error
      expect(File.exist?(File.join(git.dir.path, readme))).to be true
    end
  end

  describe '#enableremote' do
    include_context 'add readme to repository'
    include_context 'add directory special remote'

    before do
      git.annex.init
      git.annex.enableremote(special_remote_name, directory: special_remote_dir)
    end

    it 'enables directory remote' do
      expect(git.config('remote.local_directory.annex-uuid')).to be_truthy
    end
  end

  describe '#initremote' do
    include_context 'add readme to repository'
    let(:special_remote_name) { 'new_directory' }
    let(:special_remote_dir) { Rails.root.join('tmp', 'test_special_remote', repo_name).to_s }

    before do
      FileUtils.mkdir_p(special_remote_dir)
      git.annex.init
    end

    after do
      FileUtils.chmod_R(0755, special_remote_dir)
      FileUtils.rm_r(special_remote_dir)
    end

    it 'adds new special remote' do
      expect {
        git.annex.initremote(special_remote_name, type: 'directory', directory: special_remote_dir, encryption: 'none')
      }.not_to raise_error
      expect(git.annex.info.remote?(special_remote_name)).to be true
      expect(git.annex.info.remote(special_remote_name).directory).to eql special_remote_dir
    end
  end

  # TODO: Not sure how to test that this works. For now just testing that errors aren't
  # raised.
  describe '#fsck' do
    include_context 'add readme to repository'
    include_context 'add directory special remote'

    before do
      git.annex.init
      git.annex.enableremote(special_remote_name, directory: special_remote_dir)
    end

    it 'checks files' do
      expect { git.annex.fsck }.not_to raise_error
    end

    it 'checks files with --fast flag' do
      expect { git.annex.fsck(fast: true) }.not_to raise_error
    end

    it 'checks files in special remote with --from flag' do
      expect { git.annex.fsck(from: special_remote_name) }.not_to raise_error
    end
  end

  describe '#drop' do
    include_context 'add readme to repository'
    let(:readme_path) { File.join(git.dir.path, readme) }

    before do
      git.annex.init
      git.annex.get(readme)
    end

    it 'drops file' do
      expect(File.exist?(readme_path)).to be true
      git.annex.drop(readme)
      expect(File.exist?(readme_path)).to be false
    end

    it 'drops everything' do
      git.annex.drop
      expect(File.exist?(readme_path)).to be false
    end
  end

  describe '#testremote' do
    include_context 'add readme to repository'
    include_context 'add directory special remote'

    before do
      git.annex.init
      git.annex.enableremote(special_remote_name, directory: special_remote_dir)
    end

    it 'testremote' do
      expect { git.annex.testremote(special_remote_name) }.not_to raise_error
    end
  end

  describe '#whereis' do
    include_context 'add readme to repository'

    before { git.annex.init }

    it 'returns information about readme' do
      result = git.annex.whereis(readme)
      expect(result).to be_a ExtendedGit::WhereIs
      expect(result[readme]).to be_a ExtendedGit::WhereIs::WhereIsFile
    end
  end

  describe '#info' do
    before { git.annex.init }

    it 'returns information' do
      expect(git.annex.info).to be_a ExtendedGit::RepositoryInfo
    end
  end

  describe '#lock' do
    include_context 'add readme to repository'

    before do
      git.annex.init
      git.annex.get(readme)
      git.annex.unlock(readme)
    end

    it 'locks file' do
      expect(git.annex.whereis(unlocked: true).includes_file?(readme)).to be true
      git.annex.lock(readme)
      expect(git.annex.whereis(locked: true).includes_file?(readme)).to be true
    end
  end

  describe '#unlocked' do
    include_context 'add readme to repository'

    before do
      git.annex.init
      git.annex.get(readme)
    end

    it 'unlock file' do
      expect(git.annex.whereis(locked: true).includes_file?(readme)).to be true
      git.annex.unlock(readme)
      expect(git.annex.whereis(unlocked: true).includes_file?(readme)).to be true
    end
  end

  describe '#sync' do
    include_context 'add readme to repository'
    include_context 'add directory special remote'

    before do
      git.annex.init
      git.annex.enableremote(special_remote_name, directory: special_remote_dir)
    end

    it 'syncs content' do
      expect { git.annex.sync(content: true) }.not_to raise_error
      expect(git.annex.whereis[readme].here?).to be true
      expect(git.annex.whereis[readme].locations.map(&:description)).to include("[#{special_remote_name}]")
    end
  end

  describe '#copy' do
    include_context 'add readme to repository'
    include_context 'add directory special remote'

    before do
      git.annex.init
      git.annex.get(readme)
      git.annex.enableremote(special_remote_name, directory: special_remote_dir)
    end

    it 'copies file to special remote' do
      expect { git.annex.copy(readme, to: special_remote_name) }.not_to raise_error
      expect(git.annex.whereis[readme].locations.map(&:description)).to include("[#{special_remote_name}]")
    end
  end
end
