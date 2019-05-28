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

Given /^there exists an(?:other)? account "([^\"]*)"$/ do |slug|
  create :account, slug: slug
end

Given /^the account "([^\"]*)" has the following attributes:$/ do |slug, body|
  parse_placeholders! body

  attributes = JSON.parse(body).deep_transform_keys! &:underscore
  Account.find(slug).update attributes
end

Given /^I have the following attributes:$/ do |body|
  parse_placeholders! body

  attributes = JSON.parse(body).deep_transform_keys! &:underscore
  @bearer.update attributes
end

Then /^the current token has the following attributes:$/ do |body|
  parse_placeholders! body

  attributes = JSON.parse(body).deep_transform_keys! &:underscore
  @token.update attributes
end

Given /^the current account is "([^\"]*)"$/ do |slug|
  @account = Account.find slug
end

Given /^there exists (\d+) "([^\"]*)"$/ do |count, resource|
  count.to_i.times { create(resource.singularize.underscore) }
end

Given /^the account "([^\"]*)" has exceeded its daily request limit$/ do |slug|
  account = Account.find slug

  account.daily_request_count = 1_000_000_000
end

Given /^the account "([^\"]*)" is on a free tier$/ do |slug|
  account = Account.find slug

  account.plan.update! price: 0
end

Given /^the account "([^\"]*)" has (\d+) "([^\"]*)"$/ do |slug, count, resource|
  account = Account.find slug

  count.to_i.times do
    create resource.singularize.underscore, account: account
  end
end

Given /^the current account has (\d+) "([^\"]*)"$/ do |count, resource|
  count.to_i.times do
    create resource.singularize.underscore, account: @account
  end
end

Given /^the current account has (\d+) userless "([^\"]*)"$/ do |count, resource|
  count.to_i.times do
    create resource.singularize.underscore, :userless, account: @account
  end
end

Given /^the current account has (\d+) legacy encrypted "([^\"]*)"$/ do |count, resource|
  count.to_i.times do
    @crypt << create(resource.singularize.underscore, :legacy_encrypt, account: @account)
  end
end

Given /^the current account has (\d+) "([^\"]*)" using "([^\"]*)"$/ do |count, resource, scheme|
  count.to_i.times do
    case scheme
    when 'RSA_2048_PKCS1_ENCRYPT'
      @crypt << create(resource.singularize.underscore, :rsa_2048_pkcs1_encrypt, account: @account, key: SecureRandom.hex)
    when 'RSA_2048_PKCS1_SIGN'
      @crypt << create(resource.singularize.underscore, :rsa_2048_pkcs1_sign, account: @account, key: SecureRandom.hex)
    when 'RSA_2048_PKCS1_PSS_SIGN'
      @crypt << create(resource.singularize.underscore, :rsa_2048_pkcs1_pss_sign, account: @account, key: SecureRandom.hex)
    when 'RSA_2048_JWT_RS256'
      @crypt << create(resource.singularize.underscore, :rsa_2048_jwt_rs256, account: @account, key: JSON.generate(key: SecureRandom.hex))
    end
  end
end

Given /^the current product has (\d+) "([^\"]*)"$/ do |count, resource|
  resource = resource.pluralize.underscore

  model =
    if resource == "users"
      @account.send(resource).roles :user
    else
      @account.send resource
    end

  model.limit(count.to_i).all.each_with_index do |r|
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
        r.send(ref.options[:through]).first&.product = @bearer
      when ref&.options[:through] && ref.options[:through].to_s.singularize == ref.options[:through].to_s
        r.send(ref.options[:through])&.product = @bearer
      end
    end

    r.save
  end
end

Given /^the current license has (\d+) "([^\"]*)"$/ do |count, resource|
  resource = resource.pluralize.underscore

  model =
    if resource == "users"
      @account.send(resource).roles :user
    else
      @account.send resource
    end

  model.limit(count.to_i).all.each_with_index do |r|
    ref = (r.class.reflect_on_association(:licenses) rescue false) ||
          (r.class.reflect_on_association(:license) rescue false)

    begin
      case
      when ref.name.to_s.pluralize == ref.name.to_s
        r.licenses << @bearer
      when ref.name.to_s.singularize == ref.name.to_s
        r.license = @bearer
      end
    rescue
      case
      when ref&.options[:through] && ref.options[:through].to_s.pluralize == ref.options[:through].to_s
        r.send(ref.options[:through]).first&.license = @bearer
      when ref&.options[:through] && ref.options[:through].to_s.singularize == ref.options[:through].to_s
        r.send(ref.options[:through])&.license = @bearer
      end
    end

    r.save
  end
end

Given /^the (first|second|third|fourth|fifth|sixth|seventh|eigth|ninth) product has (\d+) "([^\"]*)"$/ do |i, count, resource|
  resource = resource.pluralize.underscore
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

  product = @account.products.limit(numbers[i]).last

  model =
    if resource == "users"
      @account.send(resource).roles :user
    else
      @account.send resource
    end

  model.limit(count.to_i).all.each_with_index do |r|
    ref = (r.class.reflect_on_association(:products) rescue false) ||
          (r.class.reflect_on_association(:product) rescue false)

    begin
      case
      when ref.name.to_s.pluralize == ref.name.to_s
        r.products << product
      when ref.name.to_s.singularize == ref.name.to_s
        r.product = product
      end
    rescue
      case
      when ref&.options[:through] && ref.options[:through].to_s.pluralize == ref.options[:through].to_s
        r.send(ref.options[:through]).first&.product = product
      when ref&.options[:through] && ref.options[:through].to_s.singularize == ref.options[:through].to_s
        r.send(ref.options[:through])&.product = product
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
  @account.send(resource.pluralize.underscore).update_all(
    JSON.parse(body).deep_transform_keys! &:underscore
  )
end

Given /^the first (\d+) "([^\"]*)" have the following attributes:$/ do |count, resource, body|
  parse_placeholders! body
  @account.send(resource.pluralize.underscore).limit(count).update_all(
    JSON.parse(body).deep_transform_keys! &:underscore
  )
end

Given /^(\d+) "([^\"]*)" (?:have|has) the following attributes:$/ do |count, resource, body|
  parse_placeholders! body
  @account.send(resource.pluralize.underscore).limit(count).update_all(
    JSON.parse(body).deep_transform_keys! &:underscore
  )
end

Given /^the (first|second|third|fourth|fifth|sixth|seventh|eigth|ninth) "([^\"]*)" has the following attributes:$/ do |i, resource, body|
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

  model = if resource.singularize == "plan"
            Plan.all
          else
            @account.send(resource.pluralize.underscore).all
          end

  m = model.send(:[], numbers[i])

  m.assign_attributes(
    JSON.parse(body).deep_transform_keys! &:underscore
  )

  m.save validate: false
end

Given /^the (first|second|third|fourth|fifth|sixth|seventh|eigth|ninth) "([^\"]*)" has the following metadata:$/ do |i, resource, body|
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

  model = if resource.singularize == "plan"
            Plan.all
          else
            @account.send(resource.pluralize.underscore).all
          end

  m = model.send(:[], numbers[i])

  m.assign_attributes(
    metadata: JSON.parse(body).deep_transform_keys!(&:underscore)
  )

  m.save validate: false
end

Given /^the (first|second|third|fourth|fifth|sixth|seventh|eigth|ninth) "([^\"]*)" of account "([^\"]*)" has the following attributes:$/ do |i, resource, slug, body|
  parse_placeholders! body

  account = Account.find slug
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

  m = account.send(resource.pluralize.underscore).all.send(:[], numbers[i])

  m.assign_attributes(
    JSON.parse(body).deep_transform_keys! &:underscore
  )

  m.save validate: false
end

Given /^the (first|second|third|fourth|fifth|sixth|seventh|eigth|ninth) "([^\"]*)" of account "([^\"]*)" has the following metadata:$/ do |i, resource, slug, body|
  parse_placeholders! body

  account = Account.find slug
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

  m = account.send(resource.pluralize.underscore).all.send(:[], numbers[i])

  m.assign_attributes(
    metadata: JSON.parse(body).deep_transform_keys!(&:underscore)
  )

  m.save validate: false
end

Then /^the current account should have (\d+) "([^\"]*)"$/ do |count, resource|
  user  = @account.admins.first
  token = TokenGeneratorService.new(
    account: @account,
    bearer: user
  ).execute

  case resource
  when /^admins?$/
    expect(@account.users.admins.count).to eq count.to_i
  when /^users?$/
    expect(@account.users.roles(:user).count).to eq count.to_i
  else
    expect(@account.send(resource.pluralize.underscore).count).to eq count.to_i
  end
end

Then /^the account "([^\"]*)" should have (\d+) "([^\"]*)"$/ do |slug, count, resource|
  account = Account.find slug

  user  = account.admins.first
  token = TokenGeneratorService.new(
    account: account,
    bearer: user
  ).execute

  case resource
  when /^admins?$/
    expect(account.users.admins.count).to eq count.to_i
  when /^users?$/
    expect(account.users.roles(:user).count).to eq count.to_i
  else
    expect(account.send(resource.pluralize.underscore).count).to eq count.to_i
  end
end

Then /^the account "([^\"]*)" should have the following attributes:$/ do |slug, body|
  parse_placeholders! body

  attributes = JSON.parse(body).deep_transform_keys! &:underscore
  account = Account.find(slug)

  expect(account.attributes).to include attributes
end

Then /^the current token should have the following attributes:$/ do |body|
  parse_placeholders! body

  attributes = JSON.parse(body).deep_transform_keys! &:underscore

  expect(@token.reload.attributes).to include attributes
end
