# frozen_string_literal: true

module Admin
  class BulkImportsController < AdminController
    def index
      @bulk_imports = BulkImport.order(created_at: :desc).page(params[:page])
                                .includes(:digital_object_imports, :created_by)
    end

    def new
      @bulk_import = BulkImport.new(created_by: current_user)
    end

    def create
      @bulk_import = BulkImport.new(created_by: current_user)
      uploaded_file = params[:bulk_import][:bulk_import_csv]
      uploaded_file.tempfile.set_encoding('UTF-8') # CSVs ingested are UTF-8
      csv = uploaded_file.read

      if (errors = @bulk_import.validation_errors(csv)) # Validate CSV.
        errors_array = errors.map { |r, errors| errors.map { |e| "#{r}: #{e}" } }.flatten
        flash[:error] = errors_array
        redirect_to new_admin_bulk_import_path
      else # If no validation errors, create imports.
        @bulk_import.original_filename = uploaded_file.original_filename
        @bulk_import.save
        @bulk_import.create_imports csv, safe_queue_name_from(params[:bulk_import][:job_priority].to_s)

        redirect_to admin_bulk_import_path(@bulk_import)
      end
    end

    def show
      @bulk_import = BulkImport.find(params[:id])
      @status = params[:digital_object_import_status]
      @digital_object_imports = @bulk_import.digital_object_imports
                                            .page(params[:digital_object_import_page])
      @digital_object_imports = @digital_object_imports.where(status: @status) if @status
    end

    # Download original download csv.
    def csv
      @bulk_import = BulkImport.find(params[:id])

      send_data @bulk_import.csv, type: 'text/csv', filename: @bulk_import.original_filename, disposition: :download
    end

    private

      # @param [String] priority_param
      # @return [String]
      def safe_queue_name_from(priority_param)
        if priority_param.in?(Bulwark::Queues::PRIORITY_QUEUES)
          priority_param
        else
          Bulwark::Queues::DEFAULT_PRIORITY
        end
      end
  end
end
