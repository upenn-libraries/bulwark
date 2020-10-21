namespace :bulwark do
  desc 'Start development/test environment'
  task start: :environment do
    # First, check git-annex and imagemagick are installed.
    raise 'git-annex not found. Please install git-annex.' unless ExtendedGit.git_annex_installed?
    raise 'imagemagick not found. Please install imagemagick' unless MiniMagick.imagemagick?

    # Start lando
    system('lando start')

    # Migrate test and development databases
    system('rake db:setup RAILS_ENV=development')
    system('rake db:setup RAILS_ENV=test')
  end


  desc 'Cleans development/test environment'
  task clean: :environment do
    system('lando destroy -y')
  end

  desc 'Stop development/test environment'
  task stop: :environment do
    system('lando stop -y')
  end
end
