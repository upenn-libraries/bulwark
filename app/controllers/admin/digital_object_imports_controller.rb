# frozen_string_literal: true

module Admin
  class DigitalObjectImportsController < AdminController
    def show
      @digital_object_import = DigitalObjectImport.find_by(
        bulk_import: params[:bulk_import_id], id: params[:id]
      )
    end
  end
end
