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
      let(:origin_location) { File.join(Settings.digital_object.remotes_path, repo.names.git) }

      it 'should not create a remote in that location' do
        pending('ticked in: repo/bulwark#5')
        FileUtils.mkdir_p(origin_location)
        expect(ExtendedGit.is_git_directory?(origin_location)).to be false
        repo.save
        expect(ExtendedGit.is_git_directory?(origin_location)).to be false
      end
    end

    context 'when creating git repository' do
      let(:origin_location) { File.join(Settings.digital_object.remotes_path, repo.names.git) }

      it 'creates remote in correct location' do
        expect(File.directory?(origin_location)).to be true
        expect(ExtendedGit.is_git_directory?(origin_location)).to be true
      end

      context 'when cloning git repo' do
        let!(:working_repo) { ExtendedGit.clone(origin_location, repo.names.directory, path: Rails.root.join('tmp')) }
        let(:special_remote_name) { Settings.digital_object.special_remote.name }

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
            File.join(Settings.digital_object.special_remote.directory, repo.unique_identifier.bucketize)
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
      ceph_config = double('special_remote', protocol: 'https://', host: 'storage.library.upenn.edu')
      allow(Settings.digital_object).to receive(:special_remote).and_return(ceph_config)
    end

    it 'return expected thumbnail_link' do
      expect(repo.thumbnail_link).to eql "https://storage.library.upenn.edu/#{repo.names.bucket}/file_one.jpeg"
    end
  end

  describe '#thumbnail_location' do
    context 'when new_format is true' do
      let(:repo) { FactoryBot.create(:repo, :with_assets) }

      before { repo.update(thumbnail: repo.assets.first.filename) }

      it 'returns correct thumbnail_location' do
        thumbnail_location = repo.assets.find_by(filename: repo.thumbnail).thumbnail_file_location
        expect(repo.thumbnail_location).to eql "#{repo.names.bucket}/#{thumbnail_location}"
      end
    end

    context `when new_format is false` do
      let(:repo) { FactoryBot.create(:repo, thumbnail_location: 'a_cool_location') }

      it 'returns correct thumbnail_location' do
        expect(repo.thumbnail_location).to eql "a_cool_location"
      end
    end
  end

  describe '#solr_document' do
    let(:repo) { FactoryBot.create(:repo, :with_assets, :with_descriptive_metadata, :published) }
    let(:current_time) { Time.current }
    let(:document) do
      {
        "active_fedora_model_ssi" => "Manuscript",
        "bibnumber_ssi" => nil,
        "call_number_sim" => ["Ms. Coll 200 box 180 folder 8576 item 2"],
        "call_number_ssim" => ["Ms. Coll 200 box 180 folder 8576 item 2"],
        "call_number_tesim" => ["Ms. Coll 200 box 180 folder 8576 item 2"],
        "collection_sim" => ["Marian Anderson Papers (University of Pennsylvania)"],
        "collection_ssim" => ["Marian Anderson Papers (University of Pennsylvania)"],
        "collection_tesim" => ["Marian Anderson Papers (University of Pennsylvania)"],
        "corporate_name_sim" => ["McMillin Academic Theater, Columbia University", "Hurok Attractions, Inc. ", "Institute of Arts and Sciences, Columbia University"],
        "corporate_name_ssim" => ["McMillin Academic Theater, Columbia University", "Hurok Attractions, Inc. ", "Institute of Arts and Sciences, Columbia University"],
        "corporate_name_tesim" => ["McMillin Academic Theater, Columbia University", "Hurok Attractions, Inc. ", "Institute of Arts and Sciences, Columbia University"],
        "date_sim" => ["1941-12-20T20:30:00"],
        "date_ssim" => ["1941-12-20T20:30:00"],
        "date_tesim" => ["1941-12-20T20:30:00"],
        "description_sim" => ["Handel, George Frideric: Tutta raccolta ancor; Martini, Johann Paul Aegidius: Plaisir d'amour; Bassani, Giovanni Battista: Dormi, bella, dormi tu?; Carissimi, Giacomo: No, no, non si speri!; Schubert, Franz: Fragment aus dem Aeschylus, D 450; Schubert, Franz: Fischerweise : D881; Schubert, Franz: Der Doppelgänger; Schubert, Franz: Der Erlkönig; Massenet, Jules: Pleurez, pleurez mes yeux, from Le Cid; Dvořák, Antonín: Als die alte Mutter: Songs my mother taught me; Rachmaninoff, Sergei: Christ is risen : op. 26, no. 6; Quilter, Roger: O mistress mine; Quilter, Roger: Blow, blow, thou winter wind; Burleigh, Harry Thacker (arr.): Go down, Moses: Let my people go; Lawrence, William (arr.): Let us break bread together; Boatner, Edward (arr.): Trampin'; Johnson, Hall (arr.): Honor, honor"],
        "description_ssim" => ["Handel, George Frideric: Tutta raccolta ancor; Martini, Johann Paul Aegidius: Plaisir d'amour; Bassani, Giovanni Battista: Dormi, bella, dormi tu?; Carissimi, Giacomo: No, no, non si speri!; Schubert, Franz: Fragment aus dem Aeschylus, D 450; Schubert, Franz: Fischerweise : D881; Schubert, Franz: Der Doppelgänger; Schubert, Franz: Der Erlkönig; Massenet, Jules: Pleurez, pleurez mes yeux, from Le Cid; Dvořák, Antonín: Als die alte Mutter: Songs my mother taught me; Rachmaninoff, Sergei: Christ is risen : op. 26, no. 6; Quilter, Roger: O mistress mine; Quilter, Roger: Blow, blow, thou winter wind; Burleigh, Harry Thacker (arr.): Go down, Moses: Let my people go; Lawrence, William (arr.): Let us break bread together; Boatner, Edward (arr.): Trampin'; Johnson, Hall (arr.): Honor, honor"],
        "description_tesim" => ["Handel, George Frideric: Tutta raccolta ancor; Martini, Johann Paul Aegidius: Plaisir d'amour; Bassani, Giovanni Battista: Dormi, bella, dormi tu?; Carissimi, Giacomo: No, no, non si speri!; Schubert, Franz: Fragment aus dem Aeschylus, D 450; Schubert, Franz: Fischerweise : D881; Schubert, Franz: Der Doppelgänger; Schubert, Franz: Der Erlkönig; Massenet, Jules: Pleurez, pleurez mes yeux, from Le Cid; Dvořák, Antonín: Als die alte Mutter: Songs my mother taught me; Rachmaninoff, Sergei: Christ is risen : op. 26, no. 6; Quilter, Roger: O mistress mine; Quilter, Roger: Blow, blow, thou winter wind; Burleigh, Harry Thacker (arr.): Go down, Moses: Let my people go; Lawrence, William (arr.): Let us break bread together; Boatner, Edward (arr.): Trampin'; Johnson, Hall (arr.): Honor, honor"],
        "format_sim" => ["2 p. ; 24 cm"],
        "format_ssim" => ["2 p. ; 24 cm"],
        "format_tesim" => ["2 p. ; 24 cm"],
        "geographic_subject_sim" => ["New York City, New York, United States"],
        "geographic_subject_ssim" => ["New York City, New York, United States"],
        "geographic_subject_tesim" => ["New York City, New York, United States"],
        "id" => repo.names.fedora,
        "has_images_bsi" => "T",
        "has_model_ssim" => ["Manuscript"],
        "item_type_sim" => ["Programs"],
        "item_type_ssim" => ["Programs"],
        "item_type_tesim" => ["Programs"],
        "language_sim" => ["English"],
        "language_ssim" => ["English"],
        "language_tesim" => ["English"],
        "personal_name_sim" => ["Anderson, Marian", "Rupp, Franz", "Hurok, Sol"],
        "personal_name_ssim" => ["Anderson, Marian", "Rupp, Franz", "Hurok, Sol"],
        "personal_name_tesim" => ["Anderson, Marian", "Rupp, Franz", "Hurok, Sol"],
        "rights_sim" => ["https://creativecommons.org/publicdomain/zero/1.0/"],
        "rights_ssim" => ["https://creativecommons.org/publicdomain/zero/1.0/"],
        "rights_tesim" => ["https://creativecommons.org/publicdomain/zero/1.0/"],
        "system_create_dtsi" => repo.first_published_at.utc.iso8601,
        "system_modified_dtsi" => repo.last_published_at.utc.iso8601,
        "thumbnail_location_ssi" => nil,
        "title_sim" => ["[Concert program 1941-12-20]"],
        "title_ssim" => ["[Concert program 1941-12-20]"],
        "title_tesim" => ["[Concert program 1941-12-20]"],
        "unique_identifier_tesim" => repo.unique_identifier
      }
    end

    it 'generates expected document' do
      expect(repo.solr_document).to eql document
    end
  end

  describe '#publish' do
    let(:repo) { FactoryBot.create(:repo, :with_assets, :with_descriptive_metadata) }
    let(:current_time) { Time.current }

    context 'when solr is available' do
      it 'return true' do
        expect(repo.publish).to be true
      end

      it 'adds document to solr' do
        repo.publish
        solr = RSolr.connect(url: Settings.solr.url)
        response = solr.get('select', params: { id: repo.names.fedora })
        expect(response['response']['numFound']).to be 1
      end

      it 'sets first_published_at and last_published_at' do
        travel_to(current_time) do
          repo.publish
          repo.reload
          expect(repo.published).to be true
          expect(repo.first_published_at).to be_within(1.second).of current_time
          expect(repo.last_published_at).to be_within(1.second).of current_time
        end
      end
    end

    context 'when solr is unavailable' do
      before do
        allow(Settings).to receive(:solr).and_return({})
      end

      it 'does not save first_published_at or last_published_at' do
        repo.publish
        repo.reload
        expect(repo.published).to be false
        expect(repo.first_published_at).to be nil
        expect(repo.last_published_at).to be nil
      end

      it 'returns false' do
        expect(repo.publish).to be false
      end
    end

    context 'when publishing for a second time' do
      let(:first_publish) { current_time - 1.day }

      before do
        repo.update(
          first_published_at: first_publish,
          last_published_at: first_publish
        )
      end

      it 'only updates_last_published_at' do
        travel_to(current_time) do
          expect(repo.publish).to be true
          expect(repo.published).to be true
          expect(repo.last_published_at).to be_within(1.second).of current_time
          expect(repo.first_published_at).to be_within(1.second).of first_publish
        end
      end
    end
  end

  describe '#unpublish' do
    let(:repo) { FactoryBot.create(:repo, :with_assets, :with_descriptive_metadata) }

    context 'when Repo is not yet published' do
      it 'returns false and makes no changes' do
        outcome = repo.unpublish
        repo.reload
        expect(outcome).to be false
        expect(repo.published).to be false
      end
    end

    context 'when Repo is published' do
      before { repo.publish }

      context 'when solr is available' do
        it 'removes document from solr' do
          unpublished = repo.unpublish
          solr = RSolr.connect(url: Settings.solr.url)
          response = solr.get('select', params: { id: repo.names.fedora })
          expect(response['response']['numFound']).to be 0
          expect(unpublished).to be true
          expect(repo.published).to be false
        end
      end

      context 'when solr is unavailable' do
        before do
          allow(Settings).to receive(:solr).and_return({})
        end

        it 'does not alter published, first_published_at or last_published_at' do
          first_published_at = repo.first_published_at
          repo.unpublish
          repo.reload
          expect(repo.published).to be true
          expect(repo.first_published_at).to be_within(1.second).of first_published_at
          expect(repo.last_published_at).to be_within(1.second).of first_published_at
        end

        it 'returns false' do
          expect(repo.unpublish).to be false
        end
      end
    end
  end

  describe '#create_iiif_manifest' do
    before do
      allow(Settings.iiif).to receive(:image_server).and_return('https://images.library.upenn/iiif/2')
    end

    let(:repo) do
      FactoryBot.create(:repo, :with_descriptive_metadata, :with_structural_metadata)
    end

    context 'when assets missing derivatives' do
      before do
        repo.assets.each { |a| a.update!(access_file_location: nil) }
      end

      it 'raises expected error' do
        expect { repo.create_iiif_manifest }.to raise_error /missing derivatives: #{repo.assets.map(&:filename).join(', ')}/
      end
    end

    context 'when missing title' do
      before do
        metadata_source = repo.descriptive_metadata.user_defined_mappings
        metadata_source.update!(user_defined_mappings: {})
      end

      it 'raises expected error' do
        expect { repo.create_iiif_manifest }.to raise_error /title is blank/
      end
    end

    context 'when images are present' do
      let(:expected_payload) do
        first_asset = repo.assets.find_by(filename: repo.structural_metadata.user_defined_mappings['sequence'][0]['filename'])
        second_asset = repo.assets.find_by(filename: repo.structural_metadata.user_defined_mappings['sequence'][1]['filename'])
        {
          id: repo.names.fedora,
          title: "[Concert program 1941-12-20]",
          viewing_direction: "left-to-right",
          viewing_hint: "paged",
          image_server: "https://images.library.upenn/iiif/2",
          sequence: [
            {
              file: repo.names.bucket + '%2F' + first_asset.access_file_location,
              label: 'Page 0',
              table_of_contents: [{ text: 'Image 0' }],
              additional_downloads: [
                {
                  link: first_asset.original_file_link,
                  label: "Original File",
                  size: first_asset.size,
                  format: 'image/tiff'
                }
              ]
            },
            {
              file: repo.names.bucket + '%2F' + second_asset.access_file_location,
              label: 'Page 1',
              table_of_contents: [{ text: 'Image 1' }],
              additional_downloads: [
                {
                  link: second_asset.original_file_link,
                  label: "Original File",
                  size: second_asset.size,
                  format: 'image/tiff'
                }
              ]
            }
          ]
        }.to_json
      end

      it 'makes expected call to MarmiteClient' do
        expect(MarmiteClient).to receive(:iiif_presentation).with(repo.names.fedora, expected_payload)
        repo.create_iiif_manifest
      end
    end
  end
end
