class ApplicationMailer < ActionMailer::Base
  default from: I18n.t('colenda.mailers.addresses.default')
  layout 'mailer'
end
