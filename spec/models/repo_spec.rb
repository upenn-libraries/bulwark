require 'rails_helper'

RSpec.describe Repo, type: :model do
  include_context 'stub successful EZID requests'

  it 'has a valid factory' do
    expect(FactoryBot.create(:repo)).to be_valid
  end

  describe '#new' do
    it 'requires a human_readable_name' do
      expect(FactoryBot.build(:repo, human_readable_name: nil)).not_to be_valid
    end

    it 'requires file extensions' do
      expect(FactoryBot.build(:repo, file_extensions: nil)).not_to be_valid
    end
  end

  describe '#create' do
    let(:repo) { FactoryBot.create(:repo) }

    context 'when an ark is not present' do
      let(:repo) { FactoryBot.create(:repo, unique_identifier: nil) }

      it 'mints an ark' do
        expect(repo.unique_identifier).not_to be_nil
        expect(repo.unique_identifier).to match /^ark\:\/.+\/.+$/
      end
    end

    context 'when ark is present' do
      let(:identifier) { 'ark:/81431/p3020pc5b' }
      let(:repo) { FactoryBot.create(:repo, unique_identifier: identifier) }

      it 'does not override ark' do
        expect(repo.unique_identifier).to eql identifier
      end
    end

    context 'when a directory is already present at remote location' do
      let(:repo) { FactoryBot.build(:repo, unique_identifier: 'ark:/99999fk4/d80p529') }
      let(:origin_location) { File.join(Utils.config[:assets_path], repo.names.git) }

      it 'should not create a remote in that location' do
        pending('ticked in: repo/bulwark#5')
        FileUtils.mkdir_p(origin_location)
        expect(ExtendedGit.is_git_directory?(origin_location)).to be false
        repo.save
        expect(ExtendedGit.is_git_directory?(origin_location)).to be false
      end
    end

    context 'when creating git repository' do
      let(:origin_location) { File.join(Utils.config[:assets_path], repo.names.git) }

      it 'creates remote in correct location' do
        expect(File.directory?(origin_location)).to be true
        expect(ExtendedGit.is_git_directory?(origin_location)).to be true
      end

      context 'when cloning git repo' do
        let!(:working_repo) { ExtendedGit.clone(origin_location, repo.names.directory, path: Rails.root.join('tmp')) }
        let(:special_remote_name) { Bulwark::Config.special_remote[:name] }

        after { FileUtils.remove_dir(working_repo.dir.path) }

        it 'contains expected files' do
          expect(working_repo.status.map(&:path)).to match_array([
            '.derivs/.keep',
            '.repoadmin/bin/init.sh',
            '.repoadmin/fs_semantics',
            'README.md',
            'data/assets/.keep',
            'data/metadata/.keep'
          ])
        end

        it 'special remote is configured in remote repo' do
          expect(working_repo.annex.info.remote?('local')).to be true
        end

        context 'when setting up special remote' do
          let(:special_remote_directory) do
            File.join(Bulwark::Config.special_remote[:directory], repo.unique_identifier.bucketize)
          end
          let(:readme_path) { File.join(working_repo.dir.path, 'README.md') }

          before do
            working_repo.annex.init
            working_repo.annex.enableremote(
              special_remote_name, directory: special_remote_directory
            )
            working_repo.annex.fsck(from: special_remote_name)
          end

          context 'when retrieving files from special remote' do
            after { working_repo.annex.drop(readme_path) }

            it 'successfully gets file' do
              expect { working_repo.annex.get('README.md') }.not_to raise_error
              expect(File.exist?(readme_path)).to be true
            end
          end

          it 'can successfully run testremote on special remote' do
            expect { working_repo.annex.testremote(special_remote_name, fast: true) }.not_to raise_error
          end
        end
      end
    end
  end

  describe '.names'

  describe '#_generate_readme' do
    let(:repo) { FactoryBot.create(:repo) }
    let(:directory) { Rails.root.join('tmp') }
    let!(:readme_path) { repo.send('_generate_readme', directory) }

    after { File.delete(readme_path) }

    it 'generates file in correct location' do
      expect(readme_path).to eql File.join(directory, 'README.md')
      expect(File.exists?(readme_path)).to be true
    end
  end

  describe '#_build_and_populate_directories' do
    let(:repo) { FactoryBot.create(:repo) }
    let(:directory) { Rails.root.join('tmp', 'test_directory') }

    before do
      FileUtils.mkdir_p(directory)
      repo.send('_build_and_populate_directories', directory)
    end

    after { FileUtils.remove_dir(directory) }

    it 'creates README.md file' do
      expect(File.exist?(File.join(directory, 'README.md')))
    end

    it 'creates init script' do
      expect(File.exist?(File.join(directory, '.repoadmin', 'bin', 'init.sh'))).to be true
    end

    it 'creates expected directories' do
      expect(File.directory?(File.join(directory, '.derivs'))).to be true
      expect(File.directory?(File.join(directory, '.repoadmin'))).to be true
      expect(File.directory?(File.join(directory, 'data'))).to be true
      expect(File.directory?(File.join(directory, 'data', 'metadata'))).to be true
      expect(File.directory?(File.join(directory, 'data', 'assets'))).to be true
    end

    it 'creates expected .keep files' do
      expect(File.exist?(File.join(directory, 'data', 'metadata', '.keep'))).to be true
      expect(File.exist?(File.join(directory, 'data', 'assets', '.keep'))).to be true
      expect(File.exist?(File.join(directory, '.derivs', '.keep'))).to be true
    end
  end

  describe '#structural_metadata' do
    let(:repo) { FactoryBot.create(:repo) }
    before do
      MetadataSource.create(source_type: 'kaplan_structural', metadata_builder: repo.metadata_builder)
      repo.reload
    end

    it 'return expected metadata_source' do
      expect(repo.structural_metadata).to be_a MetadataSource
      expect(repo.structural_metadata.source_type).to eql 'kaplan_structural'
    end
  end

  describe '#descriptive_metadata' do
    let(:repo) { FactoryBot.create(:repo) }
    before do
      MetadataSource.create(source_type: 'pqc', metadata_builder: repo.metadata_builder)
      repo.reload
    end

    it 'return expected metadata_source' do
      expect(repo.descriptive_metadata).to be_a MetadataSource
      expect(repo.descriptive_metadata.source_type).to eql 'pqc'
    end
  end

  describe '#thumbnail_link' do
    let(:repo) { FactoryBot.create(:repo) }

    before do
      repo.update!(thumbnail_location: "/#{repo.names.bucket}/file_one.jpeg")
      ceph_config = double('ceph_config', read_protocol: 'https://', read_host: 'storage.library.upenn.edu')
      allow(Utils::Storage::Ceph).to receive(:config).and_return(ceph_config)
    end

    it 'return expected thumbnail_link' do
      expect(repo.thumbnail_link).to eql "https://storage.library.upenn.edu/#{repo.names.bucket}/file_one.jpeg"
    end
  end
end
