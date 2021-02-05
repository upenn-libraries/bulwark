module Admin
  class DigitalObjectsController < AdminController
    def index
      # Querying for repos created in the new format.
      @digital_objects = Repo.new_format
      @digital_objects = @digital_objects.id_search(params[:id_search]) if params[:id_search].present?
      @digital_objects = @digital_objects.name_search(params[:name_search]) if params[:id_search].present?
      @digital_objects = @digital_objects.where(owner: params[:owner_search]) if params[:owner_search].present?
    end

    def show
      @digital_object = Repo.find_by(params[:id])
    end
  end
end
