require 'rails_admin/config/actions'
require 'rails_admin/config/actions/base'

module RailsAdmin
  module Config
    module Actions
      class Ingest < RailsAdmin::Config::Actions::Base

         RailsAdmin::Config::Actions.register(self)

         register_instance_option :route_fragment do
           'ingest'
         end

        register_instance_option :member? do
          true
        end

        register_instance_option :link_icon do
         'fa fa-file-text-o'
        end

        register_instance_option :http_methods do
          [:get, :post]
        end

      end
    end
  end
end
