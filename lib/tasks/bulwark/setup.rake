# frozen_string_literal: true

namespace :bulwark do
  namespace :setup do
    desc 'Creates an admin user, to be used in local development environment'
    task create_admin: :environment do
      User.find_or_create_by!(email: 'admin@example.com') do |admin|
        admin.password = 'theadmin'
        admin.password_confirmation = 'theadmin'
      end
    end

    desc 'Loads one digital object, to be used in local development environment'
    task create_digital_object: :create_admin do
      Bulwark::Import.new(
        action: Bulwark::Import::CREATE,
        directive_name: 'object_one',
        assets: { drive: 'test', path: 'object_one' },
        metadata: {
          'collection' => ['Arnold and Deanne Kaplan Collection of Early American Judaica (University of Pennsylvania)'],
          'call_number' => ['Arc.MS.56'],
          'item_type' => ['Trade cards'],
          'language' => ['English'],
          'date' => ['undated'],
          'corporate_name' => ['J. Rosenblatt & Co.'],
          'geographic_subject' => ['Baltimore, Maryland, United States', 'Maryland, United States'],
          'description' => ['J. Rosenblatt & Co.: Importers: Earthenware, China, Majolica, Novelties', '32 South Howard Street, Baltimore, MD'],
          'rights' => ['http://rightsstatements.org/page/NoC-US/1.0/?'],
          'subject' => ['House furnishings', 'Jewish merchants', 'Trade cards (advertising)'],
          'title' => ['Trade card; J. Rosenblatt & Co.; Baltimore, Maryland, United States; undated;']
        },
        structural: { 'filenames' => 'front.tif; back.tif' },
        created_by: User.find_by(email: 'admin@example.com')
      ).process
    end

    desc 'Loads a digital object with a/v content, to be used in local development environment'
    task create_av_digital_object: :create_admin do
      # This is a very roundabout way to create a digital object with sample content. The
      # Bulwark::Import class does not support loading pre-created derivatives or generating derivatives for
      # audio files. Eventually, this will be supported and this code can be updated.

      # Create baseline repo
      repo = Repo.create(
        human_readable_name: 'Test Audio File',
        metadata_subdirectory: 'metadata',
        assets_subdirectory: 'assets',
        file_extensions: Bulwark::Config.digital_object[:file_extensions],
        metadata_source_extensions: ['csv'],
        preservation_filename: 'preservation.xml',
        new_format: true,
        created_by: User.find_by(email: 'admin@example.com')
      )

      # Adding audio derivatives manually
      git = repo.clone

      fixtures_path = Rails.root.join('spec', 'fixtures', 'example_bulk_imports', 'object_four')
      FileUtils.mkdir(File.join(repo.clone_location, repo.derivatives_subdirectory, 'access'))
      FileUtils.cp(File.join(fixtures_path, 'bell.mp3'), File.join(repo.clone_location, repo.derivatives_subdirectory, 'access', 'bell.mp3'))

      git.annex.add('.', include_dotfiles: true)
      git.commit("Adding audio derivatives")
      git.push('origin', 'master')
      git.push('origin', 'git-annex')
      git.annex.sync(content: true)

      repo.delete_clone

      # Updating item to add metadata files and asset etc.
      Bulwark::Import.new(
        action: 'update',
        unique_identifier: repo.unique_identifier,
        structural: { filenames: 'bell.wav' },
        metadata: { title: ['A new audio item'] },
        assets: { drive: 'test', path: 'object_four/bell.wav' },
        created_by: User.find_by(email: 'admin@example.com')
      ).process
    end
  end
end
