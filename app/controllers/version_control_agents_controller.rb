class VersionControlAgentsController < ApplicationController
  private

    def repo_params
      params.require(:repo).permit(:type, :repo)
    end
end
