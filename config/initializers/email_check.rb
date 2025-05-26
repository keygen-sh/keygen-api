# frozen_string_literal: true

# extend to also support checking for educational emails
module EmailCheck
  class EmailAddress
    # NB(ezekg) using any? here instead of include? allows domains to be regexes and strings
    def educational? = EmailCheck.edu_email_domains.any? { _1 === @email.domain }
    alias :edu? :educational?
  end

  @@edu_email_domains = [
    /\.edu(\..{2,})?\z/, # mit.edu, unimelb.edu.au, etc.
    /\.ac\..{2,}\z/,     # ox.ac.uk, u-tokyo.ac.jp, etc.
  ]

  def self.edu_email_domains
    @@edu_email_domains ||= []
  end

  def self.edu_email_domains=(list)
    @@edu_email_domains = list
  end
end

EmailCheck.tap do |config|
  disposable_domains = ENV.fetch('EMAIL_CHECK_DISPOSABLE_DOMAINS') { '' }.split(',')
  free_domains       = ENV.fetch('EMAIL_CHECK_FREE_DOMAINS')       { '' }.split(',')
  edu_domains        = ENV.fetch('EMAIL_CHECK_EDU_DOMAINS')        { '' }.split(',')

  config.disposable_email_domains.concat(disposable_domains)
  config.free_email_domains.concat(free_domains)
  config.edu_email_domains.concat(edu_domains)
end
