namespace :bulwark do
  desc 'Start development/test environment'
  task start: :environment do
    # First, check git-annex and imagemagick are installed.
    raise 'git-annex not found. Please install git-annex.' unless ExtendedGit.git_annex_installed?
    raise 'imagemagick not found. Please install imagemagick' unless MiniMagick.imagemagick?

    # Start lando
    system('lando start')

    # Create databases, if they aren't present.
    system('rake db:create:all')

    # Migrate test and development databases
    system('RAILS_ENV=development rake db:migrate')
    system('RAILS_ENV=test rake db:migrate')

    puts Rainbow("\nTo generate...").green
    puts Rainbow('    an admin user').green
    puts Rainbow('        rake bulwark:setup:create_admin')
    puts Rainbow('    a digital object and admin users').green
    puts Rainbow('        rake bulwark:setup:create_digital_object')

  end


  desc 'Cleans development/test environment'
  task :clean do
    system('lando destroy -y')
  end

  desc 'Stop development/test environment'
  task :stop do
    system('lando stop -y')
  end
end
