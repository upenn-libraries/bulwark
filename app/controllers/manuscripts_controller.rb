class ManuscriptsController < ApplicationController
  include BaseModelsController
  before_action :set_manuscript, only: [:update]
  def update
    if manuscript_params[:review_status].present?
      binding.pry()
      @manuscript.review_status << manuscript_params[:review_status]
    else
      if @manuscript.update(manuscript_params)
        redirect_to catalog_url
      end
    end
  end

  private

  def set_manuscript
    @manuscript = Manuscript.find(params[:id])
  end

  def manuscript_params
    params.require(:manuscript).permit(:review_status)
  end

end
