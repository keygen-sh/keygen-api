World Rack::Test::Methods

Given /^I am an? (user|admin|product) of account "([^\"]*)"$/ do |role, slug|
  account = Account.find slug
  @bearer =
    case role
    when "admin", "user"
      account.users.roles(role).first
    when "product"
      account.products.first
    end
end

Given /^I send the following headers:$/ do |body|
  parse_placeholders! body
  headers = JSON.parse body

  # Base64 encode basic credentials
  if headers.key? "Authorization"
    /Basic "([.@\w\d]+):(.+)"/ =~ headers["Authorization"]
    credentials = Base64.encode64 "#{$1}:#{$2}"
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
  token = @bearer.tokens.first_or_create account: @bearer.account
  token.regenerate!

  header "Authorization", "Bearer #{token.raw}"
end

Given /^I use an expired authentication token$/ do
  token = @bearer.tokens.first_or_create account: @bearer.account
  token.regenerate!
  token.update expiry: Time.current

  header "Authorization", "Bearer #{token.raw}"
end
