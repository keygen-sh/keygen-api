# frozen_string_literal: true

World Rack::Test::Methods

Given 'I use API version {string}' do |version|
  header 'Keygen-Version', version
end

Given /^I send and accept JSON$/ do
  header "Content-Type", "application/vnd.api+json"
  header "Accept", "application/vnd.api+json"

  # Random accept signature
  algorithms = %w[ed25519 rsa-pss-sha256 rsa-sha256]

  header 'Keygen-Accept-Signature', %(algorithm="#{algorithms.sample}") if
    rand(0...6) == 0 # Dice roll to test for no header
end

Given /^time is frozen (\d+) (\w+) into the future$/ do |duration_number, duration_word|
  travel_to(duration_number.to_i.send(duration_word).from_now)
end

Given /^time is frozen at "([^\"]*)"$/ do |t|
  travel_to(t)
end

Then /^time is unfrozen$/ do
  travel_back
end

When /^I send a GET request to "([^\"]*)"$/ do |path|
  path = parse_path_placeholders(path, account: @account, bearer: @bearer, crypt: @crypt)

  case %r{/accounts/(?<account>[^/]+)}.match(path)
  in account: id if Keygen.singleplayer?
    account = FindByAliasService.call(Account, id:, aliases: :slug) rescue nil

    stub_env 'KEYGEN_ACCOUNT_ID', account&.id
  else
  end

  unless path.starts_with?('//')
    get "//api.keygen.sh/#{@api_version}/#{path.sub(/^\//, '')}"
  else
    get path
  end
end

When /^I send a POST request to "([^\"]*)"$/ do |path|
  path = parse_path_placeholders(path, account: @account, bearer: @bearer, crypt: @crypt)

  case %r{/accounts/(?<account>[^/]+)}.match(path)
  in account: id if Keygen.singleplayer?
    account = FindByAliasService.call(Account, id:, aliases: :slug) rescue nil

    stub_env 'KEYGEN_ACCOUNT_ID', account&.id
  else
  end

  post "//api.keygen.sh/#{@api_version}/#{path.sub(/^\//, '')}"
end

When /^I send a PUT request to "([^\"]*)"$/ do |path|
  path = parse_path_placeholders(path, account: @account, bearer: @bearer, crypt: @crypt)

  case %r{/accounts/(?<account>[^/]+)}.match(path)
  in account: id if Keygen.singleplayer?
    account = FindByAliasService.call(Account, id:, aliases: :slug) rescue nil

    stub_env 'KEYGEN_ACCOUNT_ID', account&.id
  else
  end

  put "//api.keygen.sh/#{@api_version}/#{path.sub(/^\//, '')}"
end

When /^I send a PATCH request to "([^\"]*)"$/ do |path|
  path = parse_path_placeholders(path, account: @account, bearer: @bearer, crypt: @crypt)

  case %r{/accounts/(?<account>[^/]+)}.match(path)
  in account: id if Keygen.singleplayer?
    account = FindByAliasService.call(Account, id:, aliases: :slug) rescue nil

    stub_env 'KEYGEN_ACCOUNT_ID', account&.id
  else
  end

  patch "//api.keygen.sh/#{@api_version}/#{path.sub(/^\//, '')}"
end

When /^I send a POST request to "([^\"]*)" with the following:$/ do |path, body|
  path = parse_path_placeholders(path, account: @account, bearer: @bearer, crypt: @crypt)
  body = parse_placeholders(body, account: @account, bearer: @bearer, crypt: @crypt)

  case %r{/accounts/(?<account>[^/]+)}.match(path)
  in account: id if Keygen.singleplayer?
    account = FindByAliasService.call(Account, id:, aliases: :slug) rescue nil

    stub_env 'KEYGEN_ACCOUNT_ID', account&.id
  else
  end

  post "//api.keygen.sh/#{@api_version}/#{path.sub(/^\//, '')}", body
end

When /^I send a POST request to "([^\"]*)" with the following badly encoded data:$/ do |path, body|
  path = parse_path_placeholders(path, account: @account, bearer: @bearer, crypt: @crypt)
  body = parse_placeholders(body, account: @account, bearer: @bearer, crypt: @crypt)

  case %r{/accounts/(?<account>[^/]+)}.match(path)
  in account: id if Keygen.singleplayer?
    account = FindByAliasService.call(Account, id:, aliases: :slug) rescue nil

    stub_env 'KEYGEN_ACCOUNT_ID', account&.id
  else
  end

  post "//api.keygen.sh/#{@api_version}/#{path.sub(/^\//, '')}", body.encode!('CP1252')
end

When /^I send a PATCH request to "([^\"]*)" with the following:$/ do |path, body|
  path = parse_path_placeholders(path, account: @account, bearer: @bearer, crypt: @crypt)
  body = parse_placeholders(body, account: @account, bearer: @bearer, crypt: @crypt)

  case %r{/accounts/(?<account>[^/]+)}.match(path)
  in account: id if Keygen.singleplayer?
    account = FindByAliasService.call(Account, id:, aliases: :slug) rescue nil

    stub_env 'KEYGEN_ACCOUNT_ID', account&.id
  else
  end

  patch "//api.keygen.sh/#{@api_version}/#{path.sub(/^\//, '')}", body
end

When /^I send a PUT request to "([^\"]*)" with the following:$/ do |path, body|
  path = parse_path_placeholders(path, account: @account, bearer: @bearer, crypt: @crypt)
  body = parse_placeholders(body, account: @account, bearer: @bearer, crypt: @crypt)

  case %r{/accounts/(?<account>[^/]+)}.match(path)
  in account: id if Keygen.singleplayer?
    account = FindByAliasService.call(Account, id:, aliases: :slug) rescue nil

    stub_env 'KEYGEN_ACCOUNT_ID', account&.id
  else
  end

  put "//api.keygen.sh/#{@api_version}/#{path.sub(/^\//, '')}", body
end

When /^I send a DELETE request to "([^\"]*)" with the following:$/ do |path, body|
  path = parse_path_placeholders(path, account: @account, bearer: @bearer, crypt: @crypt)
  body = parse_placeholders(body, account: @account, bearer: @bearer, crypt: @crypt)

  case %r{/accounts/(?<account>[^/]+)}.match(path)
  in account: id if Keygen.singleplayer?
    account = FindByAliasService.call(Account, id:, aliases: :slug) rescue nil

    stub_env 'KEYGEN_ACCOUNT_ID', account&.id
  else
  end

  delete "//api.keygen.sh/#{@api_version}/#{path.sub(/^\//, '')}", body
end

When /^I send a DELETE request to "([^\"]*)"$/ do |path|
  path = parse_path_placeholders(path, account: @account, bearer: @bearer, crypt: @crypt)

  case %r{/accounts/(?<account>[^/]+)}.match(path)
  in account: id if Keygen.singleplayer?
    account = FindByAliasService.call(Account, id:, aliases: :slug) rescue nil

    stub_env 'KEYGEN_ACCOUNT_ID', account&.id
  else
  end

  delete "//api.keygen.sh/#{@api_version}/#{path.sub(/^\//, '')}"

  # Wait for all async deletion workers to finish
  DestroyModelWorker.drain
  YankArtifactWorker.drain
rescue Timeout::Error
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

Then /^the JSON response should (?:contain|be) an array (?:with|of) (\d+) "([^\"]*)" with the following attributes:$/ do |count, resource, body|
  body  = parse_placeholders(body, account: @account, bearer: @bearer, crypt: @crypt)
  json  = JSON.parse(last_response.body)
  attrs = JSON.parse(body)

  matches = json['data'].select { |data|
    data['type'] == resource.pluralize && attrs <= data['attributes']
  }

  expect(matches.count).to eq count.to_i
end

Then /^the JSON response should (?:contain|be) an array (?:with|of) (\d+) "([^\"]*)" with the following relationships:$/ do |count, resource, body|
  body = parse_placeholders(body, account: @account, bearer: @bearer, crypt: @crypt)
  json = JSON.parse(last_response.body)
  rels = JSON.parse(body)

  matches = json['data'].select { |data|
    data['type'] == resource.pluralize && rels <= data['relationships']
  }

  expect(matches.count).to eq count.to_i
end

Then /^the JSON response should (?:contain|be) an array of "([^\"]*)"$/ do |name|
  json = JSON.parse last_response.body

  json["data"].each { |d| expect(d["type"]).to eq name.pluralize }
end

Then /^the JSON response should (?:contain|be) an empty array$/ do
  json = JSON.parse last_response.body

  expect(json["data"].empty?).to be true
end

Then /^the JSON response should (?:contain|be) an? "([^\"]*)"$/ do |name|
  json = JSON.parse last_response.body

  expect(json["data"]["type"]).to eq name.pluralize
end

Then /^the JSON response should not (?:contain|be) an? "([^\"]*)"$/ do |name|
  json = JSON.parse last_response.body

  resource = json["data"]
  if resource.present?
    expect(resource["type"]).to_not eq name.pluralize
  else
    expect(resource).to eq nil
  end
end

Then /^the JSON response should contain an included "([^\"]*)"$/ do |name|
  json = JSON.parse last_response.body
  inlc = json["included"]
  expect(incl).to be_an Array

  res = incl&.any? { |i| i["type"] == name.pluralize }
  expect(res).to be true
end

Then /^the JSON response should contain an included "([^\"]*)" with the following relationships:$/ do |name, body|
  body = parse_placeholders(body, account: @account, bearer: @bearer, crypt: @crypt)

  json = JSON.parse last_response.body
  incl = json["included"]
  expect(incl).to be_an Array

  res = incl&.any? { |i| i["type"] == name.pluralize }
  expect(res).to be true

  record = incl.first
  rels = record["relationships"]
  expect(rels).to include JSON.parse(body)
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
end

Then /^the JSON response should (?:contain|be) an? "([^\"]*)" with an? (\w+) that is not "([^\"]*)"$/ do |resource, attribute, value|
  json = JSON.parse last_response.body

  expect(json["data"]["type"]).to eq resource.pluralize
  case attribute
  when "id"
    expect(json["data"]["id"]).to_not eq value.to_s
  else
    expect(json["data"]["attributes"][attribute].to_s).to_not eq value.to_s
  end
end

Then /^the JSON response should (?:contain|be) an? "([^\"]*)" with (?:the|an?) (?:encrypted|signed|JWT) key (?:of )?(?:"([^\"]*)"|'([^\']*)') using "([^\"]*)"$/ do |resource, v1, v2, scheme|
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
  when 'ED25519_SIGN'
    verify_key = Ed25519::VerifyKey.new [@account.ed25519_public_key].pack('H*')
    signing_data, encoded_sig = json.dig('data', 'attributes', 'key').to_s.split('.')
    signing_prefix, encoded_key = signing_data.split('/')
    key = Base64.urlsafe_decode64 encoded_key
    sig = Base64.urlsafe_decode64 encoded_sig
    val = value.to_s

    ok = verify_key.verify(sig, signing_data)

    expect(json.dig('data', 'type')).to eq resource.pluralize
    expect(signing_prefix).to eq 'key'
    expect(key).to eq val
    expect(ok).to be true
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
  value = parse_placeholders(value, account: @account, bearer: @bearer, crypt: @crypt)

  json = JSON.parse last_response.body

  expect(json["data"]["type"]).to eq resource.pluralize

  t1 = json["data"]["attributes"][attribute]&.to_time
  t2 = value&.to_time

  expect(t1).to be_within(3.seconds).of t2
end

Then /^the JSON response should (?:contain|be) an? "([^\"]*)" with a nil (\w+)$/ do |resource, attribute|
  json = JSON.parse last_response.body

  expect(json["data"]["type"]).to eq resource.pluralize
  expect(json["data"]["attributes"][attribute]).to eq nil
end

Then /^the JSON response should (?:contain|be) an? "([^\"]*)" without an? (\w+)$/ do |resource, attribute|
  json = JSON.parse last_response.body

  expect(json["data"]["type"]).to eq resource.pluralize
  expect(json["data"]["attributes"][attribute]).to eq nil
end

Then /^the JSON response should (?:contain|be) an? "([^\"]*)" with an? (\w+)(?: that is not nil)?$/ do |resource, attribute|
  json = JSON.parse last_response.body

  expect(json["data"]["type"]).to eq resource.pluralize
  expect(json["data"]["attributes"][attribute]).to_not eq nil
end

Then /^the JSON response should (?:contain|be) an? "([^\"]*)" that (?:is|does|has) (\w+)$/ do |name, attribute|
  json = JSON.parse last_response.body
  expect(name.pluralize).to eq json["data"]["type"]

  expect(json["data"]["attributes"][attribute]).to be true
end

Then /^the JSON response should (?:contain|be) an? "([^\"]*)" that (?:is|does) not (\w+)$/ do |resource, attribute|
  json = JSON.parse last_response.body

  expect(json["data"]["type"]).to eq resource.pluralize
  expect(json["data"]["attributes"][attribute]).to be false
end

Then /^the JSON response should (?:contain|be) an? "([^\"]*)" without an? "([^\"]*)" attribute$/ do |resource, attribute|
  json = JSON.parse last_response.body

  expect(json["data"]["type"]).to eq resource.pluralize
  expect(json["data"]["attributes"].key?(attribute)).to be false
end

Then /^the JSON response should be meta that contains a valid activation proof of the following dataset:/ do |body|
  body = parse_placeholders(body, account: @account, bearer: @bearer, crypt: @crypt)
  json = JSON.parse last_response.body

  expected_dataset = JSON.parse(body)
  proof = json.dig("meta", "proof")
  data, encoded_sig = proof.split(".")
  prefix, encoded_dataset = data.split("/")
  dataset = JSON.parse(Base64.urlsafe_decode64(encoded_dataset))

  expect(dataset).to include expected_dataset
  expect(prefix).to eq "proof"

  # Verify with 2048-bit RSA SHA256 using PKCS1 v1.5 padding
  pub = OpenSSL::PKey::RSA.new(@account.public_key)
  digest = OpenSSL::Digest::SHA256.new
  sig = Base64.urlsafe_decode64(encoded_sig)
  ok = pub.verify(digest, sig, "proof/#{encoded_dataset}") rescue false

  expect(ok).to be true
end

Then /^the JSON response should a "license" that contains a valid "([^\"]*)" key with the following dataset:$/ do |scheme, body|
  body = parse_placeholders(body, account: @account, bearer: @bearer, crypt: @crypt)

  json = JSON.parse last_response.body
  resource_type = json.dig("data", "type")
  encoded_key = json.dig("data", "attributes", "key")
  expected_dataset = JSON.parse(body)

  expect(resource_type).to eq "licenses"

  case scheme
  when "RSA_2048_PKCS1_ENCRYPT"
    pub = OpenSSL::PKey::RSA.new @account.public_key

    encrypted_data = Base64.urlsafe_decode64 encoded_key
    decrypted_data = pub.public_decrypt encrypted_data rescue nil
    dataset = JSON.parse(decrypted_data)

    expect(dataset).to include expected_dataset
  when "RSA_2048_PKCS1_SIGN"
    pub = OpenSSL::PKey::RSA.new @account.public_key
    digest = OpenSSL::Digest::SHA256.new

    encoded_dataset, encoded_sig = encoded_key.split(".")
    dataset = JSON.parse(Base64.urlsafe_decode64(encoded_dataset))

    expect(dataset).to include expected_dataset

    signing_data = Base64.urlsafe_decode64 encoded_dataset
    sig = Base64.urlsafe_decode64 encoded_sig
    ok = pub.verify digest, sig, signing_data rescue false

    expect(ok).to be true
  when "RSA_2048_PKCS1_PSS_SIGN"
    pub = OpenSSL::PKey::RSA.new @account.public_key
    digest = OpenSSL::Digest::SHA256.new

    encoded_dataset, encoded_sig = encoded_key.split(".")
    dataset = JSON.parse(Base64.urlsafe_decode64(encoded_dataset))

    expect(dataset).to include expected_dataset

    signing_data = Base64.urlsafe_decode64 encoded_dataset
    sig = Base64.urlsafe_decode64 encoded_sig
    ok = pub.verify_pss digest, sig, signing_data, salt_length: :auto, mgf1_hash: "SHA256" rescue false

    expect(ok).to be true
  when "RSA_2048_JWT_RS256"
    pub = OpenSSL::PKey::RSA.new @account.public_key

    jwt = JWT.decode encoded_key, pub, true, algorithm: "RS256"

    expect(jwt).to_not be_nil

    dataset, alg = jwt

    expect(alg).to eq "alg" => "RS256"
    expect(dataset).to include expected_dataset
  when "RSA_2048_PKCS1_SIGN_V2"
    pub = OpenSSL::PKey::RSA.new @account.public_key
    digest = OpenSSL::Digest::SHA256.new

    signing_data, encoded_sig = encoded_key.split(".")
    prefix, encoded_dataset = signing_data.split("/")
    dataset = JSON.parse(Base64.urlsafe_decode64(encoded_dataset))

    expect(dataset).to include expected_dataset
    expect(prefix).to eq "key"

    sig = Base64.urlsafe_decode64 encoded_sig
    ok = pub.verify digest, sig, "key/#{encoded_dataset}" rescue false

    expect(ok).to be true
  when "RSA_2048_PKCS1_PSS_SIGN_V2"
    pub = OpenSSL::PKey::RSA.new @account.public_key
    digest = OpenSSL::Digest::SHA256.new

    signing_data, encoded_sig = encoded_key.split(".")
    prefix, encoded_dataset = signing_data.split("/")
    dataset = JSON.parse(Base64.urlsafe_decode64(encoded_dataset))

    expect(dataset).to include expected_dataset
    expect(prefix).to eq "key"

    sig = Base64.urlsafe_decode64 encoded_sig
    ok = pub.verify_pss digest, sig, "key/#{encoded_dataset}", salt_length: :auto, mgf1_hash: "SHA256" rescue false

    expect(ok).to be true
  when 'ED25519_SIGN'
    verify_key = Ed25519::VerifyKey.new [@account.ed25519_public_key].pack('H*')
    signing_data, encoded_sig = json.dig('data', 'attributes', 'key').to_s.split('.')
    signing_prefix, encoded_dataset = signing_data.split('/')
    dataset = JSON.parse(Base64.urlsafe_decode64(encoded_dataset))

    expect(dataset).to include expected_dataset
    expect(signing_prefix).to eq 'key'

    sig = Base64.urlsafe_decode64 encoded_sig
    ok = verify_key.verify(sig, signing_data)

    expect(ok).to be true
  else
    raise "unknown encryption scheme"
  end
end

Then /^the JSON response should (?:contain|be) an? "([^\"]*)" with the following "([^\"]*)":$/ do |resource, attribute, body|
  json = JSON.parse last_response.body

  expect(json["data"]["type"]).to eq resource.pluralize
  expect(json["data"]["attributes"][attribute]).to eq JSON.parse(body)
end

Then /^the JSON response should (?:contain|be) an? "([^\"]*)" with the following data:$/ do |resource, body|
  body = parse_placeholders(body, account: @account, bearer: @bearer, crypt: @crypt)
  json = JSON.parse last_response.body

  expect(json["data"]["type"]).to eq resource.pluralize
  expect(json["data"]).to include JSON.parse(body)
end

Then /^the JSON response should (?:contain|be) an? "([^\"]*)" with the following attributes:$/ do |resource, body|
  body = parse_placeholders(body, account: @account, bearer: @bearer, crypt: @crypt)
  json = JSON.parse last_response.body

  expect(json["data"]["type"]).to eq resource.pluralize
  expect(json["data"]["attributes"]).to include JSON.parse(body)
end

Then /^the JSON response should (?:contain|be) an? "([^\"]*)" with the following relationships:$/ do |resource, body|
  body = parse_placeholders(body, account: @account, bearer: @bearer, crypt: @crypt)
  json = JSON.parse last_response.body

  expect(json["data"]["type"]).to eq resource.pluralize
  expect(json["data"]["relationships"]).to include JSON.parse(body)
end

Then /^the JSON response should (?:contain|be) an? "([^\"]*)" with the following meta:$/ do |resource, body|
  body = parse_placeholders(body, account: @account, bearer: @bearer, crypt: @crypt)
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
  body = parse_placeholders(body, account: @account, bearer: @bearer, crypt: @crypt)
  json = JSON.parse last_response.body

  expect(json["meta"]).to eq JSON.parse(body)
end

Then /^the JSON response should (?:contain|be) meta which includes the following:$/ do |body|
  body = parse_placeholders(body, account: @account, bearer: @bearer, crypt: @crypt)
  json = JSON.parse last_response.body

  expect(json["meta"]).to include JSON.parse(body)
end

Then /^the JSON response should (?:contain|be) an array of (\d+) errors?$/ do |count|
  json = JSON.parse last_response.body

  expect(json["errors"].size).to eq count.to_i
end

Then /^the JSON response should (?:contain|be) an array of errors?$/ do
  json = JSON.parse last_response.body

  expect(json["errors"].size).to be >= 1
end

Given /^the (\w+) error should have the following properties:$/ do |named_idx, body|
  body = parse_placeholders(body, account: @account, bearer: @bearer, crypt: @crypt)
  json = JSON.parse(last_response.body)
  err  = json["errors"].send(named_idx)

  expect(err).to include JSON.parse(body)
end

Then /^the JSON response should contain the following links:$/ do |body|
  body = parse_placeholders(body, account: @account, bearer: @bearer, crypt: @crypt)

  json = JSON.parse last_response.body

  expect(json["links"]&.transform_values { |l| l.is_a?(String) ? URI.decode_www_form_component(l) : l }).to include JSON.parse(body)
end

Then /^the response should contain the following headers:$/ do |body|
  body = parse_placeholders(body, account: @account, bearer: @bearer, crypt: @crypt)

  expect(last_response.headers).to include JSON.parse(body)
end

Then /^the response should contain the following raw headers:$/ do |body|
  body = parse_placeholders(body, account: @account, bearer: @bearer, crypt: @crypt)

  headers = body.split /\n/

  headers.each do |raw|
    key, value = raw.split ":"

    expect(last_response.headers).to include key => value.strip
  end

end

Then /^the response should contain a valid(?: "([^"]+)")? signature header for "([^"]+)"$/ do |expected_algorithm, account_id|
  account = FindByAliasService.call(Account, id: account_id, aliases: :slug)
  req     = last_request
  res     = last_response

  # Legacy signature header
  begin
    pub     = OpenSSL::PKey::RSA.new(account.public_key)
    digest  = OpenSSL::Digest::SHA256.new
    enc_sig = res.headers['X-Signature']
    sig     = Base64.strict_decode64(enc_sig)
    body    = res.body.to_s
    ok      = pub.verify(digest, sig, body) rescue false

    expect(ok).to be true
  end

  # Signature header
  begin
    attrs = SignatureHelper.parse(res.headers['Keygen-Signature'])
    expect(attrs).to_not eq nil

    keyid     = attrs[:keyid]
    algorithm = attrs[:algorithm]
    signature = attrs[:signature]
    headers   = attrs[:headers]

    if expected_algorithm.present?
      expect(algorithm).to eq expected_algorithm
    else
      expect(algorithm).to satisfy { |v| %w[ed25519 rsa-pss-sha256 rsa-sha256].include?(v) }
    end

    expect(keyid).to eq account.id
    expect(signature).to be_a String
    expect(headers).to eq %w[(request-target) host date digest]

    sha256 = OpenSSL::Digest::SHA256.new
    digest = sha256.digest(res.body)
    enc    = Base64.strict_encode64(digest)

    expect("sha-256=#{enc}").to eq res.headers['Digest']

    ok = SignatureHelper.verify(
      account: account,
      method: req.request_method,
      host: account.cname.presence || account.domain.presence || 'api.keygen.sh',
      uri: req.fullpath,
      body: res.body,
      signature_algorithm: algorithm,
      signature_header: res.headers['Keygen-Signature'],
      digest_header: res.headers['Digest'],
      date_header: res.headers['Date'],
    )

    expect(ok).to be true
  end
end

Then /^the response should be a "([^"]+)" certificate$/ do |type|
  account = @account
  req     = last_request
  res     = last_response
  cert    = last_response.body

  expect(cert).to start_with "-----BEGIN #{type.upcase} FILE-----\n"
  expect(cert).to end_with "-----END #{type.upcase} FILE-----\n"
end

Then /^the response should be a "([^"]+)" certificate signed using "([^"]+)"$/ do |type, expected_alg|
  account = @account
  req     = last_request
  res     = last_response
  cert    = last_response.body

  expect(cert).to start_with "-----BEGIN #{type.upcase} FILE-----\n"
  expect(cert).to end_with "-----END #{type.upcase} FILE-----\n"

  payload = cert.delete_prefix("-----BEGIN #{type.upcase} FILE-----\n")
                .delete_suffix("-----END #{type.upcase} FILE-----\n")

  attrs = JSON.parse(Base64.decode64(payload))
  alg   = attrs.fetch('alg')
  enc   = attrs.fetch('enc')
  sig   = attrs.fetch('sig')

  expect(alg).to end_with expected_alg

  signing_prefix = type.downcase
  signing_data   = "#{signing_prefix}/#{enc}"
  sig_bytes      = Base64.strict_decode64(sig)
  ok             = false

  case alg
  when /ed25519/
    ed25519 = Ed25519::VerifyKey.new [account.ed25519_public_key].pack('H*')
    ok      = ed25519.verify(sig_bytes, signing_data) rescue false
  when /rsa-pss-sha256/
    rsa = OpenSSL::PKey::RSA.new(account.public_key)
    ok  = rsa.verify_pss(OpenSSL::Digest::SHA256.new, sig_bytes, signing_data, salt_length: :auto, mgf1_hash: 'SHA256') rescue false
  when /rsa-sha256/
    rsa = OpenSSL::PKey::RSA.new(account.public_key)
    ok  = rsa.verify(OpenSSL::Digest::SHA256.new, sig_bytes, signing_data) rescue false
  end

  expect(ok).to be true
end

Then /^the response should be a "([^"]+)" certificate with the following encoded data:$/ do |type, body|
  body = parse_placeholders(body, account: @account, bearer: @bearer, crypt: @crypt)

  req  = last_request
  res  = last_response
  cert = last_response.body

  expect(cert).to start_with "-----BEGIN #{type.upcase} FILE-----\n"
  expect(cert).to end_with "-----END #{type.upcase} FILE-----\n"

  payload = cert.delete_prefix("-----BEGIN #{type.upcase} FILE-----\n")
                .delete_suffix("-----END #{type.upcase} FILE-----\n")

  attrs = JSON.parse(Base64.decode64(payload))
  enc   = attrs.fetch('enc')
  data  = JSON.parse(Base64.decode64(enc))

  actual_data = data.fetch('data')     { nil }
  actual_meta = data.fetch('meta')     { nil }
  actual_incl = data.fetch('included') { nil }

  expected_json = JSON.parse(body)
  expected_data = expected_json.fetch('data')     { nil }
  expected_meta = expected_json.fetch('meta')     { nil }
  expected_incl = expected_json.fetch('included') { nil }

  if expected_data.present?
    expect(actual_data).to deep_include expected_data
  end

  if expected_meta.present?
    expect(actual_meta).to deep_include expected_meta
  end

  if expected_incl.present?
    expect(actual_incl).to deep_include *expected_incl
  else
    expect(actual_incl).to be_nil
  end
end

Then /^the response should be a "([^"]+)" certificate with the following encrypted data:$/ do |type, body|
  body = parse_placeholders(body, account: @account, bearer: @bearer, crypt: @crypt)

  account = @account
  req     = last_request
  res     = last_response
  cert    = last_response.body

  expect(cert).to start_with "-----BEGIN #{type.upcase} FILE-----\n"
  expect(cert).to end_with "-----END #{type.upcase} FILE-----\n"

  payload = cert.delete_prefix("-----BEGIN #{type.upcase} FILE-----\n")
                .delete_suffix("-----END #{type.upcase} FILE-----\n")

  attrs = JSON.parse(Base64.decode64(payload))
  enc   = attrs.fetch('enc')

  # FIXME(ezekg) This should not assume first record
  secret =
    case type.downcase
    when 'license'
      account.licenses.first.key
    when 'machine'
      account.licenses.first.key + account.machines.first.fingerprint
    end

  aes = OpenSSL::Cipher::AES256.new(:GCM)
  aes.decrypt

  key         = OpenSSL::Digest::SHA256.digest(secret)
  ciphertext,
  iv,
  tag         = enc.split('.')
                   .map { Base64.strict_decode64(_1) }

  aes.key = key
  aes.iv  = iv

  aes.auth_tag  = tag
  aes.auth_data = ''

  plaintext = aes.update(ciphertext) + aes.final
  data      = JSON.parse(plaintext)

  actual_data = data.fetch('data')     { nil }
  actual_meta = data.fetch('meta')     { nil }
  actual_incl = data.fetch('included') { nil }

  expected_json = JSON.parse(body)
  expected_data = expected_json.fetch('data')     { nil }
  expected_meta = expected_json.fetch('meta')     { nil }
  expected_incl = expected_json.fetch('included') { nil }

  if expected_data.present?
    expect(actual_data).to deep_include expected_data
  end

  if expected_meta.present?
    expect(actual_meta).to deep_include expected_meta
  end

  if expected_incl.present?
    expect(actual_incl).to deep_include *expected_incl
  else
    expect(actual_incl).to be_nil
  end
end

Then /^the JSON response should be a "([^"]+)" with a certificate signed using "([^"]+)"$/ do |resource_type, expected_alg|
  account = @account
  req     = last_request
  res     = last_response
  json    = JSON.parse(last_response.body)
  cert    = json.dig('data', 'attributes', 'certificate')
  type    = json.dig('data', 'type')

  expect(type).to eq resource_type.pluralize

  type = type.delete_suffix('-files')
             .singularize

  expect(cert).to start_with "-----BEGIN #{type.upcase} FILE-----\n"
  expect(cert).to end_with "-----END #{type.upcase} FILE-----\n"

  payload = cert.delete_prefix("-----BEGIN #{type.upcase} FILE-----\n")
                .delete_suffix("-----END #{type.upcase} FILE-----\n")

  attrs = JSON.parse(Base64.decode64(payload))
  alg   = attrs.fetch('alg')
  enc   = attrs.fetch('enc')
  sig   = attrs.fetch('sig')

  expect(alg).to end_with expected_alg

  signing_prefix = type.downcase
  signing_data   = "#{signing_prefix}/#{enc}"
  sig_bytes      = Base64.strict_decode64(sig)
  ok             = false

  case alg
  when /ed25519/
    ed25519 = Ed25519::VerifyKey.new [account.ed25519_public_key].pack('H*')
    ok      = ed25519.verify(sig_bytes, signing_data) rescue false
  when /rsa-pss-sha256/
    rsa = OpenSSL::PKey::RSA.new(account.public_key)
    ok  = rsa.verify_pss(OpenSSL::Digest::SHA256.new, sig_bytes, signing_data, salt_length: :auto, mgf1_hash: 'SHA256') rescue false
  when /rsa-sha256/
    rsa = OpenSSL::PKey::RSA.new(account.public_key)
    ok  = rsa.verify(OpenSSL::Digest::SHA256.new, sig_bytes, signing_data) rescue false
  end

  expect(ok).to be true
end

Then /^the JSON response should be a "([^"]+)" with the following encoded certificate data:$/ do |resource_type, body|
  body = parse_placeholders(body, account: @account, bearer: @bearer, crypt: @crypt)

  req  = last_request
  res  = last_response
  json = JSON.parse(last_response.body)
  cert = json.dig('data', 'attributes', 'certificate')
  type = json.dig('data', 'type')

  expect(type).to eq resource_type.pluralize

  type = type.delete_suffix('-files')
             .singularize

  expect(cert).to start_with "-----BEGIN #{type.upcase} FILE-----\n"
  expect(cert).to end_with "-----END #{type.upcase} FILE-----\n"

  payload = cert.delete_prefix("-----BEGIN #{type.upcase} FILE-----\n")
                .delete_suffix("-----END #{type.upcase} FILE-----\n")

  attrs = JSON.parse(Base64.decode64(payload))
  enc   = attrs.fetch('enc')
  data  = JSON.parse(Base64.decode64(enc))

  actual_data = data.fetch('data')     { nil }
  actual_meta = data.fetch('meta')     { nil }
  actual_incl = data.fetch('included') { nil }

  expected_json = JSON.parse(body)
  expected_data = expected_json.fetch('data')     { nil }
  expected_meta = expected_json.fetch('meta')     { nil }
  expected_incl = expected_json.fetch('included') { nil }

  if expected_data.present?
    expect(actual_data).to deep_include expected_data
  end

  if expected_meta.present?
    expect(actual_meta).to deep_include expected_meta
  end

  if expected_incl.present?
    expect(actual_incl).to deep_include *expected_incl
  else
    expect(actual_incl).to be_nil
  end
end

Then /^the JSON response should be a "([^"]+)" with the following encrypted certificate data:$/ do |resource_type, body|
  body = parse_placeholders(body, account: @account, bearer: @bearer, crypt: @crypt)

  account = @account
  req     = last_request
  res     = last_response
  json    = JSON.parse(last_response.body)
  cert    = json.dig('data', 'attributes', 'certificate')
  type    = json.dig('data', 'type')

  expect(type).to eq resource_type.pluralize

  type = type.delete_suffix('-files')
             .singularize

  expect(cert).to start_with "-----BEGIN #{type.upcase} FILE-----\n"
  expect(cert).to end_with "-----END #{type.upcase} FILE-----\n"

  payload = cert.delete_prefix("-----BEGIN #{type.upcase} FILE-----\n")
                .delete_suffix("-----END #{type.upcase} FILE-----\n")

  attrs  = JSON.parse(Base64.decode64(payload))
  enc    = attrs.fetch('enc')
  secret =
    case type.downcase
    when 'license'
      license_id = json.dig('data', 'relationships', 'license', 'data', 'id')

      account.licenses.find(license_id).key
    when 'machine'
      license_id = json.dig('data', 'relationships', 'license', 'data', 'id')
      machine_id = json.dig('data', 'relationships', 'machine', 'data', 'id')

      account.licenses.find(license_id).key +
        account.machines.find(machine_id).fingerprint
    end

  aes = OpenSSL::Cipher::AES256.new(:GCM)
  aes.decrypt

  key         = OpenSSL::Digest::SHA256.digest(secret)
  ciphertext,
  iv,
  tag         = enc.split('.')
                   .map { Base64.strict_decode64(_1) }

  aes.key = key
  aes.iv  = iv

  aes.auth_tag  = tag
  aes.auth_data = ''

  plaintext = aes.update(ciphertext) + aes.final
  data      = JSON.parse(plaintext)

  actual_data = data.fetch('data')     { nil }
  actual_meta = data.fetch('meta')     { nil }
  actual_incl = data.fetch('included') { nil }

  expected_json = JSON.parse(body)
  expected_data = expected_json.fetch('data')     { nil }
  expected_meta = expected_json.fetch('meta')     { nil }
  expected_incl = expected_json.fetch('included') { nil }

  if expected_data.present?
    expect(actual_data).to deep_include expected_data
  end

  if expected_meta.present?
    expect(actual_meta).to deep_include expected_meta
  end

  if expected_incl.present?
    expect(actual_incl).to deep_include *expected_incl
  else
    expect(actual_incl).to be_nil
  end
end

Given /^the JSON data should be sorted by "([^"]+)"$/ do |key|
  data = JSON.parse(last_response.body)
             .fetch('data')

  expect(data).to eq data.sort_by { _1.dig(*key.split('.')) }
                         .reverse
end
