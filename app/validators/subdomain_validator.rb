class SubdomainValidator < ActiveModel::EachValidator
  RESERVED = %w[
    abuse
    account
    admin
    administrate
    administrator
    analytics
    api
    app
    application
    auth
    authenticate
    authorize
    blog
    careers
    dashboard
    database
    demo
    dev
    develop
    developer
    developers
    development
    doc
    docs
    documentation
    email
    feed
    feeds
    files
    ftp
    git
    go
    help
    http
    https
    imap
    info
    jobs
    join
    key
    keys
    keygin
    keygen
    log
    logs
    login
    mail
    monitor
    mysql
    pop
    pop3
    postgres
    register
    root
    sales
    secure
    security
    sftp
    smtp
    sql
    ssh
    ssl
    stage
    staging
    stats
    status
    support
    svn
    test
    vcs
    web
    webmail
    webmaster
    www
  ].freeze

  def validate_each(record, attribute, value)
    record.errors.add attribute, "cannot be a reserved subdomain" if reserved_subdomain?(value)
    record.errors.add attribute, "must be a valid subdomain" unless valid_subdomain?(value)
  end

  private

  def reserved_subdomain?(value)
    RESERVED.include? value
  end

  def valid_subdomain?(value)
    return false if value.nil?
    value =~ /\A[-a-z0-9]+\Z/i
  end
end
