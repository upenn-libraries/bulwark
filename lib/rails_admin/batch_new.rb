module RailsAdmin
  module Config
    module Actions
      class BatchNew < RailsAdmin::Config::Actions::New
        RailsAdmin::Config::Actions.register(self)

        register_instance_option :collection do
          true
        end

        register_instance_option :http_methods do
          [:get, :post] # NEW / CREATE
        end

        register_instance_option :link_icon do
          'icon-plus'
        end
      end
    end
  end
end
