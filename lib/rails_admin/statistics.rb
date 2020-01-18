module RailsAdmin
  module Config
    module Actions
      class Statistics < RailsAdmin::Config::Actions::Base

        RailsAdmin::Config::Actions.register(self)

        register_instance_option :collection? do
          true
        end

        register_instance_option :visible? do
          authorized?
        end

        register_instance_option :member do
          false
        end
        register_instance_option :link_icon do
          'fa fa-pie-chart'
        end
      end
    end
  end
end