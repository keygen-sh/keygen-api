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

  get "//api.keygen.sh/#{@api_version}/#{path.sub(/^\//, '')}"
end

When /^I send a POST request to "([^\"]*)"$/ do |path|
  parse_path_placeholders! path

  post "//api.keygen.sh/#{@api_version}/#{path.sub(/^\//, '')}"
end

When /^I send a PUT request to "([^\"]*)"$/ do |path|
  parse_path_placeholders! path

  put "//api.keygen.sh/#{@api_version}/#{path.sub(/^\//, '')}"
end

When /^I send a POST request to "([^\"]*)" with the following:$/ do |path, body|
  parse_path_placeholders! path
  parse_placeholders! body

  post "//api.keygen.sh/#{@api_version}/#{path.sub(/^\//, '')}", body
end

When /^I send a PATCH request to "([^\"]*)" with the following:$/ do |path, body|
  parse_path_placeholders! path
  parse_placeholders! body

  patch "//api.keygen.sh/#{@api_version}/#{path.sub(/^\//, '')}", body
end

When /^I send a PUT request to "([^\"]*)" with the following:$/ do |path, body|
  parse_path_placeholders! path
  parse_placeholders! body

  put "//api.keygen.sh/#{@api_version}/#{path.sub(/^\//, '')}", body
end

When /^I send a DELETE request to "([^\"]*)"$/ do |path|
  parse_path_placeholders! path

  delete "//api.keygen.sh/#{@api_version}/#{path.sub(/^\//, '')}"
end

Then /^the response status should be "([^\"]*)"$/ do |status|
  expect(last_response.status).to eq status.to_i
end

Then /^the JSON response should be an array with (\d+) "([^\"]*)"$/ do |count, name|
  json = JSON.parse last_response.body

  expect(json["data"].select { |d| d["type"] == name.pluralize }.length).to eq count.to_i
end

Then /^the JSON response should be an array of "([^\"]*)"$/ do |name|
  json = JSON.parse last_response.body

  json["data"].each { |d| expect(d["type"]).to eq name.pluralize }
end

Then /^the JSON response should be an? "([^\"]*)"$/ do |name|
  json = JSON.parse last_response.body

  expect(json["data"]["type"]).to eq name.pluralize
end

Then /^the JSON response should be an? "([^\"]*)" with (?:the )?(\w+) "([^\"]*)"$/ do |resource, attribute, value|
  json = JSON.parse last_response.body

  expect(json["data"]["type"]).to eq resource.pluralize
  expect(json["data"]["attributes"][attribute].to_s).to eq value.to_s
end

Then /^the JSON response should be an? "([^\"]*)" with a nil (\w+)$/ do |resource, attribute|
  json = JSON.parse last_response.body

  expect(json["data"]["type"]).to eq resource.pluralize
  expect(json["data"]["attributes"][attribute]).to eq nil
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
