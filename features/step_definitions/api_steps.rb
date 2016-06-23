World Rack::Test::Methods

Given /^I am an? (user|admin) of account "([^\"]*)"$/ do |role, subdomain|
  account = create :account, subdomain: subdomain
  @user = account.users.find_by role: "admin"
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
  post path, body
end

When /^I send a PUT request to "([^\"]*)" with the following:$/ do |path, body|
  put path, body
end

When /^I send a DELETE request to "([^\"]*)"$/ do |path|
  delete path
end

Then /^the response should be "([^\"]*)"$/ do |status|
  assert last_response.status == status.to_i
end

Then /^the JSON response should be an array with (\d+) "([^\"]*)"$/ do |count, name|
  json = JSON.parse last_response.body
  assert json["data"].select { |d|
    d["type"] == name.pluralize
  }.length == count.to_i
end
