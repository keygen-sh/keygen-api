# frozen_string_literal: true

TOKEN_VERSIONS = %W[v1 v2 v3 #{Tokenable::ALGO_VERSION}].uniq

World Rack::Test::Methods

Given /^I am(?: an?)? (admin|developer|sales agent|support agent|user|product|license) (?:of|for) account "([^\"]*)"$/ do |role, slug|
  account = Account.find slug
  @bearer =
    case role
    when "admin", "user", "developer", "sales agent", "support agent"
      account.users.roles(role.parameterize.underscore).first
    when "product"
      account.products.first
    when "license"
      account.licenses.first
    else
      raise 'invalid role'
    end

  raise 'failed to find bearer' if @bearer.nil?
end

Given /^I have 2FA (enabled|disabled)$/ do |second_factor_status|
  @second_factor = SecondFactor.new user: @bearer, account: @bearer.account
  @second_factor.enabled = second_factor_status == 'enabled'
  @second_factor.save
end

Given /^I send the following headers:$/ do |body|
  parse_placeholders! body
  headers = JSON.parse body

  # Base64 encode basic credentials
  if headers["Authorization"]&.starts_with? "Basic"
    /Basic "([.@\w\d]+):(.+)"/ =~ headers["Authorization"]
    credentials = Base64.encode64 "#{$1}:#{$2}"
    headers["Authorization"] = "Basic \"#{credentials}\""
  end

  headers.each do |name, value|
    header name, value
  end
end

Given /^I send the following badly encoded headers:$/ do |body|
  parse_placeholders! body
  headers = JSON.parse body

  # Base64 encode basic credentials
  if headers.key? "Authorization"
    /Basic "([.@\w\d]+):(.+)"/ =~ headers["Authorization"]
    credentials = Base64.encode64 "#{128.chr + $1}:#{128.chr + $2}"
    headers["Authorization"] = "Basic \"#{credentials}\""
  end

  headers.each do |name, value|
    header name, value
  end
end

Given /^I send the following raw headers:$/ do |body|
  parse_placeholders! body
  headers = body.split /\n/

  headers.each do |raw|
    key, value = raw.split ":"

    header key, value
  end
end

Given /^I use an authentication token$/ do
  @token = @bearer.tokens.first_or_create account: @bearer.account

  # Randomly pick a token version to test. We're doing it this way so
  # that we can evenly distribute tests for all token versions, to
  # make sure we're backwards compatible.
  @token.regenerate! version: TOKEN_VERSIONS.sample

  header "Authorization", "Bearer #{@token.raw}"
end

Given /^I use an expired authentication token$/ do
  @token = @bearer.tokens.first_or_create account: @bearer.account
  @token.regenerate! version: TOKEN_VERSIONS.sample
  @token.update expiry: Time.current

  header "Authorization", "Bearer #{@token.raw}"
end
