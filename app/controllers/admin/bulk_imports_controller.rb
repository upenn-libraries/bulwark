module Admin
  class BulkImportsController < AdminController
    def index
      @bulk_imports = BulkImport.order(created_at: :desc)
                                .page(params[:page])
                                .includes(:digital_object_imports)
    end

    def new
      @bulk_import = BulkImport.new(created_by: current_user)
    end

    def create
      @bulk_import = BulkImport.new(created_by: current_user)
      uploaded_file = params[:bulk_import][:bulk_import_csv]
      uploaded_file.tempfile.set_encoding('UTF-8') # CSVs ingested are UTF-8
      csv = uploaded_file.read

      if errors = @bulk_import.validation_errors(csv) # Validate CSV.
        errors_array = errors.map { |r, errors| errors.map { |e| "#{r}: #{e}" } }.flatten
        flash[:error] = errors_array
        redirect_to new_admin_bulk_import_path
      else # If no validation errors, create imports.
        @bulk_import.save
        @bulk_import.create_imports(csv)

        redirect_to admin_bulk_import_path(@bulk_import)
      end
    end

    def show
      @bulk_import = BulkImport.find(params[:id])
    end
  end
end
