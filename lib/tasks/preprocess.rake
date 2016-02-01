namespace :preprocess do

  namespace :generate do
    desc "Generate checksum log"
    task :checksum_log => :environment do
      Utils.generate_checksum_log
    end
  end

end
