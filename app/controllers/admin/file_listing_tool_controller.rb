# frozen_string_literal: true

module Admin
  class FileListingToolController < AdminController
    def tool; end

    def file_list

      # params[:drive]
      # params[:path]
      # path_to_drive = Bulwark::Import::MountedDrives.path_to(drive)
      # path = File.join(path_to_drive, path)



      # get absolute path
      # check that absolute path begins with the path drive
      #

      render json: { filenames: 'whatever' }

    end

    def csv
      send_data csv, type: 'text/csv', filename: filename, disposition: :download
    end
  end
end
