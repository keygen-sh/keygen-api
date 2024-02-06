# frozen_string_literal: true

World Rack::Test::Methods

Given /^the following "([^\"]*)"(?: rows)? exist:$/ do |resource, table|
  data = table.hashes.map { |h| h.deep_transform_keys! &:underscore }
  data.each do |attributes|
    create(resource.singularize.underscore, attributes.transform_values(&:presence))
  end
end

Given /^the following "([^\"]*)" exists:$/ do |resource, body|
  body = parse_placeholders(body, account: @account, bearer: @bearer, crypt: @crypt)

  attributes = JSON.parse(body).deep_transform_keys! &:underscore
  create resource.singularize.underscore, attributes.transform_values(&:presence)
end

Given /^there exists an(?:other)? account "([^\"]*)"$/ do |slug|
  create :account, slug: slug
end

Given /^the account "([^\"]*)" has the following attributes:$/ do |id, body|
  body = parse_placeholders(body, account: @account, bearer: @bearer, crypt: @crypt)

  account = FindByAliasService.call(Account, id:, aliases: :slug)
  attributes = JSON.parse(body).deep_transform_keys! &:underscore

  account.update!(attributes)
end

Given /^I have the following attributes:$/ do |body|
  body = parse_placeholders(body, account: @account, bearer: @bearer, crypt: @crypt)

  attributes = JSON.parse(body).deep_transform_keys! &:underscore
  @bearer.update!(attributes)
end

Given /^I have a password reset token$/ do
  @crypt << @bearer.generate_password_reset_token
end

Given /^I have a password reset token that is expired$/ do
  @crypt << @bearer.generate_password_reset_token
  @bearer.update!(password_reset_sent_at: 3.days.ago)
end

Then /^the current token has the following attributes:$/ do |body|
  body = parse_placeholders(body, account: @account, bearer: @bearer, crypt: @crypt)

  attributes = JSON.parse(body).deep_transform_keys! &:underscore
  @token.update!(attributes)
end

Given /^the current account is "([^\"]*)"$/ do |id|
  @account = FindByAliasService.call(Account, id:, aliases: :slug)
end

Given /^the current environment is "([^\"]*)"$/ do |id|
  Current.environment = FindByAliasService.call(@account.environments, id:, aliases: :code)
end

Given /^there exists (\d+) "([^\"]*)"$/ do |count, resource|
  count.to_i.times { create(resource.singularize.underscore) }
end

Given /^the account "([^\"]*)" has exceeded its daily request limit$/ do |id|
  account = FindByAliasService.call(Account, id:, aliases: :slug)

  account.daily_request_count = 1_000_000_000
end

Given /^the account "([^\"]*)" is on a free tier$/ do |id|
  account = FindByAliasService.call(Account, id:, aliases: :slug)

  account.plan.update! price: 0
end

Given /^the account "([^\"]*)" has a max (\w+) limit of (\d+)$/ do |id, resource, limit|
  account = FindByAliasService.call(Account, id:, aliases: :slug)

  account.plan.update! "max_#{resource.pluralize.underscore}" => limit.to_i
end

Given /^the account "([^\"]*)" has (\d+) (?:([\w+]+) )?"([^\"]*)"$/ do |id, count, traits, resource|
  account = FindByAliasService.call(Account, id:, aliases: :slug)
  traits  = traits&.split('+')&.map(&:to_sym)

  count.to_i.times do
    create resource.singularize.underscore, *traits, account: account
  end
end

Given /^the account "([^\"]*)" has its billing uninitialized$/ do |id|
  account = FindByAliasService.call(Account, id:, aliases: :slug)

  account.billing&.delete
end

Given /^the current account has the following attributes:$/ do |body|
  body = parse_placeholders(body, account: @account, bearer: @bearer, crypt: @crypt)

  attributes = JSON.parse(body).deep_transform_keys! &:underscore

  @account.update!(attributes)
end

Given /^the current account has (\d+) (?:([\w+]+) )?"([^\"]*)"$/ do |count, traits, resource|
  traits = traits&.split('+')&.map(&:to_sym)

  count.to_i.times do
    create resource.singularize.underscore, *traits, account: @account
  end
end

Given /^the current account has (\d+) (?:([\w+]+) )?"([^\"]*)" with the following:$/ do |count, traits, resource, body|
  body = parse_placeholders(body, account: @account, bearer: @bearer, crypt: @crypt)

  attrs  = JSON.parse(body).deep_transform_keys!(&:underscore)
  traits = traits&.split('+')&.map(&:to_sym)

  count.to_i.times do
    create resource.singularize.underscore, *traits, **attrs, account: @account
  end
end

Given /^the current account has the following "([^\"]*)" rows:$/ do |resource, rows|
  hashes  = rows.hashes.map { |h| h.transform_keys { |k| k.underscore.to_sym } }
  factory = resource.singularize.underscore.to_sym

  hashes.each do |hash|
    hash.transform_values! { _1.presence }

    # FIXME(ezekg) Treating releases a bit differently for convenience
    case factory
    when :release
      codes = hash.delete(:entitlements)&.split(/,\s*/)
      if codes.present? && codes.any?
        entitlements = codes.map { |code| { entitlement: @account.entitlements.find_by!(code: code) } }

        hash[:constraints_attributes] = entitlements
      end

      hash[:channel_attributes]  = { key: hash.delete(:channel) }

      create(:release,
        account: @account,
        **hash,
      )
    when :artifact
      hash[:platform_attributes] = { key: hash.delete(:platform) }
      hash[:arch_attributes]     = { key: hash.delete(:arch)     }
      hash[:filetype_attributes] = { key: hash.delete(:filetype) }

      create(:artifact,
        account: @account,
        **hash,
      )
    when :package
      hash[:engine_attributes] = { key: hash.delete(:engine) }

      create(:package,
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

Given /^the current account has (\d+) (?:([\w+]+) )?"([^\"]*)" (?:with|for|in)(?: an)? existing "([^\"]*)"$/ do |count, traits, resource, association|
  count.to_i.times do
    associated_record = @account.send(association.pluralize.underscore).all.sample
    association_name  = association.singularize.underscore.to_sym
    traits            = traits&.split('+')&.map(&:to_sym)

    create resource.singularize.underscore, *traits, account: @account, association_name => associated_record
  end
end

Given /^the current account has (\d+) (?:([\w+]+) )?"([^\"]*)" (?:with|for|in) (?:all|each) "([^\"]*)"$/ do |count, traits, resource, association|
  associated_records =
      case association.underscore.pluralize
      when 'components'
        @account.machine_components
      when 'processes'
        @account.machine_processes
      when 'artifacts'
        @account.release_artifacts
      when 'packages'
        @account.release_packages
      when 'engines'
        @account.release_engines
      else
        @account.send(association.pluralize.underscore)
      end

  traits = traits&.split('+')&.map(&:to_sym)

  if associated_records.respond_to?(:for_environment)
    associated_records = case traits
                         in [*, :isolated, *]
                           environment = @account.environments.find_by_code!(:isolated)

                           associated_records.for_environment(environment)
                         in [*, :shared, *]
                           environment = @account.environments.find_by_code!(:shared)

                           associated_records.for_environment(environment)
                         in [*, :global, *]
                           associated_records.for_environment(nil)
                         else
                           associated_records
                         end
  end

  association_name =
    case resource.singularize
    when 'token'
      :bearer
    else
      association.singularize.underscore.to_sym
    end

  associated_records.each do |record|
    count.to_i.times do
      create resource.singularize.underscore, *traits, account: @account, association_name => record
    end
  end
end

Given /^the current account has (\d+) (?:([\w+]+) )?"([^\"]*)" (?:with|for|in) (?:all|each) "([^\"]*)" with the following:$/ do |count, traits, resource, association, body|
  body   = parse_placeholders(body, account: @account, bearer: @bearer, crypt: @crypt)
  attrs  = JSON.parse(body).deep_transform_keys!(&:underscore)
  traits = traits&.split('+')&.map(&:to_sym)

  associated_records =
      case association.underscore.pluralize
      when 'components'
        @account.machine_components
      when 'processes'
        @account.machine_processes
      when 'artifacts'
        @account.release_artifacts
      when 'packages'
        @account.release_packages
      when 'engines'
        @account.release_engines
      else
        @account.send(association.pluralize.underscore)
      end

  if associated_records.respond_to?(:for_environment)
    associated_records = case traits
                         in [*, :isolated, *]
                           environment = @account.environments.find_by_code!(:isolated)

                           associated_records.for_environment(environment)
                         in [*, :shared, *]
                           environment = @account.environments.find_by_code!(:shared)

                           associated_records.for_environment(environment)
                         in [*, :global, *]
                           associated_records.for_environment(nil)
                         else
                           associated_records
                         end
  end

  association_name =
    case resource.singularize
    when 'token'
      :bearer
    else
      association.singularize.underscore.to_sym
    end

  associated_records.each do |record|
    count.to_i.times do
      create resource.singularize.underscore, *traits, **attrs, account: @account, association_name => record
    end
  end
end

Given /^the current account has (\d+) (?:([\w+]+) )?"([^\"]*)" (?:with|for|in) the (\w+) "([^\"]*)"$/ do |count, traits, resource, index, association|
  traits = traits&.split('+')&.map(&:to_sym)

  count.to_i.times do
    associated_records =
      case association.underscore.pluralize
      when 'components'
        @account.machine_components
      when 'processes'
        @account.machine_processes
      when 'artifacts'
        @account.release_artifacts
      when 'packages'
        @account.release_packages
      when 'engines'
        @account.release_engines
      else
        @account.send(association.pluralize.underscore)
      end

    association_name  =
      case resource.singularize
      when "token"
        :bearer
      else
        association.singularize.underscore.to_sym
      end

    create resource.singularize.underscore, *traits, account: @account, association_name => associated_records.send(index)
  end
end

Given /^the current account has (\d+) (?:([\w+]+) )?"([^\"]*)" (?:with|for|in) the (\w+) "([^\"]*)" with the following:$/ do |count, traits, resource, index, association, body|
  body   = parse_placeholders(body, account: @account, bearer: @bearer, crypt: @crypt)
  attrs  = JSON.parse(body).deep_transform_keys!(&:underscore)
  traits = traits&.split('+')&.map(&:to_sym)

  count.to_i.times do
    associated_record = @account.send(association.pluralize.underscore).send(index)
    association_name  =
      case resource.singularize
      when "token"
        :bearer
      else
        association.singularize.underscore.to_sym
      end

    create resource.singularize.underscore, *traits, **attrs, account: @account, association_name => associated_record
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

    r.save!
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

    r.save!
  end
end

Given /^the (first|second|third|fourth|fifth|sixth|seventh|eighth|ninth|last) product has (\d+) "([^\"]*)"$/ do |i, count, resource|
  resource = resource.pluralize.underscore
  numbers = {
    "first"   => 1,
    "second"  => 2,
    "third"   => 3,
    "fourth"  => 4,
    "fifth"   => 5,
    "sixth"   => 6,
    "seventh" => 7,
    "eighth"   => 8,
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

    r.save!
  end
end

Given /^the current user has (\d+) "([^\"]*)"$/ do |count, resource|
  @account.send(resource.pluralize.underscore).limit(count.to_i).all.each do |r|
    r.user = @bearer
    r.save!
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
    "eighth"   => 8,
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
  body = parse_placeholders(body, account: @account, bearer: @bearer, crypt: @crypt)

  attrs = JSON.parse(body).deep_transform_keys!(&:underscore)
  resources =
    case resource.underscore.pluralize
    when 'components'
      @account.machine_components
    when 'processes'
      @account.machine_processes
    when 'artifacts'
      @account.release_artifacts
    when 'engines'
      @account.release_engines
    else
      @account.send(resource.pluralize.underscore)
    end

  resources.each {
    _1.assign_attributes(attrs)
    _1.save!(validate: false)
  }
end

Given /^the first (\d+) "([^\"]*)" have the following attributes:$/ do |count, resource, body|
  body = parse_placeholders(body, account: @account, bearer: @bearer, crypt: @crypt)

  attrs     = JSON.parse(body).deep_transform_keys!(&:underscore)
  resources = @account.send(resource.pluralize.underscore)
                      .first(count)

  resources.each {
    _1.assign_attributes(attrs)
    _1.save!(validate: false)
  }
end

Given /^the last (\d+) "([^\"]*)" have the following attributes:$/ do |count, resource, body|
  body = parse_placeholders(body, account: @account, bearer: @bearer, crypt: @crypt)

  attrs     = JSON.parse(body).deep_transform_keys!(&:underscore)
  resources = @account.send(resource.pluralize.underscore)
                      .last(count)

  resources.each {
    _1.assign_attributes(attrs)
    _1.save!(validate: false)
  }
end

Given /^(\d+) "([^\"]*)" (?:have|has) the following attributes:$/ do |count, resource, body|
  body = parse_placeholders(body, account: @account, bearer: @bearer, crypt: @crypt)

  attrs = JSON.parse(body).deep_transform_keys!(&:underscore)
  resources = @account.send(resource.pluralize.underscore).limit(count)

  resources.each {
    _1.assign_attributes(attrs)
    _1.save!(validate: false)
  }
end

Given /^(?:the )?"([^\"]*)" (\d+)-(\d+) (?:have|has) the following attributes:$/ do |resource, start_index, end_index, body|
  body = parse_placeholders(body, account: @account, bearer: @bearer, crypt: @crypt)

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

  slice.each {
    _1.assign_attributes(attrs)
    _1.save!(validate: false)
  }
end

Given /^"([^\"]*)" (\d+) has the following attributes:$/ do |resource, index, body|
  body = parse_placeholders(body, account: @account, bearer: @bearer, crypt: @crypt)

  idx       = index.to_i
  resources = @account.send(resource.pluralize.underscore).limit(idx + 1)
  attrs     = JSON.parse(body).deep_transform_keys!(&:underscore)
  resource  = resources[idx]

  resource.update!(attrs)
end

Given /^the (first|second|third|fourth|fifth|sixth|seventh|eighth|ninth|last) "([^\"]*)" has the following attributes:$/ do |named_idx, resource, body|
  body = parse_placeholders(body, account: @account, bearer: @bearer, crypt: @crypt)

  attrs = JSON.parse(body).deep_transform_keys!(&:underscore)
  model =
    case resource.singularize
    when "plan"
      Plan.send(named_idx)
    when "component"
      @account.machine_components.send(named_idx)
    when "process"
      @account.machine_processes.send(named_idx)
    when "artifact"
      @account.release_artifacts.send(named_idx)
    when "package"
      @account.release_packages.send(named_idx)
    else
      @account.send(resource.pluralize.underscore).send(named_idx)
    end

  model.assign_attributes(attrs)

  model.save!(validate: false)
end

Given /^the (first|second|third|fourth|fifth|sixth|seventh|eighth|ninth|last) "([^\"]*)" has the following metadata:$/ do |named_idx, resource, body|
  body = parse_placeholders(body, account: @account, bearer: @bearer, crypt: @crypt)

  metadata = JSON.parse(body).deep_transform_keys!(&:underscore)
  model    =
    case resource.singularize
    when "plan"
      Plan.send(named_idx)
    when "component"
      @account.machine_components.send(named_idx)
    when "process"
      @account.machine_processes.send(named_idx)
    when "artifact"
      @account.release_artifacts.send(named_idx)
    when "package"
      @account.release_packages.send(named_idx)
    else
      @account.send(resource.pluralize.underscore).send(named_idx)
    end

  model.assign_attributes(metadata:)

  model.save!(validate: false)
end

Given /^the (first|second|third|fourth|fifth|last) "([^\"]*)" has the following permissions:$/ do |named_idx, resource, body|
  body = parse_placeholders(body, account: @account, bearer: @bearer, crypt: @crypt)

  permissions = JSON.parse(body)
  model       =
    case resource.singularize
    when "plan"
      Plan.send(named_idx)
    when "component"
      @account.machine_component.send(named_idx)
    when "process"
      @account.machine_processes.send(named_idx)
    when "artifact"
      @account.release_artifacts.send(named_idx)
    when "package"
      @account.release_packages.send(named_idx)
    else
      @account.send(resource.pluralize.underscore).send(named_idx)
    end

  model.update!(permissions:)
end

Given /^the (first|second|third|fourth|fifth|sixth|seventh|eighth|ninth|last) "([^\"]*)" (?:belongs to|is in) the (\w+) "([^\"]*)"$/ do |model_idx, model_name, assoc_idx, assoc_name|
  model =
    case model_name.singularize
    when 'component'
      @account.machine_components.send(model_idx)
    when 'process'
      @account.machine_processes.send(model_idx)
    when 'artifact'
      @account.release_artifacts.send(model_idx)
    when 'package'
      @account.release_packages.send(model_idx)
    when 'engine'
      @account.release_engine.send(model_idx)
    else
      @account.send(model_name.pluralize.underscore).send(model_idx)
    end

  associated_record =
    case assoc_name.singularize
    when 'component'
      @account.machine_components.send(assoc_idx)
    when 'process'
      @account.machine_processes.send(assoc_idx)
    when 'artifact'
      @account.release_artifacts.send(assoc_idx)
    when 'package'
      @account.release_packages.send(assoc_idx)
    when 'engine'
      @account.release_engines.send(model_idx)
    else
      @account.send(assoc_name.pluralize.underscore).send(assoc_idx)
    end

  association_name = assoc_name.singularize.underscore.to_sym

  model.assign_attributes(association_name => associated_record)
  model.save!(validate: false)
end

Given /^the (first|last) (\d+) "([^\"]*)" (?:belong to|is in) the (\w+) "([^\"]*)"$/ do |direction, count, model_name, assoc_idx, assoc_name|
  models =
    case model_name.singularize
    when 'component'
      @account.machine_components
    when 'process'
      @account.machine_processes
    when 'artifact'
      @account.release_artifacts
    when 'package'
      @account.release_packages
    when 'engine'
      @account.release_engines
    else
      @account.send(model_name.pluralize.underscore)
    end

  models = models.reorder(created_at: direction == 'first' ? :asc : :desc)
                 .limit(count)

  associated_record =
    case assoc_name.singularize
    when 'component'
      @account.machine_components.send(assoc_idx)
    when 'process'
      @account.machine_processes.send(assoc_idx)
    when 'artifact'
      @account.release_artifacts.send(assoc_idx)
    when 'package'
      @account.release_packages.send(assoc_idx)
    when 'engine'
      @account.release_engines.send(assoc_idx)
    else
      @account.send(assoc_name.pluralize.underscore).send(assoc_idx)
    end

  association_name  = assoc_name.singularize.underscore.to_sym

  models.each do |model|
    model.assign_attributes(association_name => associated_record)
    model.save!(validate: false)
  end
end

Given /^all "([^\"]*)" belong to the (\w+) "([^\"]*)"$/ do |model_name, assoc_idx, assoc_name|
  models =
    case model_name.singularize
    when 'component'
      @account.machine_components
    when 'process'
      @account.machine_processes
    when 'artifact'
      @account.release_artifacts
    when 'package'
      @account.release_package
    else
      @account.send(model_name.pluralize.underscore)
    end

  associated_record = @account.send(assoc_name.pluralize.underscore).send(assoc_idx)
  association_name  = assoc_name.singularize.underscore.to_sym

  models.each do |model|
    model.assign_attributes(association_name => associated_record)
    model.save!(validate: false)
  end
end

Given /^the (first|second|third|fourth|fifth) "license" has the following policy entitlements:$/ do |named_index, body|
  body = parse_placeholders(body, account: @account, bearer: @bearer, crypt: @crypt)

  license = @account.licenses.send(named_index)
  codes = JSON.parse(body)

  codes.each do |code|
    entitlement = create(:entitlement, account: @account, code: code)

    license.policy.policy_entitlements << create(:policy_entitlement, account: @account, policy: license.policy, entitlement: entitlement)
  end
end

Given /^the (first|second|third|fourth|fifth) "license" has the following license entitlements:$/ do |named_index, body|
  body = parse_placeholders(body, account: @account, bearer: @bearer, crypt: @crypt)

  license = @account.licenses.send(named_index)
  codes = JSON.parse(body)

  codes.each do |code|
    entitlement = create(:entitlement, account: @account, code: code)

    license.license_entitlements << create(:license_entitlement, account: @account, license: license, entitlement: entitlement)
  end
end

Given /^AWS S3 is (responding with a 200 status|responding with a 404 status|timing out)$/ do |scenario|
  res = case scenario
        when 'responding with a 200 status'
          []
        when 'responding with a 404 status'
          ['NotFound']
        when 'timing out'
          [Timeout::Error]
        when 'nil'
          next # bail without doing anything
        end

  Aws.config[:s3] = {
    stub_responses: {
      delete_object: res,
      head_object: res,
    }
  }
end

Given /^the (first|second|third|fourth|fifth|sixth|seventh|eighth|ninth|last) "([^\"]*)" of account "([^\"]*)" has the following attributes:$/ do |i, resource, id, body|
  body = parse_placeholders(body, account: @account, bearer: @bearer, crypt: @crypt)

  account = FindByAliasService.call(Account, id:, aliases: :slug)
  numbers = {
    "first"   => 0,
    "second"  => 1,
    "third"   => 2,
    "fourth"  => 3,
    "fifth"   => 4,
    "sixth"   => 5,
    "seventh" => 6,
    "eighth"   => 7,
    "ninth"   => 8
  }

  m = account.send(resource.pluralize.underscore).all.send(:[], numbers[i])

  m.assign_attributes(
    JSON.parse(body).deep_transform_keys! &:underscore
  )

  m.save!(validate: false)
end

Given /^the (first|second|third|fourth|fifth|sixth|seventh|eighth|ninth|last) "([^\"]*)" of account "([^\"]*)" has the following metadata:$/ do |i, resource, id, body|
  body = parse_placeholders(body, account: @account, bearer: @bearer, crypt: @crypt)

  account = FindByAliasService.call(Account, id:, aliases: :slug)
  numbers = {
    "first"   => 0,
    "second"  => 1,
    "third"   => 2,
    "fourth"  => 3,
    "fifth"   => 4,
    "sixth"   => 5,
    "seventh" => 6,
    "eighth"   => 7,
    "ninth"   => 8
  }

  m = account.send(resource.pluralize.underscore).all.send(:[], numbers[i])

  m.assign_attributes(
    metadata: JSON.parse(body).deep_transform_keys!(&:underscore)
  )

  m.save!(validate: false)
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
  when /^read[-_]?onlys?$/
    expect(@account.users.with_role(:read_only).count).to eq count.to_i
  when /^users?$/
    expect(@account.users.with_role(:user).count).to eq count.to_i
  when /^components?$/
    expect(@account.machine_components.count).to eq count.to_i
  when /^process(es)?$/
    expect(@account.machine_processes.count).to eq count.to_i
  when /^artifacts?$/
    expect(@account.release_artifacts.count).to eq count.to_i
  when /^filetypes?$/
    expect(@account.release_filetypes.count).to eq count.to_i
  when /^channels?$/
    expect(@account.release_channels.count).to eq count.to_i
  when /^platforms?$/
    expect(@account.release_platforms.count).to eq count.to_i
  when /^arch(es)?$/
    expect(@account.release_arches.count).to eq count.to_i
  when /^packages?$/
    expect(@account.release_packages.count).to eq count.to_i
  when /^engines?$/
    expect(@account.release_engines.count).to eq count.to_i
  else
    expect(@account.send(resource.pluralize.underscore).count).to eq count.to_i
  end
end

Then /^the current (?:bearer|user|license|product) should have (\d+) "([^\"]*)"$/ do |expected_count, resource|
  count = @bearer.send(resource.pluralize.underscore).count

  expect(count).to eq(expected_count.to_i)
end

Then /^the account "([^\"]*)" should have (\d+) "([^\"]*)"$/ do |id, count, resource|
  account = FindByAliasService.call(Account, id:, aliases: :slug)

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
  when /^read[-_]?onlys?$/
    expect(account.users.with_role(:read_only).count).to eq count.to_i
  when /^users?$/
    expect(account.users.with_role(:user).count).to eq count.to_i
  else
    expect(account.send(resource.pluralize.underscore).count).to eq count.to_i
  end
end

Then /^the account "([^\"]*)" should have a referral of "([^\"]*)"$/ do |account_id, referral_id|
  account = FindByAliasService.call(Account, id: account_id, aliases: :slug)
  billing = account.billing

  expect(billing.referral_id).to eq referral_id
end

Then /^the account "([^\"]*)" should not have a referral$/ do |account_id|
  account = FindByAliasService.call(Account, id: account_id, aliases: :slug)
  billing = account.billing

  expect(billing.referral_id).to be_nil
end

Then /^the account "([^\"]*)" should have the following attributes:$/ do |id, body|
  body = parse_placeholders(body, account: @account, bearer: @bearer, crypt: @crypt)

  account = FindByAliasService.call(Account, id:, aliases: :slug)
  attributes = JSON.parse(body).deep_transform_keys! &:underscore

  expect(account.attributes.as_json).to include attributes
end

Then /^the current token should have the following attributes:$/ do |body|
  body = parse_placeholders(body, account: @account, bearer: @bearer, crypt: @crypt)

  attributes = JSON.parse(body).deep_transform_keys! &:underscore

  expect(@token.reload.attributes.as_json).to include attributes
end

Then /^the (first|second|third|fourth|fifth|sixth|seventh|eighth|ninth|last) "license" should have a correct machine core count$/ do |word_index|
  numbers = {
    "first"   => 0,
    "second"  => 1,
    "third"   => 2,
    "fourth"  => 3,
    "fifth"   => 4,
    "sixth"   => 5,
    "seventh" => 6,
    "eighth"   => 7,
    "ninth"   => 8
  }
  index = numbers[word_index]
  model = @account.licenses.all[index]

  expect(model.machines_core_count).to eq model.machines.sum(:cores)
end

Then /^the (first|second|third|fourth|fifth|sixth|seventh|eighth|ninth|last) "license" should have an? (\w+) within seconds of "([^\"]+)"$/ do |index_in_words, attr_name, value|
  value = parse_placeholders(value, account: @account, bearer: @bearer, crypt: @crypt)

  license   = @account.licenses.send(index_in_words).reload # why?
  attribute = attr_name.underscore.to_sym
  time      = value&.to_time

  expect(license.send(attribute)).to be_within(3.seconds).of(time)
end

Then /^the (first|second|third|fourth|fifth|sixth|seventh|eighth|ninth|last) "license" should have an? (\w+) "([^\"]+)"$/ do |index_in_words, attr_name, value|
  value = parse_placeholders(value, account: @account, bearer: @bearer, crypt: @crypt)

  license   = @account.licenses.send(index_in_words).reload # why?
  attribute = attr_name.underscore.to_sym

  expect(license.send(attribute)).to eq value
end

Then /^the (first|second|third|fourth|fifth|sixth|seventh|eighth|ninth|last) "license" should have an? (\d+) (\w+) expiry$/ do |index_in_words, duration_count, duration_interval|
  license  = @account.licenses.send(index_in_words)
  duration = duration_count.to_i.send(duration_interval)
  expiry   = duration.from_now

  expect(license.expiry).to be_within(30.seconds).of(expiry)
end

Then /^the (first|second|third|fourth|fifth|sixth|seventh|eighth|ninth|last) "license" should not have an expiry$/ do |index_in_words|
  license = @account.licenses.send(index_in_words)

  expect(license.expiry).to be nil
end

Then /^the (\w+) "([^\"]*)" should have the (\w+) "([^\"]+)"$/ do |index_in_words, model_name, attribute_name, expected|
  model =
    case model_name.pluralize
    when 'components'
      @account.machine_components.send(index_in_words)
    when 'processes'
      @account.machine_processes.send(index_in_words)
    else
      @account.send(model_name.pluralize).send(index_in_words)
    end

  # FIXME(ezekg) Why do we need this?
  model.reload

  actual = model.send(attribute_name.underscore)

  # HACK(ezekg) We can't compare against symbols since expected is a string
  actual = actual.to_s if
    actual.is_a?(Symbol)

  expect(actual).to eq expected
end

Then /^the (?!account)(\w+) "([^\"]*)" should have (\w+) "([^\"]+)"$/ do |index_in_words, model_name, expected_count, association_name|
  model =
    case model_name.pluralize
    when 'components'
      @account.machine_components.send(index_in_words)
    when 'processes'
      @account.machine_processes.send(index_in_words)
    else
      @account.send(model_name.pluralize).send(index_in_words)
    end

  count = model.send(association_name.pluralize.underscore).count

  expect(count).to eq(expected_count.to_i)
end

Then /^the (first|second|third|fourth|fifth|last) "([^\"]*)" for account "([^\"]*)" should have the following attributes:$/ do |index_in_words, model_name, account_id, body|
  body = parse_placeholders(body, account: @account, bearer: @bearer, crypt: @crypt)

  account = FindByAliasService.call(Account, id: account_id, aliases: :slug)
  model   = account.send(model_name.pluralize).send(index_in_words)
  attrs   = JSON.parse(body).deep_transform_keys(&:underscore)

  expect(model.attributes).to include attrs
end

Then /^the (first|second|third|fourth|fifth|last) "([^\"]*)" should have the following attributes:$/ do |index_in_words, model_name, body|
  body  = parse_placeholders(body, account: @account, bearer: @bearer, crypt: @crypt)
  model =
    case model_name.pluralize
    when 'components'
      @account.machine_components.send(index_in_words)
    when 'processes'
      @account.machine_processes.send(index_in_words)
    when 'artifacts'
      @account.release_artifacts.send(index_in_words)
    when 'packages'
      @account.release_packages.send(index_in_words)
    when 'engines'
      @account.release_engines.send(index_in_words)
    else
      @account.send(model_name.pluralize).send(index_in_words)
    end

  # FIXME(ezekg) Why do we need this?
  model.reload

  attrs = JSON.parse(body).deep_transform_keys(&:underscore)

  expect(model.attributes.as_json).to include attrs
end

Then /^the (first|second|third|fourth|fifth|last) "([^\"]*)" should not have the following attributes:$/ do |word_index, model_name, body|
  body  = parse_placeholders(body, account: @account, bearer: @bearer, crypt: @crypt)
  model = @account.send(model_name.pluralize).send(word_index)
  attrs = JSON.parse(body).deep_transform_keys(&:underscore)

  expect(model.attributes.as_json).to_not include attrs
end

Then /^the (first|second|third|fourth|fifth|last) "([^\"]*)" should have the following relationships:$/ do |word_index, resource, body|
  body = parse_placeholders(body, account: @account, bearer: @bearer, crypt: @crypt)
  json = JSON.parse(last_response.body)
  data = json['data'].select { _1['type'] == resource.pluralize }
                     .send(word_index)

  expect(data['relationships']).to include JSON.parse(body)
end

Then /^the (first|second|third|fourth|fifth|last) "([^\"]*)" should have the following data:$/ do |word_index, resource, body|
  body = parse_placeholders(body, account: @account, bearer: @bearer, crypt: @crypt)
  json = JSON.parse(last_response.body)
  data = json['data'].select { _1['type'] == resource.pluralize }
                     .send(word_index)

  expect(data).to include JSON.parse(body)
end

Given /^the (first|second|third|fourth|fifth|last) "release" should (be|not be) yanked$/ do |named_index, named_scenario|
  release  = @account.releases.send(named_index)
  expected = named_scenario == 'be'

  expect(release.yanked_at.present?).to be expected
end
