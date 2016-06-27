World Rack::Test::Methods

Given /^there exists an(?:other)? account "([^\"]*)"$/ do |subdomain|
  create :account, subdomain: subdomain
end

Given /^I am an? (user|admin) of account "([^\"]*)"$/ do |role, subdomain|
  @user = Account.find_by(subdomain: subdomain).users.find_by role: "admin"
end

Given /^I send and accept HTML$/ do
  header "Accept", "text/html"
  header "Content-Type", "text/html"
end

Given /^I send and accept JSON$/ do
  header "Accept", "application/json"
  header "Content-Type", "application/json"
end

Given /^I use my auth token$/ do
  header "Authorization", "Bearer \"#{@user.auth_token}\""
end

Given /^I am on the subdomain "([^\"]*)"$/ do |subdomain|
  @account = Account.find_by subdomain: subdomain
end

Given /^I have (\d+) "([^\"]*)"$/ do |count, resource|
  if @account
    count.to_i.times {
      create resource.singularize, account_id: @account.id
    }
  else
    create_list resource.singularize, count.to_i
  end
end

When /^I send a GET request to "([^\"]*)"$/ do |path|
  if @account
    get "//#{@account.subdomain}.keygin.io#{path}"
  else
    get "//keygin.io#{path}"
  end
end

When /^I send a POST request to "([^\"]*)" with the following:$/ do |path, body|
  if @account
    post "//#{@account.subdomain}.keygin.io#{path}", body
  else
    post "//keygin.io#{path}", body
  end
end

When /^I send a (?:PUT|PATCH) request to "([^\"]*)" with the following:$/ do |path, body|
  if @account
    put "//#{@account.subdomain}.keygin.io#{path}", body
  else
    put "//keygin.io#{path}", body
  end
end

When /^I send a DELETE request to "([^\"]*)"$/ do |path|
  if @account
    delete "//#{@account.subdomain}.keygin.io#{path}"
  else
    delete "//keygin.io#{path}"
  end
end

Then /^the response status should be "([^\"]*)"$/ do |status|
  assert_equal status.to_i, last_response.status
end

Then /^the JSON response should be an array with (\d+) "([^\"]*)"$/ do |count, name|
  json = JSON.parse last_response.body
  assert_equal count.to_i, json["data"].select { |d| d["type"] == name.pluralize }.length
end

Then /^the JSON response should be a "([^\"]*)"$/ do |name|
  json = JSON.parse last_response.body
  assert_equal name.pluralize, json["data"]["type"]
end

Then /^the JSON response should be a "([^\"]*)" with (\w+) "([^\"]*)"$/ do |name, attribute, value|
  json = JSON.parse last_response.body
  assert_equal name.pluralize, json["data"]["type"]
  assert_equal value, json["data"]["attributes"][attribute]
end

Then /^the JSON response should be a "([^\"]*)" with the following (\w+):$/ do |name, attribute, body|
  json = JSON.parse last_response.body
  assert_equal name.pluralize, json["data"]["type"]
  assert_equal JSON.parse(body), json["data"]["attributes"][attribute]
end

Then /^the JSON response should be an array of (\d+) errors?$/ do |count|
  json = JSON.parse last_response.body
  assert_equal count.to_i, json["errors"].length
end
