# frozen_string_literal: true

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

When /^I send a POST request to "([^\"]*)" with the following badly encoded data:$/ do |path, body|
  parse_path_placeholders! path
  parse_placeholders! body

  post "//api.keygen.sh/#{@api_version}/#{path.sub(/^\//, '')}", body.encode!('CP1252')
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

  # Wait for all async deletion workers to finish
  DestroyModelWorker.drain
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

  if @account.present?
    json["data"].all? do |data|
      account_id =  data["relationships"]["account"]["data"]["id"]

      expect(account_id).to eq @account.id
    end
  end
end

Then /^the JSON response should (?:contain|be) an array of "([^\"]*)"$/ do |name|
  json = JSON.parse last_response.body

  json["data"].each { |d| expect(d["type"]).to eq name.pluralize }

  if @account.present?
    account_id = json["data"]["relationships"]["account"]["data"]["id"]

    expect(account_id).to eq @account.id
  end
end

Then /^the JSON response should (?:contain|be) an empty array$/ do
  json = JSON.parse last_response.body

  expect(json["data"].empty?).to be true
end

Then /^the JSON response should (?:contain|be) an? "([^\"]*)"$/ do |name|
  json = JSON.parse last_response.body

  expect(json["data"]["type"]).to eq name.pluralize

  if @account.present?
    account_id = json["data"]["relationships"]["account"]["data"]["id"]

    expect(account_id).to eq @account.id
  end
end

Then /^the JSON response should not (?:contain|be) an? "([^\"]*)"$/ do |name|
  json = JSON.parse last_response.body

  expect(json["data"]).to be nil
end

Then /^the JSON response should (?:contain|be) an? "([^\"]*)" with (?:(?:the|an?) )?(\w+) "([^\"]*)"$/ do |resource, attribute, value|
  json = JSON.parse last_response.body

  expect(json["data"]["type"]).to eq resource.pluralize
  case attribute
  when "id"
    expect(json["data"]["id"]).to eq value.to_s
  else
    expect(json["data"]["attributes"][attribute].to_s).to eq value.to_s
  end

  if @account.present?
    account_id = json["data"]["relationships"]["account"]["data"]["id"]

    expect(account_id).to eq @account.id
  end
end

Then /^the JSON response should (?:contain|be) an? "([^\"]*)" with a (\w+) that is not "([^\"]*)"$/ do |resource, attribute, value|
  json = JSON.parse last_response.body

  expect(json["data"]["type"]).to eq resource.pluralize
  case attribute
  when "id"
    expect(json["data"]["id"]).to_not eq value.to_s
  else
    expect(json["data"]["attributes"][attribute].to_s).to_not eq value.to_s
  end

  if @account.present?
    account_id = json["data"]["relationships"]["account"]["data"]["id"]

    expect(account_id).to eq @account.id
  end
end

Then /^the JSON response should (?:contain|be) an? "([^\"]*)" with (?:the|an?) (?:encrypted|signed|jwt) key (?:of )?(?:"([^\"]*)"|'([^\']*)') using "([^\"]*)"$/ do |resource, v1, v2, scheme|
  json = JSON.parse last_response.body

  # Double quotes vs single quotes
  value = v1 || v2

  case scheme
  when "RSA_2048_PKCS1_ENCRYPT"
    pub = OpenSSL::PKey::RSA.new @account.public_key

    key = Base64.urlsafe_decode64 json["data"]["attributes"]["key"].to_s
    dec = pub.public_decrypt key rescue nil

    expect(json["data"]["type"]).to eq resource.pluralize
    expect(dec).to eq value.to_s
  when "RSA_2048_PKCS1_SIGN"
    pub = OpenSSL::PKey::RSA.new @account.public_key
    digest = OpenSSL::Digest::SHA256.new

    encoded_key, encoded_sig = json["data"]["attributes"]["key"].to_s.split "."
    key = Base64.urlsafe_decode64 encoded_key
    sig = Base64.urlsafe_decode64 encoded_sig
    val = value.to_s

    res = pub.verify digest, sig, key rescue false

    expect(json["data"]["type"]).to eq resource.pluralize
    expect(key).to eq val
    expect(res).to be true
  when "RSA_2048_PKCS1_PSS_SIGN"
    pub = OpenSSL::PKey::RSA.new @account.public_key
    digest = OpenSSL::Digest::SHA256.new

    encoded_key, encoded_sig = json["data"]["attributes"]["key"].to_s.split "."
    key = Base64.urlsafe_decode64 encoded_key
    sig = Base64.urlsafe_decode64 encoded_sig
    val = value.to_s

    res = pub.verify_pss digest, sig, key, salt_length: :auto, mgf1_hash: "SHA256" rescue false

    expect(json["data"]["type"]).to eq resource.pluralize
    expect(key).to eq val
    expect(res).to be true
  when "RSA_2048_JWT_RS256"
    pub = OpenSSL::PKey::RSA.new @account.public_key
    jwt = json["data"]["attributes"]["key"].to_s
    dec = JWT.decode jwt, pub, true, algorithm: "RS256"
    payload = JSON.parse value
    val, alg = dec

    expect(json["data"]["type"]).to eq resource.pluralize
    expect(alg).to eq "alg" => "RS256"
    expect(val).to eq payload
  when "RSA_2048_PKCS1_SIGN_V2"
    pub = OpenSSL::PKey::RSA.new @account.public_key
    digest = OpenSSL::Digest::SHA256.new

    data, encoded_sig = json["data"]["attributes"]["key"].to_s.split "."
    prefix, encoded_key = data.split("/")
    key = Base64.urlsafe_decode64 encoded_key
    sig = Base64.urlsafe_decode64 encoded_sig
    val = value.to_s

    res = pub.verify digest, sig, "key/#{encoded_key}" rescue false

    expect(json["data"]["type"]).to eq resource.pluralize
    expect(prefix).to eq "key"
    expect(key).to eq val
    expect(res).to be true
  when "RSA_2048_PKCS1_PSS_SIGN_V2"
    pub = OpenSSL::PKey::RSA.new @account.public_key
    digest = OpenSSL::Digest::SHA256.new

    data, encoded_sig = json["data"]["attributes"]["key"].to_s.split "."
    prefix, encoded_key = data.split("/")
    key = Base64.urlsafe_decode64 encoded_key
    sig = Base64.urlsafe_decode64 encoded_sig
    val = value.to_s

    res = pub.verify_pss digest, sig, "key/#{encoded_key}", salt_length: :auto, mgf1_hash: "SHA256" rescue false

    expect(json["data"]["type"]).to eq resource.pluralize
    expect(prefix).to eq "key"
    expect(key).to eq val
    expect(res).to be true
  else
    raise "unknown encryption scheme"
  end
end

Then /^the JSON response should (?:contain|be) an? "([^\"]*)" with (?:the|an?) encoded (\w+) (?:of )?"([^\"]*)" using "([^\"]*)"$/ do |resource, attribute, value, scheme|
  json = JSON.parse last_response.body

  case scheme
  when "BASE64"
    dec = Base64.urlsafe_decode64 json["data"]["attributes"][attribute].to_s

    expect(json["data"]["type"]).to eq resource.pluralize
    expect(dec).to eq value.to_s
  else
    raise "unknown encoding scheme"
  end
end

Then /^the JSON response should (?:contain|be) an? "([^\"]*)" with (?:an?) (\w+) within seconds of "([^\"]*)"$/ do |resource, attribute, value|
  parse_placeholders! value

  json = JSON.parse last_response.body

  expect(json["data"]["type"]).to eq resource.pluralize

  t1 = json["data"]["attributes"][attribute].to_time
  t2 = value.to_time

  expect(t1).to be_within(3.seconds).of t2

  if @account.present?
    account_id = json["data"]["relationships"]["account"]["data"]["id"]

    expect(account_id).to eq @account.id
  end
end

Then /^the JSON response should (?:contain|be) an? "([^\"]*)" with a nil (\w+)$/ do |resource, attribute|
  json = JSON.parse last_response.body

  expect(json["data"]["type"]).to eq resource.pluralize
  expect(json["data"]["attributes"][attribute]).to eq nil

  if @account.present?
    account_id = json["data"]["relationships"]["account"]["data"]["id"]

    expect(account_id).to eq @account.id
  end
end

Then /^the JSON response should (?:contain|be) an? "([^\"]*)" with a (\w+)(?: that is not nil)?$/ do |resource, attribute|
  json = JSON.parse last_response.body

  expect(json["data"]["type"]).to eq resource.pluralize
  expect(json["data"]["attributes"][attribute]).to_not eq nil

  if @account.present?
    account_id = json["data"]["relationships"]["account"]["data"]["id"]

    expect(account_id).to eq @account.id
  end
end

Then /^the JSON response should (?:contain|be) an? "([^\"]*)" that (?:is|does) (\w+)$/ do |name, attribute|
  json = JSON.parse last_response.body
  expect(name.pluralize).to eq json["data"]["type"]

  expect(json["data"]["attributes"][attribute]).to be true

  if @account.present?
    account_id = json["data"]["relationships"]["account"]["data"]["id"]

    expect(account_id).to eq @account.id
  end
end

Then /^the JSON response should (?:contain|be) an? "([^\"]*)" that (?:is|does) not (\w+)$/ do |resource, attribute|
  json = JSON.parse last_response.body

  expect(json["data"]["type"]).to eq resource.pluralize
  expect(json["data"]["attributes"][attribute]).to be false

  if @account.present?
    account_id = json["data"]["relationships"]["account"]["data"]["id"]

    expect(account_id).to eq @account.id
  end
end

Then /^the JSON response should (?:contain|be) an? "([^\"]*)" without an? (\w+) attribute$/ do |resource, attribute|
  json = JSON.parse last_response.body

  expect(json["data"]["type"]).to eq resource.pluralize
  expect(json["data"]["attributes"].key?(attribute)).to be false

  if @account.present?
    account_id = json["data"]["relationships"]["account"]["data"]["id"]

    expect(account_id).to eq @account.id
  end
end

Then /^the JSON response should be meta that contains a valid activation proof of the following dataset:/ do |dataset|
  parse_placeholders! dataset
  json = JSON.parse last_response.body

  # Clean up the dataset whitespace (parse then regenerate JSON)
  data = JSON.generate(JSON.parse(dataset))

  # Sign with 2048-bit RSA SHA256 using PKCS1 v1.5 padding
  priv = OpenSSL::PKey::RSA.new(@account.private_key)
  sig = priv.sign(OpenSSL::Digest::SHA256.new, data)

  encoded_data = Base64.urlsafe_encode64(data)
  encoded_sig = Base64.urlsafe_encode64(sig)

  proof = "#{encoded_data}.#{encoded_sig}"

  expect(json["meta"]["proof"]).to eq proof
end

Then /^the JSON response should (?:contain|be) an? "([^\"]*)" with the following "([^\"]*)":$/ do |resource, attribute, body|
  json = JSON.parse last_response.body

  expect(json["data"]["type"]).to eq resource.pluralize
  expect(json["data"]["attributes"][attribute]).to eq JSON.parse(body)

  if @account.present?
    account_id = json["data"]["relationships"]["account"]["data"]["id"]

    expect(account_id).to eq @account.id
  end
end

Then /^the JSON response should (?:contain|be) an? "([^\"]*)" with the following attributes:$/ do |resource, body|
  parse_placeholders! body
  json = JSON.parse last_response.body

  expect(json["data"]["type"]).to eq resource.pluralize
  expect(json["data"]["attributes"]).to include JSON.parse(body)

  if @account.present?
    account_id = json["data"]["relationships"]["account"]["data"]["id"]

    expect(account_id).to eq @account.id
  end
end

Then /^the JSON response should (?:contain|be) an? "([^\"]*)" with the following relationships:$/ do |resource, body|
  parse_placeholders! body
  json = JSON.parse last_response.body

  expect(json["data"]["type"]).to eq resource.pluralize
  expect(json["data"]["relationships"]).to include JSON.parse(body)

  if @account.present?
    account_id = json["data"]["relationships"]["account"]["data"]["id"]

    expect(account_id).to eq @account.id
  end
end

Then /^the JSON response should (?:contain|be) an? "([^\"]*)" with the following meta:$/ do |resource, body|
  parse_placeholders! body
  json = JSON.parse last_response.body

  expect(json["data"]["type"]).to eq resource.pluralize
  expect(json["data"]["meta"]).to include JSON.parse(body)
end

Then /^the JSON response should (?:contain|be) an? "([^\"]*)" with no meta$/ do |resource|
  json = JSON.parse last_response.body

  expect(json["data"]["type"]).to eq resource.pluralize
  expect(json["data"].key?("meta")).to be false
end

Then /^the JSON response should (?:contain|be) meta with the following:$/ do |body|
  parse_placeholders! body
  json = JSON.parse last_response.body

  expect(json["meta"]).to eq JSON.parse(body)
end

Then /^the JSON response should (?:contain|be) meta which includes the following:$/ do |body|
  parse_placeholders! body
  json = JSON.parse last_response.body

  expect(json["meta"]).to include JSON.parse(body)
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

  expect(json["links"]&.transform_values { |l| l.is_a?(String) ? URI.decode(l) : l }).to include JSON.parse(body)
end

Then /^the response should contain the following headers:$/ do |body|
  parse_placeholders! body

  expect(last_response.headers).to include JSON.parse(body)
end

Then /^the response should contain the following raw headers:$/ do |body|
  parse_placeholders! body

  headers = body.split /\n/

  headers.each do |raw|
    key, value = raw.split ":"

    expect(last_response.headers).to include key => value.strip
  end

end

Then /^the response should contain a valid signature header for "(\w+)"$/ do |slug|
  pub = OpenSSL::PKey::RSA.new Account.find(slug).public_key
  digest = OpenSSL::Digest::SHA256.new

  sig = Base64.strict_decode64 last_response.headers['X-Signature']
  body = last_response.body.to_s

  res = pub.verify digest, sig, body rescue false

  expect(res).to be true
end
