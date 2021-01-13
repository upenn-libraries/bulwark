module Admin
  class BulkImportsController < AdminController
    def index
      @bulk_imports = BulkImport.page(params[:page]).includes(:digital_object_imports)
    end

    def new
      @bulk_import = BulkImport.new(created_by: current_user)
    end

    def create
      @bulk_import = BulkImport.new(created_by: current_user)
      csv = params[:bulk_import][:bulk_import_csv]
      # TODO: parse CSV, validate and build DigitalObjectImports
      if @bulk_import.save
        redirect_to admin_bulk_import_path(@bulk_import)
      else
        # TODO: display CSV parsing errors?
        redirect_to new_admin_bulk_import_path, flash: { errors: 'Failed' }
      end
    end

    def show
      @bulk_import = BulkImport.find(params[:id])
    end
  end
end
