class ApplicationMailer < ActionMailer::Base
  default from: I18n.t('mailers.addresses.default')
  layout 'mailer'
end
