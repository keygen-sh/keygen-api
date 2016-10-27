World Rack::Test::Methods

Given /^I am an? (user|admin|product) of account "([^\"]*)"$/ do |role, subdomain|
  account = Account.find_by subdomain: subdomain
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

Given /^I use my authentication token$/ do
  token = @bearer.token.generate!

  header "Authorization", "Bearer \"#{token}\""
end
