# frozen_string_literal: true

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

Given /^the account "([^\"]*)" has the following attributes:$/ do |id, body|
  parse_placeholders! body

  account = FindByAliasService.call(scope: Account, identifier: id, aliases: :slug)
  attributes = JSON.parse(body).deep_transform_keys! &:underscore

  account.update attributes
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

Given /^the current account is "([^\"]*)"$/ do |id|
  @account = FindByAliasService.call(scope: Account, identifier: id, aliases: :slug)
end

Given /^there exists (\d+) "([^\"]*)"$/ do |count, resource|
  count.to_i.times { create(resource.singularize.underscore) }
end

Given /^the account "([^\"]*)" has exceeded its daily request limit$/ do |id|
  account = FindByAliasService.call(scope: Account, identifier: id, aliases: :slug)

  account.daily_request_count = 1_000_000_000
end

Given /^the account "([^\"]*)" is on a free tier$/ do |id|
  account = FindByAliasService.call(scope: Account, identifier: id, aliases: :slug)

  account.plan.update! price: 0
end

Given /^the account "([^\"]*)" has a max (\w+) limit of (\d+)$/ do |id, resource, limit|
  account = FindByAliasService.call(scope: Account, identifier: id, aliases: :slug)

  account.plan.update! "max_#{resource.pluralize.underscore}" => limit.to_i
end

Given /^the account "([^\"]*)" has (\d+) "([^\"]*)"$/ do |id, count, resource|
  account = FindByAliasService.call(scope: Account, identifier: id, aliases: :slug)

  count.to_i.times do
    create resource.singularize.underscore, account: account
  end
end

Given /^the current account has (\d+) "([^\"]*)"$/ do |count, resource|
  count.to_i.times do
    create resource.singularize.underscore, account: @account
  end
end

Given /^the current account has (\d+) "([^\"]*)" with the following:$/ do |count, resource, body|
  parse_placeholders! body

  attrs = JSON.parse(body).deep_transform_keys!(&:underscore)

  count.to_i.times do
    create resource.singularize.underscore, **attrs, account: @account
  end
end

Given /^the current account has the following "([^\"]*)" rows:$/ do |resource, rows|
  hashes  = rows.hashes.map { |h| h.transform_keys { |k| k.underscore.to_sym } }
  factory = resource.singularize.underscore.to_sym

  hashes.each do |hash|
    # FIXME(ezekg) Treating releases a bit differently for convenience
    case factory
    when :release
      codes = hash.delete(:entitlements)&.split(/,\s*/)
      if codes.present? && codes.any?
        entitlements = codes.map { |code| { entitlement: @account.entitlements.find_by!(code: code) } }

        hash[:constraints_attributes] = entitlements
      end

      hash[:platform_attributes] = { key: hash.delete(:platform) }
      hash[:filetype_attributes] = { key: hash.delete(:filetype) }
      hash[:channel_attributes]  = { key: hash.delete(:channel) }

      create(:release,
        account: @account,
        **hash,
      )
    else
      create(factory,
        account: @account,
        **hash,
      )
    end
  end
end

Given /^the current account has (\d+) "([^\"]*)" for(?: an)? existing "([^\"]*)"$/ do |count, resource, association|
  count.to_i.times do
    associated_record = @account.send(association.pluralize.underscore).all.sample
    association_name = association.singularize.underscore.to_sym

    create resource.singularize.underscore, account: @account, association_name => associated_record
  end
end

Given /^the current account has (\d+) "([^\"]*)" for the (\w+) "([^\"]*)"$/ do |count, resource, index, association|
  count.to_i.times do
    associated_record = @account.send(association.pluralize.underscore).send(index)
    association_name = association.singularize.underscore.to_sym

    create resource.singularize.underscore, account: @account, association_name => associated_record
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
    when 'RSA_2048_PKCS1_SIGN_V2'
      @crypt << create(resource.singularize.underscore, :rsa_2048_pkcs1_sign_v2, account: @account, key: SecureRandom.hex)
    when 'RSA_2048_PKCS1_PSS_SIGN_V2'
      @crypt << create(resource.singularize.underscore, :rsa_2048_pkcs1_pss_sign_v2, account: @account, key: SecureRandom.hex)
    when 'ED25519_SIGN'
      @crypt << create(resource.singularize.underscore, :ed25519_sign, account: @account, key: SecureRandom.hex)
    end
  end
end

Given /^the current product has (\d+) "([^\"]*)"$/ do |count, resource|
  resource = resource.pluralize.underscore

  model =
    if resource == "users"
      @account.send(resource).with_roles :user
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
      @account.send(resource).with_roles :user
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
      @account.send(resource).with_roles :user
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

  attrs = JSON.parse(body).deep_transform_keys!(&:underscore)
  resources = @account.send(resource.pluralize.underscore)

  resources.each { |r| r.update(attrs) }
end

Given /^the first (\d+) "([^\"]*)" have the following attributes:$/ do |count, resource, body|
  parse_placeholders! body

  attrs = JSON.parse(body).deep_transform_keys!(&:underscore)
  resources = @account.send(resource.pluralize.underscore).limit(count)

  resources.each { |r| r.update(attrs) }
end

Given /^(\d+) "([^\"]*)" (?:have|has) the following attributes:$/ do |count, resource, body|
  parse_placeholders! body

  attrs = JSON.parse(body).deep_transform_keys!(&:underscore)
  resources = @account.send(resource.pluralize.underscore).limit(count)

  resources.each { |r| r.update(attrs) }
end

Given /^(?:the )?"([^\"]*)" (\d+)-(\d+) (?:have|has) the following attributes:$/ do |resource, start_index, end_index, body|
  parse_placeholders! body

  start_idx = start_index.to_i
  end_idx   = end_index.to_i
  resources = @account.send(resource.pluralize.underscore).limit(start_idx + end_index)
  attrs     = JSON.parse(body).deep_transform_keys!(&:underscore)
  slice     =
    if start_idx.zero?
      # Arrays start at zero!
      resources[start_idx..end_idx]
    else
      # Oh no, he's retarded...
      resources[(start_idx - 1)..(end_idx - 1)]
    end

  slice.each { |r| r.update(attrs) }
end

Given /^"([^\"]*)" (\d+) has the following attributes:$/ do |resource, index, body|
  parse_placeholders! body

  idx       = index.to_i
  resources = @account.send(resource.pluralize.underscore).limit(idx + 1)
  attrs     = JSON.parse(body).deep_transform_keys!(&:underscore)
  resource  = resources[idx]

  resource.update(attrs)
end

Given /^the (first|second|third|fourth|fifth|sixth|seventh|eigth|ninth|last) "([^\"]*)" has the following attributes:$/ do |named_idx, resource, body|
  parse_placeholders! body

  attrs = JSON.parse(body).deep_transform_keys!(&:underscore)
  model =
    if resource.singularize == "plan"
      Plan.send(named_idx)
    else
      @account.send(resource.pluralize.underscore).send(named_idx)
    end

  model.assign_attributes(attrs)

  model.save validate: false
end

Given /^the (first|second|third|fourth|fifth|sixth|seventh|eigth|ninth) "([^\"]*)" has the following metadata:$/ do |named_idx, resource, body|
  parse_placeholders! body

  metadata = JSON.parse(body).deep_transform_keys!(&:underscore)
  model    =
    if resource.singularize == "plan"
      Plan.send(named_idx)
    else
      @account.send(resource.pluralize.underscore).send(named_idx)
    end

  model.assign_attributes(metadata: metadata)

  model.save validate: false
end

Given /^the (first|second|third|fourth|fifth) "license" has the following policy entitlements:$/ do |named_index, body|
  parse_placeholders! body

  license = @account.licenses.send(named_index)
  codes = JSON.parse(body)

  codes.each do |code|
    entitlement = create(:entitlement, account: @account, code: code)

    license.policy.policy_entitlements << create(:policy_entitlement, account: @account, policy: license.policy, entitlement: entitlement)
  end
end

Given /^the (first|second|third|fourth|fifth) "license" has the following license entitlements:$/ do |named_index, body|
  parse_placeholders! body

  license = @account.licenses.send(named_index)
  codes = JSON.parse(body)

  codes.each do |code|
    entitlement = create(:entitlement, account: @account, code: code)

    license.license_entitlements << create(:license_entitlement, account: @account, license: license, entitlement: entitlement)
  end
end

Given /^(?:the )?(\w+) "releases?" (?:has an?|have) artifacts? that (?:is|are) (uploaded|not uploaded|timing out)$/ do |named_index, named_scenario|
  res = case named_scenario
        when 'uploaded'
          []
        when 'not uploaded'
          ['NotFound']
        when 'timing out'
          [Timeout::Error]
        end

  Aws.config[:s3] = {
    stub_responses: {
      delete_object: [],
      head_object: res,
    }
  }

  if named_index == 'all'
    releases = @account.releases.all

    releases.each do |release|
      release.create_artifact!(key: release.filename, account: release.account, product: release.product)
    end
  else
    release = @account.releases.send(named_index)

    release.create_artifact!(key: release.filename, account: release.account, product: release.product)
  end
end

Given /^the (first|second|third|fourth|fifth|sixth|seventh|eigth|ninth) "([^\"]*)" of account "([^\"]*)" has the following attributes:$/ do |i, resource, id, body|
  parse_placeholders! body

  account = FindByAliasService.call(scope: Account, identifier: id, aliases: :slug)
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

Given /^the (first|second|third|fourth|fifth|sixth|seventh|eigth|ninth) "([^\"]*)" of account "([^\"]*)" has the following metadata:$/ do |i, resource, id, body|
  parse_placeholders! body

  account = FindByAliasService.call(scope: Account, identifier: id, aliases: :slug)
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
  case resource
  when /^administrators?$/
    expect(@account.users.administrators.count).to eq count.to_i
  when /^admins?$/
    expect(@account.users.admins.count).to eq count.to_i
  when /^developers?$/
    expect(@account.users.with_role(:developer).count).to eq count.to_i
  when /^sales-agents?$/
    expect(@account.users.with_role(:sales_agent).count).to eq count.to_i
  when /^support-agents?$/
    expect(@account.users.with_role(:support_agent).count).to eq count.to_i
  when /^users?$/
    expect(@account.users.with_role(:user).count).to eq count.to_i
  else
    expect(@account.send(resource.pluralize.underscore).count).to eq count.to_i
  end
end

Then /^the account "([^\"]*)" should have (\d+) "([^\"]*)"$/ do |id, count, resource|
  account = FindByAliasService.call(scope: Account, identifier: id, aliases: :slug)

  case resource
  when /^administrators?$/
    expect(account.users.administrators.count).to eq count.to_i
  when /^admins?$/
    expect(account.users.admins.count).to eq count.to_i
  when /^developers?$/
    expect(account.users.with_role(:developer).count).to eq count.to_i
  when /^sales-agents?$/
    expect(account.users.with_role(:sales_agent).count).to eq count.to_i
  when /^support-agents?$/
    expect(account.users.with_role(:support_agent).count).to eq count.to_i
  when /^users?$/
    expect(account.users.with_role(:user).count).to eq count.to_i
  else
    expect(account.send(resource.pluralize.underscore).count).to eq count.to_i
  end
end

Then /^the account "([^\"]*)" should have a referral of "([^\"]*)"$/ do |account_id, referral_id|
  account = FindByAliasService.call(scope: Account, identifier: account_id, aliases: :slug)
  billing = account.billing

  expect(billing.referral_id).to eq referral_id
end

Then /^the account "([^\"]*)" should not have a referral$/ do |account_id|
  account = FindByAliasService.call(scope: Account, identifier: account_id, aliases: :slug)
  billing = account.billing

  expect(billing.referral_id).to be_nil
end

Then /^the account "([^\"]*)" should have the following attributes:$/ do |id, body|
  parse_placeholders! body

  account = FindByAliasService.call(scope: Account, identifier: id, aliases: :slug)
  attributes = JSON.parse(body).deep_transform_keys! &:underscore

  expect(account.attributes).to include attributes
end

Then /^the current token should have the following attributes:$/ do |body|
  parse_placeholders! body

  attributes = JSON.parse(body).deep_transform_keys! &:underscore

  expect(@token.reload.attributes).to include attributes
end

Then /^the (first|second|third|fourth|fifth|sixth|seventh|eigth|ninth) "license" should have a correct machine core count$/ do |word_index|
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
  index = numbers[word_index]
  model = @account.licenses.all[index]

  expect(model.machines_core_count).to eq model.machines.sum(:cores)
end

Then /^the (first|second|third|fourth|fifth|sixth|seventh|eigth|ninth) "([^\"]*)" for account "([^\"]*)" should have the following attributes:$/ do |index_in_words, model_name, account_id, body|
  parse_placeholders!(body)

  account = FindByAliasService.call(scope: Account, identifier: account_id, aliases: :slug)
  model   = account.send(model_name.pluralize).send(index_in_words)
  attrs   = JSON.parse(body).deep_transform_keys(&:underscore)

  expect(model.attributes).to include attrs
end

Given /^the (\w+) "release" should (be|not be) yanked$/ do |named_index, named_scenario|
  release  = @account.releases.send(named_index)
  expected = named_scenario == 'be'

  expect(release.yanked_at.present?).to be expected
end
