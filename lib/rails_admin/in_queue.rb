module RailsAdmin
  module Config
    module Actions
      class InQueue < RailsAdmin::Config::Actions::Base

        RailsAdmin::Config::Actions.register(self)

        register_instance_option :root? do
          true
        end

        register_instance_option :visible? do
          authorized?
        end

        register_instance_option :member do
          false
        end
        register_instance_option :link_icon do
          'icon-eye-open'
        end
      end
    end
  end
end