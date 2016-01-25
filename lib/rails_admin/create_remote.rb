require 'rails_admin/config/actions'
require 'rails_admin/config/actions/base'

module RailsAdmin
  module Config
    module Actions
      class CreateRemote < RailsAdmin::Config::Actions::Base

         RailsAdmin::Config::Actions.register(self)

         register_instance_option :route_fragment do
           'create_remote'
         end

        register_instance_option :member? do
          true
        end

        register_instance_option :http_methods do
          [:post]
        end

      end
    end
  end
end
