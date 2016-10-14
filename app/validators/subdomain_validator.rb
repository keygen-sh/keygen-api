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
    if reserved?(value)
      record.errors.add attribute, "#{value} is a reserved subdomain"
    end
  end

  private

  def reserved?(value)
    RESERVED.include? value
  end
end
