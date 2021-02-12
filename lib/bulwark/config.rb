module Bulwark
  module Config
    # Module to centralize calls to retrieve application-wide configuration.
    #
    # This module should eventually replace all the modules that are created at
    # initialization, such as Utils.config, etc. Because these modules are created
    # at app start time in development/test the modules aren't reloaded properly.
    #
    # Eventually, we can make this module more efficient by potentially caching
    # values in each thread. There are probably other things we can explore as well.
    #
    # This module will at first read configuration from different yml files in
    # config/. Eventually we want merge all those file into config/bulwark.yml.

    def self.special_remote
      Rails.application.config_for(:filesystem)
                       .fetch('special_remote', {})
                       .with_indifferent_access
    end

    def self.bulk_import
      Rails.application.config_for(:bulwark)
                       .fetch('bulk_import', {})
                       .with_indifferent_access
    end
  end
end
