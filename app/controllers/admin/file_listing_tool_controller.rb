# frozen_string_literal: true

module Admin
  class FileListingToolController < AdminController
    def tool; end

    def file_list
      respond_to do |format|
        if valid_path?
          format.csv { send_data csv, type: 'text/csv', filename: 'structural_metadata.csv', disposition: :download }
          format.json { render json: { filenames: filenames.join('; '), drive: params[:drive], path: params[:path] }, status: :ok }
        else
          format.csv {}
          format.json { render json: { error: 'Path invalid!' }, status: :unprocessable_entity }
        end
      end
    end

    private

      def csv
        data = filenames.map { |f| { filename: f } }
        Bulwark::StructuredCSV.generate(data)
      end

      def valid_path?
        params[:path].present? &&
          Bulwark::Import::MountedDrives.valid?(params[:drive]) &&
          absolute_path.starts_with?(Bulwark::Import::MountedDrives.path_to(params[:drive])) &&
          File.exist?(absolute_path)
      end

      def absolute_path
        path_to_drive = Bulwark::Import::MountedDrives.path_to(params[:drive])
        File.expand_path(File.join(path_to_drive, params[:path]))
      end

      def filenames
        Dir.entries(absolute_path).select { |f| !f.start_with?('.') }.sort
      end
  end
end
