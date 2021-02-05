module Admin
  class DigitalObjectsController < AdminController
    def index
      # Querying for repos created in the new format.
      @digital_objects = Repo.new_format
    end

    def show
      @digital_object = Repo.find(params[:id])
    end
  end
end
