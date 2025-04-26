# frozen_string_literal: true

TOKEN_VERSIONS = %W[v1 v2 v3 #{Tokenable::ALGO_VERSION}].uniq

World Rack::Test::Methods

Given /^I am(?: (?:an?|(the (\w+))))? (admin|developer|read only|sales agent|support agent|user|product|license|environment) (?:for|of) account "([^\"]*)"$/ do |named_idx, role, id|
  named_idx ||= :first

  account = FindByAliasService.call(Account, id:, aliases: :slug)

  @bearer =
    case role
    when "admin", "user", "read only", "developer", "sales agent", "support agent"
      account.users.with_roles(role.parameterize.underscore).send(named_idx)
    when "product"
      account.products.send(named_idx)
    when "license"
      account.licenses.send(named_idx)
    when "environment"
      account.environments.send(named_idx)
    else
      raise 'invalid role'
    end

  raise 'failed to find bearer' if @bearer.nil?
end

Given /^I am(?: (?:an?|(the (\w+))))? (admin|developer|read only|sales agent|support agent|user|product|license|environment) (?:for|of) the (\w+) "account"$/ do |named_role_idx, role, named_account_idx|
  named_role_idx ||= :first

  account = Account.send(named_account_idx)
  @bearer =
    case role
    when "admin", "user", "read only", "developer", "sales agent", "support agent"
      account.users.with_roles(role.parameterize.underscore).send(named_role_idx)
    when "product"
      account.products.send(named_role_idx)
    when "license"
      account.licenses.send(named_role_idx)
    when "environment"
      account.environments.send(named_role_idx)
    else
      raise 'invalid role'
    end

  raise 'failed to find bearer' if @bearer.nil?
end

Given /^I am product "([^\"]*)" of account "([^\"]*)"$/ do |product_id, account_id|
  account = FindByAliasService.call(Account, id: account_id, aliases: :slug)
  product = FindByAliasService.call(
    account.products,
    id: product_id,
    aliases: :code,
  )

  @bearer = product

  raise 'failed to find bearer' if @bearer.nil?
end

Given /^I have 2FA (enabled|disabled)$/ do |second_factor_status|
  @second_factor = SecondFactor.new user: @bearer, account: @bearer.account
  @second_factor.enabled = second_factor_status == 'enabled'
  @second_factor.save
end

Given /^I do not have 2FA$/ do
  @bearer.second_factors.delete_all
end

Given /^the (first|second|third|fourth|fifth|last) "(user|admin)" does not have 2FA$/ do |named_index, user_role|
  user = @account.users.with_roles(user_role).send(named_index)

  user.second_factors.delete_all
end

Given /^the (first|second|third|fourth|fifth|last) "(user|admin)" has 2FA (disabled|enabled)$/ do |named_index, user_role, second_factor_status|
  user = @account.users.with_roles(user_role).send(named_index)

  @second_factor = SecondFactor.new user: user, account: user.account
  @second_factor.enabled = second_factor_status == 'enabled'
  @second_factor.save
end

Given /^I send the following headers:$/ do |body|
  body = parse_placeholders(body, account: @account, bearer: @bearer, crypt: @crypt)
  headers = JSON.parse body

  # Base64 encode basic credentials
  if headers["Authorization"]&.starts_with? "Basic"
    /Basic "([.@\w\d]+):(.*)"/ =~ headers["Authorization"]
    credentials = Base64.encode64 "#{$1}:#{$2}"
    headers["Authorization"] = "Basic \"#{credentials}\""
  end

  headers.each do |name, value|
    header name, value&.strip
  end
end

Given /^I send the following badly encoded headers:$/ do |body|
  body = parse_placeholders(body, account: @account, bearer: @bearer, crypt: @crypt)
  headers = JSON.parse body

  # Base64 encode basic credentials
  if headers.key? "Authorization"
    /Basic "([.@\w\d]+):(.*)"/ =~ headers["Authorization"]
    credentials = Base64.encode64 "#{128.chr + $1}:#{128.chr + $2}"
    headers["Authorization"] = "Basic \"#{credentials}\""
  end

  headers.each do |name, value|
    header name, value&.strip
  end
end

Given /^I send the following raw headers:$/ do |body|
  body = parse_placeholders(body, account: @account, bearer: @bearer, crypt: @crypt)
  headers = body.split /\n/

  headers.each do |raw|
    key, value = raw.split(':')

    header key, value&.strip
  end
end

Given /^I (?:use (?:an|my) authentication|authenticate with (?:a|my)) token$/ do
  @token = if @bearer.respond_to?(:environment)
             @bearer.tokens.first_or_create!(account: @bearer.account, environment: @bearer.environment, bearer: @bearer)
           else
             @bearer.tokens.first_or_create!(account: @bearer.account, bearer: @bearer)
           end

  # Randomly pick a token version to test. We're doing it this way so
  # that we can evenly distribute tests for all token versions, to
  # make sure we're backwards compatible.
  @token.regenerate! version: TOKEN_VERSIONS.sample

  # Use a mix between basic and bearer auth schemes
  if rand(0..1).zero?
    http_token = @token.raw

    header "Authorization", "Bearer #{http_token}"
  else
    http_basic = Base64.strict_encode64("#{@token.raw}:")

    header "Authorization", "Basic #{http_basic}"
  end
end

Given /^I (?:use an expired authentication|authenticate with an expired) token$/ do
  @token = @bearer.tokens.first_or_create! account: @bearer.account
  @token.regenerate! version: TOKEN_VERSIONS.sample
  @token.update expiry: 1.minute.ago

  header "Authorization", "Bearer #{@token.raw}"
end

Given /^I authenticate with (?:a|my)(?: license)? key$/ do
  if rand(0..1).zero?
    http_key = @bearer.key

    header "Authorization", "License #{http_key}"
  else
    http_basic = Base64.strict_encode64("license:#{@bearer.key}")

    header "Authorization", "Basic #{http_basic}"
  end
end

Given /^I authenticate with an invalid key$/ do
  if rand(0..1).zero?
    http_key = SecureRandom.hex

    header "Authorization", "License #{http_key}"
  else
    http_basic = Base64.strict_encode64("license:#{SecureRandom.hex}")

    header "Authorization", "Basic #{http_basic}"
  end
end

Given /^I authenticate with (?:a|my)(?: valid)? session$/ do
  @token   = @bearer.tokens.first_or_create!(account: @bearer.account, bearer: @bearer)
  @session = @token.sessions.create!(
    expiry: 10.hours.from_now,
    user_agent: 'keygen/test',
    ip: '127.0.0.1',
  )

  app       = Rails.application
  config    = app.config
  keygen    = app.key_generator
  salt      = config.action_dispatch.authenticated_encrypted_cookie_salt
  cipher    = config.action_dispatch.encrypted_cookie_cipher
  key_len   = ActiveSupport::MessageEncryptor.key_len(cipher)
  key       = keygen.generate_key(salt, key_len)
  encryptor = ActiveSupport::MessageEncryptor.new(key,
    serializer: ActiveSupport::MessageEncryptor::NullSerializer,
    cipher:,
  )

  dec = JSON.dump(@session.id)
  enc = encryptor.encrypt_and_sign(dec, purpose: 'cookie.session_id')
  esc = CGI.escape(enc)

  header "Cookie", %(session_id=#{esc})
end

Given /^I authenticate with an expiring session$/ do
  @token   = @bearer.tokens.first_or_create!(account: @bearer.account, bearer: @bearer)
  @session = @token.sessions.create!(
    expiry: 10.minutes.from_now,
    user_agent: 'keygen/test',
    ip: '127.0.0.1',
  )

  app       = Rails.application
  config    = app.config
  keygen    = app.key_generator
  salt      = config.action_dispatch.authenticated_encrypted_cookie_salt
  cipher    = config.action_dispatch.encrypted_cookie_cipher
  key_len   = ActiveSupport::MessageEncryptor.key_len(cipher)
  key       = keygen.generate_key(salt, key_len)
  encryptor = ActiveSupport::MessageEncryptor.new(key,
    serializer: ActiveSupport::MessageEncryptor::NullSerializer,
    cipher:,
  )

  dec = JSON.dump(@session.id)
  enc = encryptor.encrypt_and_sign(dec, purpose: 'cookie.session_id')
  esc = CGI.escape(enc)

  header "Cookie", %(session_id=#{esc})
end

Given /^I authenticate with an expired session$/ do
  @token   = @bearer.tokens.first_or_create!(account: @bearer.account, bearer: @bearer)
  @session = @token.sessions.create!(
    expiry: 1.hour.ago,
    user_agent: 'keygen/test',
    ip: '127.0.0.1',
  )

  app       = Rails.application
  config    = app.config
  keygen    = app.key_generator
  salt      = config.action_dispatch.authenticated_encrypted_cookie_salt
  cipher    = config.action_dispatch.encrypted_cookie_cipher
  key_len   = ActiveSupport::MessageEncryptor.key_len(cipher)
  key       = keygen.generate_key(salt, key_len)
  encryptor = ActiveSupport::MessageEncryptor.new(key,
    serializer: ActiveSupport::MessageEncryptor::NullSerializer,
    cipher:,
  )

  dec = JSON.dump(@session.id)
  enc = encryptor.encrypt_and_sign(dec, purpose: 'cookie.session_id')
  esc = CGI.escape(enc)

  header "Cookie", %(session_id=#{esc})
end

Given /^I authenticate with an invalid session$/ do
  @token   = @bearer.tokens.first_or_create!(account: @bearer.account, bearer: @bearer)

  app       = Rails.application
  config    = app.config
  keygen    = app.key_generator
  salt      = config.action_dispatch.authenticated_encrypted_cookie_salt
  cipher    = config.action_dispatch.encrypted_cookie_cipher
  key_len   = ActiveSupport::MessageEncryptor.key_len(cipher)
  key       = keygen.generate_key(salt, key_len)
  encryptor = ActiveSupport::MessageEncryptor.new(key,
    serializer: ActiveSupport::MessageEncryptor::NullSerializer,
    cipher:,
  )

  dec = JSON.dump(SecureRandom.uuid)
  enc = encryptor.encrypt_and_sign(dec, purpose: 'cookie.session_id')
  esc = CGI.escape(enc)

  header "Cookie", %(session_id=#{esc})
end

Given /^the SSO callback code "([^\"]*)" returns the following profile:$/ do |code, body|
  profile           = double(JSON.parse(body, symbolize_names: true))
  profile_and_token = double(
    access_token: "test_token_#{SecureRandom.hex}",
    profile:,
  )

  allow(WorkOS::SSO).to receive(:profile_and_token).with(hash_including(code:)).and_return(
    profile_and_token,
  )
end

Given /^the SSO callback code "([^\"]*)" returns an? "([^\"]*)" error$/ do |code, error|
  allow(WorkOS::SSO).to receive(:profile_and_token).with(hash_including(code:)).and_raise(
    WorkOS::APIError.new(error:),
  )
end
