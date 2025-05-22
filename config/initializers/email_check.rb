# frozen_string_literal: true

EmailCheck.tap do |config|
  disposable_domains = ENV.fetch('EMAIL_CHECK_DISPOSABLE_DOMAINS') { '' }.split(',')
  free_domains       = ENV.fetch('EMAIL_CHECK_FREE_DOMAINS')       { '' }.split(',')

  config.disposable_email_domains.concat(disposable_domains)
  config.free_email_domains.concat(free_domains)
end
