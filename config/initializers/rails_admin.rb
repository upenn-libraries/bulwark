require Rails.root.join('lib', 'rails_admin', 'git_review.rb')
require Rails.root.join('lib', 'rails_admin', 'create_remote.rb')

RailsAdmin.config do |config|
  config.main_app_name = ["Intermediary", "Admin Interface"]

  config.included_models = ["Repo"]

  config.actions do
    dashboard                     # mandatory
    index                         # mandatory
    new
    export
    bulk_delete
    show
    edit
    delete
    show_in_app
    git_review do
      only ["Repo"]
    end
    create_remote do
      only ["Repo"]
    end
    # clone_from_production do
    #   only ["Repo"]
    # end
    # sign_off_production do
    #   only ["Repo"]
    # end
    # report_flagged do
    #   only ["Repo"]
    # end
  end

end
