require Rails.root.join('lib', 'rails_admin', 'git_review.rb')
RailsAdmin::Config::Actions.register(RailsAdmin::Config::Actions::GitReview)

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
  end

end
