World Rack::Test::Methods

Given /^the following "([^\"]*)" exist:$/ do |resource, table|
  data = table.hashes.map { |h| h.deep_transform_keys! &:underscore }
  data.each { |attributes| create(resource.singularize.underscore, attributes) }
end

Given /^the following "([^\"]*)" exists:$/ do |resource, body|
  parse_placeholders! body

  attributes = JSON.parse(body).deep_transform_keys! &:underscore
  create resource.singularize.underscore, attributes
end

Given /^there exists an(?:other)? account "([^\"]*)"$/ do |subdomain|
  create :account, subdomain: subdomain
end

Given /^the account "([^\"]*)" has the following attributes:$/ do |subdomain, body|
  parse_placeholders! body

  attributes = JSON.parse(body).deep_transform_keys! &:underscore
  Account.find_by(subdomain: subdomain).update attributes
end

Given /^I have the following attributes:$/ do |body|
  parse_placeholders! body

  attributes = JSON.parse(body).deep_transform_keys! &:underscore
  @bearer.update attributes
end

Given /^I am on the subdomain "([^\"]*)"$/ do |subdomain|
  @account = Account.find_by subdomain: subdomain
end

Given /^there exists (\d+) "([^\"]*)"$/ do |count, resource|
  count.to_i.times { create(resource.singularize.underscore) }
end

Given /^the account "([^\"]*)" has (\d+) "([^\"]*)"$/ do |subdomain, count, resource|
  account = Account.find_by subdomain: subdomain

  count.to_i.times do
    create resource.singularize.underscore, account: account
  end
end

Given /^the current account has (\d+) "([^\"]*)"$/ do |count, resource|
  count.to_i.times do
    create resource.singularize.underscore, account: @account
  end
end

Given /^the current account has (\d+) encrypted "([^\"]*)"$/ do |count, resource|
  count.to_i.times do
    create resource.singularize.underscore, :encrypted, account: @account
  end
end

Given /^the current product has (\d+) "([^\"]*)"$/ do |count, resource|
  finders  = %w[first second third fourth fifth]
  resource = resource.pluralize.underscore

  model =
    if resource == "users"
      @account.send(resource).roles :user
    else
      @account.send resource
    end

  model.limit(count.to_i).all.each_with_index do |r, i|
    ref = (r.class.reflect_on_association(:products) rescue false) ||
          (r.class.reflect_on_association(:product) rescue false)

    begin
      case
      when ref.name.to_s.pluralize == ref.name.to_s
        r.products << @bearer
      when ref.name.to_s.singularize == ref.name.to_s
        r.product = @bearer
      end
    rescue
      case
      when ref&.options[:through] && ref.options[:through].to_s.pluralize == ref.options[:through].to_s
        r.send(ref.options[:through]).send(finders[i])&.product = @bearer
      when ref&.options[:through] && ref.options[:through].to_s.singularize == ref.options[:through].to_s
        r.send(ref.options[:through])&.product = @bearer
      end
    end

    r.save
  end
end

Given /^the current user has (\d+) "([^\"]*)"$/ do |count, resource|
  @account.send(resource.pluralize.underscore).limit(count.to_i).all.each do |r|
    r.user = @bearer
    r.save
  end
end

Given /^the (\w+) "([^\"]*)" is associated (?:with|to) the (\w+) "([^\"]*)"$/ do |i, a, j, b|
  numbers = {
    "first"   => 1,
    "second"  => 2,
    "third"   => 3,
    "fourth"  => 4,
    "fifth"   => 5,
    "sixth"   => 6,
    "seventh" => 7,
    "eigth"   => 8,
    "ninth"   => 9
  }

  resource = @account.send(a.pluralize.underscore).limit(numbers[i]).last
  association = @account.send(b.pluralize.underscore).limit(numbers[j]).last

  begin
    association.send(a.singularize.underscore) << resource
  rescue
    association.send(a.pluralize.underscore) << resource
  end
end

Given /^all "([^\"]*)" have the following attributes:$/ do |resource, body|
  parse_placeholders! body
  @account.send(resource.pluralize).update_all(
    JSON.parse(body).deep_transform_keys! &:underscore
  )
end

Given /^(\d+) "([^\"]*)" (?:have|has) the following attributes:$/ do |count, resource, body|
  parse_placeholders! body
  @account.send(resource.pluralize).limit(count.to_i).all.each do |r|
    r.update JSON.parse(body).deep_transform_keys! &:underscore
  end
end

Given /^the (\w+) "([^\"]*)" has the following attributes:$/ do |i, resource, body|
  parse_placeholders! body
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

  @account.send(resource.pluralize).all.send(:[], numbers[i]).update(
    JSON.parse(body).deep_transform_keys! &:underscore
  )
end

Then /^the current account should have (\d+) "([^\"]*)"$/ do |count, resource|
  if @account
    user  = @account.admins.first
    token = TokenGeneratorService.new(
      account: @account,
      bearer: user
    ).execute

    header "Authorization", "Bearer \"#{token.raw}\""

    get "//#{@account.subdomain}.keygen.sh/#{@api_version}/#{resource.pluralize.underscore.dasherize}"
  else
    get "//keygen.sh/#{@api_version}/#{resource.pluralize.underscore.dasherize}"
  end
  json = JSON.parse last_response.body

  expect(json["data"].select { |d| d["type"] == resource.pluralize }.length).to eq count.to_i
end

Then /^the account "([^\"]*)" should have (\d+) "([^\"]*)"$/ do |subdomain, count, resource|
  account = Account.find_by subdomain: subdomain

  user  = account.admins.first
  token = TokenGeneratorService.new(
    account: account,
    bearer: user
  ).execute

  header "Authorization", "Bearer \"#{token.raw}\""

  case resource
  when /^admins?$/
    expect(account.users.admins.count).to eq count.to_i
  else
    get "//#{account.subdomain}.keygen.sh/#{@api_version}/#{resource.pluralize.underscore.dasherize}"

    json = JSON.parse last_response.body

    expect(json["data"].select { |d| d["type"] == resource.pluralize }.length).to eq count.to_i
  end
end
