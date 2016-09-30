module RailsAdmin
  module Config
    module Actions
      class RepoNew < RailsAdmin::Config::Actions::New
        RailsAdmin::Config::Actions.register(self)

        register_instance_option :collection do
          true
        end

        register_instance_option :http_methods do
          [:get, :post] # NEW / CREATE
        end

        register_instance_option :controller do
          proc do
            if request.get? # NEW

              @object = @abstract_model.new
              @authorization_adapter && @authorization_adapter.attributes_for(:new, @abstract_model).each do |name, value|
                @object.send("#{name}=", value)
              end
              if object_params == params[@abstract_model.to_param]
                sanitize_params_for!(request.xhr? ? :modal : :create)
                @object.set_attributes(@object.attributes.merge(object_params.to_h))
              end
              respond_to do |format|
                format.html { render @action.template_name }
                format.js   { render @action.template_name, layout: false }
              end

            elsif request.post? # CREATE

              @modified_assoc = []
              @object = @abstract_model.new
              sanitize_params_for!(request.xhr? ? :modal : :create)

              @object.set_attributes(params[@abstract_model.param_key])
              @authorization_adapter && @authorization_adapter.attributes_for(:create, @abstract_model).each do |name, value|
                @object.send("#{name}=", value)
              end

              if @object.save
                @auditing_adapter && @auditing_adapter.create_object(@object, @abstract_model, _current_user)
                params[:return_to]
                if @abstract_model.model_name == 'Repo'
                  memo = @object.metadata_subdirectory == @object.assets_subdirectory ? { :warning => I18n.t('admin.flash.warning', name: @model_config.label, action: I18n.t("admin.actions.#{@action.key}.done"), reason: I18n.t("admin.actions.#{@action.key}.warning_reason")) } : { :success => I18n.t('admin.flash.successful', name: @model_config.label, action: I18n.t("admin.actions.#{@action.key}.done"))}
                  redirect_to "#{main_app.root_path}admin_repo/#{@abstract_model.model_name.downcase}/#{@object.id}/git_actions",  flash: memo
                else
                  respond_to do |format|
                    format.html { redirect_to_on_success }
                    format.js   { render json: {id: @object.id.to_s, label: @model_config.with(object: @object).object_label} }
                  end
                end
              else
                handle_save_error
              end

            end
          end
        end

        register_instance_option :link_icon do
          'icon-plus'
        end
      end
    end
  end
end
