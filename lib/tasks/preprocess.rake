namespace :preprocess do

  namespace :generate do
    desc "Generate checksum log"
    task :checksum_log => :environment do
      Utils.generate_checksum_log
    end
  end

  desc "Fetch and convert flat XML"
  task :fetch_and_convert_files => :environment do
    Utils.fetch_and_convert_files
  end

end
