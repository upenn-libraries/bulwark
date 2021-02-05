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
        directive: 'object_one',
        assets: { drive: 'test', path: 'object_one' },
        metadata: {
          'collection' => ['Arnold and Deanne Kaplan Collection of Early American Judaica (University of Pennsylvania)'],
          'call_number' => ['Arc.MS.56'],
          'item_type' => ['Trade cards'],
          'language' => ['English'],
          'date' => ['undated'],
          'corporate_name' => ['J. Rosenblatt & Co.'],
          'geographic_subject' => ['Baltimore, Maryland, United States', 'Maryland, United States'],
          'description' =>['J. Rosenblatt & Co.: Importers: Earthenware, China, Majolica, Novelties', '32 South Howard Street, Baltimore, MD'],
          'rights' => ['http://rightsstatements.org/page/NoC-US/1.0/?'],
          'subject' => ['House furnishings', 'Jewish merchants', 'Trade cards (advertising)'],
          'title' => ['Trade card; J. Rosenblatt & Co.; Baltimore, Maryland, United States; undated;']
        },
        structural: { 'filenames' => 'front.tif; back.tif' },
        created_by: User.find_by(email: 'admin@example.com')
      ).process
    end
  end
end
