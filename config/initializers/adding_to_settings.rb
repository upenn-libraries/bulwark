# Adding settings to Settings object initialized via the `config` gem.
Settings.add_source!(solr: Rails.application.config_for(:solr))
Settings.reload!
