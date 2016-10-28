World Rack::Test::Methods

Given /^I send and accept HTML$/ do
  header "Content-Type", "text/html"
  header "Accept", "text/html"
end

Given /^I send and accept JSON$/ do
  header "Content-Type", "application/vnd.api+json"
  header "Accept", "application/vnd.api+json"
end

When /^I send a GET request to "([^\"]*)"$/ do |path|
  parse_path_placeholders! path
  if @account
    get "//#{@account.subdomain}.keygen.sh/#{@api_version}/#{path.sub(/^\//, '')}"
  else
    get "//keygen.sh/#{@api_version}/#{path.sub(/^\//, '')}"
  end
end

When /^I send a POST request to "([^\"]*)"$/ do |path|
  parse_path_placeholders! path
  if @account
    post "//#{@account.subdomain}.keygen.sh/#{@api_version}/#{path.sub(/^\//, '')}"
  else
    post "//keygen.sh/#{@api_version}/#{path.sub(/^\//, '')}"
  end
end

When /^I send a POST request to "([^\"]*)" with the following:$/ do |path, body|
  parse_path_placeholders! path
  parse_placeholders! body
  if @account
    post "//#{@account.subdomain}.keygen.sh/#{@api_version}/#{path.sub(/^\//, '')}", body
  else
    post "//keygen.sh/#{@api_version}/#{path.sub(/^\//, '')}", body
  end
end

When /^I send a (?:PUT|PATCH) request to "([^\"]*)" with the following:$/ do |path, body|
  parse_path_placeholders! path
  parse_placeholders! body
  if @account
    put "//#{@account.subdomain}.keygen.sh/#{@api_version}/#{path.sub(/^\//, '')}", body
  else
    put "//keygen.sh/#{@api_version}/#{path.sub(/^\//, '')}", body
  end
end

When /^I send a DELETE request to "([^\"]*)"$/ do |path|
  parse_path_placeholders! path
  if @account
    delete "//#{@account.subdomain}.keygen.sh/#{@api_version}/#{path.sub(/^\//, '')}"
  else
    delete "//keygen.sh/#{@api_version}/#{path.sub(/^\//, '')}"
  end
end

Then /^the response status should be "([^\"]*)"$/ do |status|
  expect(status.to_i).to eq last_response.status
end

Then /^the JSON response should be an array with (\d+) "([^\"]*)"$/ do |count, name|
  json = JSON.parse last_response.body

  expect(json["data"].select { |d| d["type"] == name.pluralize }.length).to eq count.to_i
end

Then /^the JSON response should be an? "([^\"]*)"$/ do |name|
  json = JSON.parse last_response.body

  expect(json["data"]["type"]).to eq name.pluralize
end

Then /^the JSON response should be an? "([^\"]*)" with (?:the )?(\w+) "([^\"]*)"$/ do |name, attribute, value|
  json = JSON.parse last_response.body

  expect(json["data"]["type"]).to eq name.pluralize
  expect(json["data"]["attributes"][attribute].to_s).to eq value.to_s
end

Then /^the JSON response should be an? "([^\"]*)" that is (\w+)$/ do |name, attribute|
  json = JSON.parse last_response.body
  expect(name.pluralize).to eq json["data"]["type"]

  expect(json["data"]["attributes"][attribute]).to be true
end

Then /^the JSON response should be an? "([^\"]*)" that is not (\w+)$/ do |name, attribute|
  json = JSON.parse last_response.body

  expect(json["data"]["type"]).to eq name.pluralize
  expect(json["data"]["attributes"][attribute]).to be false
end

Then /^the JSON response should be an? "([^\"]*)" with the following (\w+):$/ do |name, attribute, body|
  json = JSON.parse last_response.body

  expect(json["data"]["type"]).to eq name.pluralize
  expect(json["data"]["attributes"][attribute]).to eq JSON.parse(body)
end

Then /^the JSON response should be meta with the following:$/ do |body|
  json = JSON.parse last_response.body

  expect(json["meta"]).to eq JSON.parse(body)
end

Then /^the JSON response should be an array of (\d+) errors?$/ do |count|
  json = JSON.parse last_response.body

  expect(json["errors"].length).to eq count.to_i
end
