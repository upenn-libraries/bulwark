namespace :postprocess do

  namespace :generate do

    desc "Add post-ingest checksums to log"
    task :checksum_log => :environment do
    end
  end

  namespace :manuscripts do
    desc "Assign AF models for pages to respective manuscripts"
    task :assign_pages => :environment do
      ActiveFedora::Base.find_each({"active_fedora_model_ssi"=>"Manuscript"}, batch_size: 100) do |manuscript|
        page_relations = Page.where(parent_manuscript: manuscript.id).to_a
        binding.pry()
        page_relations.each do |page_relation|
          binding.pry()
          page = Page.find(page_relation.id)
          page.manuscript = manuscript
          page.save
        end
      end
    end
  end

end
