World Rack::Test::Methods

Before "@api/v1" do
  @api_version = "v1"
end

Before do
  Stripe.api_key = "sX}x6fY^i=oAv6o{6hudzs7YC"
  StripeMock.start
end

After do
  StripeMock.stop
end

Given /^there exists an(?:other)? account "([^\"]*)"$/ do |subdomain|
  create :account, subdomain: subdomain
end

Given /^I am an? (user|admin) of account "([^\"]*)"$/ do |role, subdomain|
  @user = Account.find_by(subdomain: subdomain).users.find_by role: role
end

Given /^I send and accept HTML$/ do
  header "Content-Type", "text/html"
  header "Accept", "text/html"
end

Given /^I send and accept JSON$/ do
  header "Content-Type", "application/vnd.api+json"
  header "Accept", "application/vnd.api+json"
end

Given /^I use my auth token$/ do
  header "Authorization", "Bearer \"#{@user.auth_token}\""
end

Given /^I am on the subdomain "([^\"]*)"$/ do |subdomain|
  @account = Account.find_by subdomain: subdomain
end

Given /^there exists (\d+) "([^\"]*)"$/ do |count, resource|
  create_list resource.singularize, count.to_i
end

Given /^the account "([^\"]*)" has (\d+) "([^\"]*)"$/ do |subdomain, count, resource|
  count.to_i.times {
    create resource.singularize, account_id: Account.find_by(subdomain: subdomain).id
  }
end

Given /^the current account has (\d+) "([^\"]*)"$/ do |count, resource|
  count.to_i.times {
    create resource.singularize, account_id: @account.id
  }
end

Given /^I have a valid payment token/ do
end

Given /^I have a payment token with an? "([^\"]*)" error$/ do |error|
  StripeMock.prepare_card_error(
    case error
    when "incorrect number"     then :incorrect_number
    when "invalid number"       then :invalid_number
    when "invalid expiry month" then :invalid_expiry_month
    when "invalid expiry year"  then :invalid_expiry_year
    when "invalid cvc"          then :invalid_cvc
    when "expired card"         then :expired_card
    when "incorrect cvc"        then :incorrect_cvc
    when "card declined"        then :card_declined
    when "missing"              then :missing
    when "processing error"     then :processing_error
    end, :new_customer
  )
end

When /^I send a GET request to "([^\"]*)"$/ do |path|
  if @account
    get "//#{@account.subdomain}.keygin.io/#{@api_version}/#{path.sub(/^\//, '')}"
  else
    get "//keygin.io/#{@api_version}/#{path.sub(/^\//, '')}"
  end
end

When /^I send a POST request to "([^\"]*)" with the following:$/ do |path, body|
  if @account
    post "//#{@account.subdomain}.keygin.io/#{@api_version}/#{path.sub(/^\//, '')}", body
  else
    post "//keygin.io/#{@api_version}/#{path.sub(/^\//, '')}", body
  end
end

When /^I send a (?:PUT|PATCH) request to "([^\"]*)" with the following:$/ do |path, body|
  if @account
    put "//#{@account.subdomain}.keygin.io/#{@api_version}/#{path.sub(/^\//, '')}", body
  else
    put "//keygin.io/#{@api_version}/#{path.sub(/^\//, '')}", body
  end
end

When /^I send a DELETE request to "([^\"]*)"$/ do |path|
  if @account
    delete "//#{@account.subdomain}.keygin.io/#{@api_version}/#{path.sub(/^\//, '')}"
  else
    delete "//keygin.io/#{@api_version}/#{path.sub(/^\//, '')}"
  end
end

Then /^the response status should be "([^\"]*)"$/ do |status|
  assert_equal status.to_i, last_response.status
end

Then /^the JSON response should be an array with (\d+) "([^\"]*)"$/ do |count, name|
  json = JSON.parse last_response.body
  assert_equal count.to_i, json["data"].select { |d| d["type"] == name.pluralize }.length
end

Then /^the JSON response should be an? "([^\"]*)"$/ do |name|
  json = JSON.parse last_response.body
  assert_equal name.pluralize, json["data"]["type"]
end

Then /^the JSON response should be an? "([^\"]*)" with (?:the )?(\w+) "([^\"]*)"$/ do |name, attribute, value|
  json = JSON.parse last_response.body
  assert_equal name.pluralize, json["data"]["type"]
  assert_equal value, json["data"]["attributes"][attribute]
end

Then /^the JSON response should be an? "([^\"]*)" with the following (\w+):$/ do |name, attribute, body|
  json = JSON.parse last_response.body
  assert_equal name.pluralize, json["data"]["type"]
  assert_equal JSON.parse(body), json["data"]["attributes"][attribute]
end

Then /^the JSON response should be an array of (\d+) errors?$/ do |count|
  json = JSON.parse last_response.body
  assert_equal count.to_i, json["errors"].length
end

Then /^the current account should have (\d+) "([^\"]*)"$/ do |count, resource|
  if @account
    user = Account.find_by(subdomain: @account.subdomain).users.find_by role: "admin"
    header "Authorization", "Bearer \"#{user.auth_token}\""
    get "//#{@account.subdomain}.keygin.io/#{@api_version}/#{resource.pluralize}"
  else
    get "//keygin.io/#{@api_version}/#{resource.pluralize}"
  end
  json = JSON.parse last_response.body
  assert_equal count.to_i, json["data"].select { |d| d["type"] == resource.pluralize }.length
end
