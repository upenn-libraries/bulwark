# frozen_string_literal: true

module Admin
  class FileListingToolController < AdminController
    def tool; end

    def file_list
      respond_to do |format|
        if valid_path?
          format.json { render json: { filenames: filenames(absolute_path), drive: params[:drive], path: params[:path] }, status: :ok }
        else
          format.json { render json: { error: 'Error with path' }, status: :unprocessable_entity }
        end
      end
    end

    def csv
      return unless valid_path?

      data = filenames.map { |f| { filename: f } }
      csv = Bulwark::StructuredCSV.generate(data)
      send_data csv, type: 'text/csv', filename: 'structural_metadata.csv', disposition: :download
    end

    private

      def valid_path?
        params[:path].present? && absolute_path.starts_with?(Bulwark::Import::MountedDrives.path_to(params[:drive]))
      end

      def absolute_path
        path_to_drive = Bulwark::Import::MountedDrives.path_to(params[:drive])
        File.expand_path(File.join(path_to_drive, params[:path]))
      end

      def filenames(path)
        Dir.entries(path).select { |f| !f.start_with?('.') }.sort.join('; ')
      end
  end
end
