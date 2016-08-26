class BatchEditController < ApplicationController
    include Hydra::BatchEditBehavior
    include Blacklight::Base

    def update
      batch.each do |doc_id|
        obj = ActiveFedora::Base.find(doc_id, :cast=>true)
        type = obj.class.to_s.underscore.to_sym
        obj.update_attributes(params[type])
        obj.do_something_special
        obj.save
      end
      flash[:notice] = "Batch update complete"
      clear_batch!
      redirect_to catalog_index_path
    end
  end
