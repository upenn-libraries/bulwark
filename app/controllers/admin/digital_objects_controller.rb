module Admin
  class DigitalObjectsController < AdminController
    def index
      # Querying for repos created in the new format.
      @digital_objects = Repo.where(new_format: true)
    end

    def show
      @digital_object = Repo.find_by(params[:id])
    end
  end
end
