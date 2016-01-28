require 'rails_admin/config/actions'
require 'rails_admin/config/actions/base'

module RailsAdmin
  module Config
    module Actions
      class CreateRemote < RailsAdmin::Config::Actions::Base

         RailsAdmin::Config::Actions.register(self)

        register_instance_option :member? do
          true
        end

        register_instance_option :http_methods do
          [:post]
        end

        register_instance_option :controller do
          Proc.new do
            @object.create_remote
            redirect_to main_app.show_path(@object)
          end
        end

      end
    end
  end
end
