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

When /^I send a PATCH request to "([^\"]*)"$/ do |path|
  parse_path_placeholders! path

  patch "//api.keygen.sh/#{@api_version}/#{path.sub(/^\//, '')}"
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

Then /^the response status should (?:contain|be) "([^\"]*)"$/ do |status|
  expect(last_response.status).to eq status.to_i
end

Then /^the response status should not (?:contain|be) "([^\"]*)"$/ do |status|
  expect(last_response.status).to_not eq status.to_i
end

Then /^the JSON response should (?:contain|be) an array (?:with|of) (\d+) "([^\"]*)"$/ do |count, name|
  json = JSON.parse last_response.body

  expect(json["data"].select { |d| d["type"] == name.pluralize }.length).to eq count.to_i
end

Then /^the JSON response should (?:contain|be) an array of "([^\"]*)"$/ do |name|
  json = JSON.parse last_response.body

  json["data"].each { |d| expect(d["type"]).to eq name.pluralize }

  begin
    account_id = json["data"]["relationships"]["accounts"]["data"]["id"]

    expect(account_id).to eq @account.id
  rescue
  end
end

Then /^the JSON response should (?:contain|be) an empty array$/ do
  json = JSON.parse last_response.body

  expect(json["data"].empty?).to be true

  begin
    account_id = json["data"]["relationships"]["accounts"]["data"]["id"]

    expect(account_id).to eq @account.id
  rescue
  end
end

Then /^the JSON response should (?:contain|be) an? "([^\"]*)"$/ do |name|
  json = JSON.parse last_response.body

  expect(json["data"]["type"]).to eq name.pluralize

  begin
    account_id = json["data"]["relationships"]["accounts"]["data"]["id"]

    expect(account_id).to eq @account.id
  rescue
  end
end

Then /^the JSON response should not (?:contain|be) an? "([^\"]*)"$/ do |name|
  json = JSON.parse last_response.body

  expect(json["data"]).to be nil
end

Then /^the JSON response should (?:contain|be) an? "([^\"]*)" with (?:(?:the|a) )?(\w+) "([^\"]*)"$/ do |resource, attribute, value|
  json = JSON.parse last_response.body

  expect(json["data"]["type"]).to eq resource.pluralize
  expect(json["data"]["attributes"][attribute].to_s).to eq value.to_s

  begin
    account_id = json["data"]["relationships"]["accounts"]["data"]["id"]

    expect(account_id).to eq @account.id
  rescue
  end
end

Then /^the JSON response should (?:contain|be) an? "([^\"]*)" with (?:a|an) (\w+) within seconds of "([^\"]*)"$/ do |resource, attribute, value|
  parse_placeholders! value

  json = JSON.parse last_response.body

  expect(json["data"]["type"]).to eq resource.pluralize

  # FIXME(ezekg) This is really hacky, but can't figure out another way to
  #              do this type of time validation in a reproducible way.
  a = json["data"]["attributes"][attribute].to_time.change sec: 0, nsec: 0
  b = value.to_time.change sec: 0, nsec: 0

  expect(a).to eq b

  begin
    account_id = json["data"]["relationships"]["accounts"]["data"]["id"]

    expect(account_id).to eq @account.id
  rescue
  end
end

Then /^the JSON response should (?:contain|be) an? "([^\"]*)" with a nil (\w+)$/ do |resource, attribute|
  json = JSON.parse last_response.body

  expect(json["data"]["type"]).to eq resource.pluralize
  expect(json["data"]["attributes"][attribute]).to eq nil

  begin
    account_id = json["data"]["relationships"]["accounts"]["data"]["id"]

    expect(account_id).to eq @account.id
  rescue
  end
end

Then /^the JSON response should (?:contain|be) an? "([^\"]*)" with a (\w+)(?: that is not nil)?$/ do |resource, attribute|
  json = JSON.parse last_response.body

  expect(json["data"]["type"]).to eq resource.pluralize
  expect(json["data"]["attributes"][attribute]).to_not eq nil

  begin
    account_id = json["data"]["relationships"]["accounts"]["data"]["id"]

    expect(account_id).to eq @account.id
  rescue
  end
end

Then /^the JSON response should (?:contain|be) an? "([^\"]*)" that is (\w+)$/ do |name, attribute|
  json = JSON.parse last_response.body
  expect(name.pluralize).to eq json["data"]["type"]

  expect(json["data"]["attributes"][attribute]).to be true

  begin
    account_id = json["data"]["relationships"]["accounts"]["data"]["id"]

    expect(account_id).to eq @account.id
  rescue
  end
end

Then /^the JSON response should (?:contain|be) an? "([^\"]*)" that is not (\w+)$/ do |name, attribute|
  json = JSON.parse last_response.body

  expect(json["data"]["type"]).to eq name.pluralize
  expect(json["data"]["attributes"][attribute]).to be false

  begin
    account_id = json["data"]["relationships"]["accounts"]["data"]["id"]

    expect(account_id).to eq @account.id
  rescue
  end
end

Then /^the JSON response should (?:contain|be) an? "([^\"]*)" with the following "([^\"]*)":$/ do |name, attribute, body|
  json = JSON.parse last_response.body

  expect(json["data"]["type"]).to eq name.pluralize
  expect(json["data"]["attributes"][attribute]).to eq JSON.parse(body)

  begin
    account_id = json["data"]["relationships"]["accounts"]["data"]["id"]

    expect(account_id).to eq @account.id
  rescue
  end
end

Then /^the JSON response should (?:contain|be) an? "(?:[^\"]*)" with the following attributes:$/ do |body|
  parse_placeholders! body
  json = JSON.parse last_response.body

  expect(json["data"]["attributes"]).to include JSON.parse(body)

  begin
    account_id = json["data"]["relationships"]["accounts"]["data"]["id"]

    expect(account_id).to eq @account.id
  rescue
  end
end

Then /^the JSON response should (?:contain|be) an? "(?:[^\"]*)" with the following relationships:$/ do |body|
  parse_placeholders! body
  json = JSON.parse last_response.body

  expect(json["data"]["relationships"]).to include JSON.parse(body)

  begin
    account_id = json["data"]["relationships"]["accounts"]["data"]["id"]

    expect(account_id).to eq @account.id
  rescue
  end
end

Then /^the JSON response should (?:contain|be) an? "(?:[^\"]*)" with the following meta:$/ do |body|
  parse_placeholders! body
  json = JSON.parse last_response.body

  expect(json["data"]["meta"]).to include JSON.parse(body)
end

Then /^the JSON response should (?:contain|be) meta with the following:$/ do |body|
  parse_placeholders! body
  json = JSON.parse last_response.body

  expect(json["meta"]).to eq JSON.parse(body)
end

Then /^the JSON response should (?:contain|be) an array of (\d+) errors?$/ do |count|
  json = JSON.parse last_response.body

  expect(json["errors"].length).to eq count.to_i
end

Given /^the (\w+) error should have the following properties:$/ do |i, body|
  parse_placeholders! body

  json = JSON.parse last_response.body
  numbers = {
    "first"   => 0,
    "second"  => 1,
    "third"   => 2,
    "fourth"  => 3,
    "fifth"   => 4,
    "sixth"   => 5,
    "seventh" => 6,
    "eigth"   => 7,
    "ninth"   => 8
  }

  err = json["errors"].send :[], numbers[i]
  expect(err).to eq JSON.parse(body)
end

Then /^the JSON response should contain the following links:$/ do |body|
  parse_placeholders! body

  json = JSON.parse last_response.body

  expect(json["links"]&.transform_values { |l| l.nil? ? l : URI.decode(l) }).to include JSON.parse(body)
end

Then /^the response should contain the following headers:$/ do |body|
  parse_placeholders! body

  expect(last_response.headers).to include JSON.parse(body)
end

Then /^the response should contain a valid signature header for "(\w+)"$/ do |slug|
  pub = OpenSSL::PKey::RSA.new Account.find(slug).public_key
  digest = OpenSSL::Digest::SHA256.new

  sig = Base64.decode64 last_response.headers['X-Signature']
  body = last_response.body.to_s

  res = pub.verify digest, sig, body rescue false

  expect(res).to be true
end
