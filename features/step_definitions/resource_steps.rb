# frozen_string_literal: true

World Rack::Test::Methods

def stub_cryptography_keygens!
  def stubbed!; @stubbed = true end
  def stubbed?; !!@stubbed end

  return if stubbed?

  allow_any_instance_of(Account).to receive(:ecdsa_private_key) { "7a768f62a10b6d7a231662d25fee01e090731b6277a9aa68007b4e5b0a3f188a" }
  allow_any_instance_of(Account).to receive(:ecdsa_public_key) { "047c256ba49442bc24e881256e7bb5f4b4088b7af85196f46df9c98e5305ed8a9f57f0af6dc016df6fe694abb40e23f506cce95928e61eef71463cec9028077879" }
  allow_any_instance_of(Account).to receive(:dsa_private_key) { "-----BEGIN DSA PRIVATE KEY-----\nMIIDVwIBAAKCAQEAiN4Z4uyGQ4SqPFUvagdKQn4fdmkS4kIlRU/mXeoF9VCouMt4\nncLOaHvLFHdg1AnGF+TF4icQgQPI36yQVw4WykzlDvVpdYg7LRq17YwRqKLFyUR/\n0Ty3t5ADQotd0kDqpZdllKPyfboXoIf1pTfErVj5jOocqTJV5Sxz6qu9wVuU/gv9\n7/Dlcxq6xiMTGwRrP0WZZJG4G0vQlki7MSnSrxOT8eARewbcww7FerGRqlKYPR7R\n38pZDlC5YPyF2YvXNk8gD8/IYrMnjOTewnEo7Es8Egvwuy/FvpJBDg7ZEUxofkWb\nbsPu4H0L72lBclvmFXZUgKkAjquNQrPG3fodMQIhANHlWtd1jNOdsLE4/QTNZ6Vz\nBQ4291OY51xgq62mXItpAoIBAQCAtqCe/QRNXa22d6/FNoL1XPixwT2/gG2cAq97\nbmogveGvd/vuqHZiZfZ/vrKk29zvia67YcK04JwgilkAhUUQf5FXDEbCW3gpfUxD\nBeLgRHkv3sWjeZfL67gZbNv867B4mX4jDS3F9pKou20RSUXzQ1js3XYNFV0rDvPR\ncUlNGM1+phG06M3T3CcAGv7XC+WvV1uXAK4snpfm2b3AAS1bPiOrjDyjwjYNIkkP\n7EJjjcXLxVfzACRGHZQjYc/bgZPUv2suxjzQ8Eiw3ONYZCatbkzK1eNLadivTjvU\nT9tN9M6hgRBYmHcweTwTT0Pt8g1zepxBRMU9WYj87FVoUg+FAoIBABqrc4yDZeDJ\n2FyPjkAJNRfD8uFqVMtbotxgBAY0+3mH1yFX/vyHxk+NEGOIMt9wiVKtW2b2GZvO\n8nctR8sXuHrZtP2M2rjex1VgpdyzR7s/YSBUcQARw+qFLc6nsZozJh4gLUhwpdLZ\nkWiVuGS2H7g5+Y1e5F8Y38ew3zP7gA9I4uCg94y+oD5gE9tkSMwwIcRb6wCd0ei2\nLg0N2pBDn4CgYLYwaDqT83CagBnT7JcE/tHMxTpRnIDLwQunJkilmb2meevDlBWA\nhU3KAtLuxMNIom8ENcETkJGz5NcYtjhyfzpInB+qOBJOt17p2UKzVBodslXQssU0\nq8AUPNGP4UwCIQCyB5NiBHhMZiMwNhpOOwTDeR83iAIZ+hsgh+wvZ0uzzA==\n-----END DSA PRIVATE KEY-----\n" }
  allow_any_instance_of(Account).to receive(:dsa_public_key) { "-----BEGIN PUBLIC KEY-----\nMIIDRzCCAjoGByqGSM44BAEwggItAoIBAQCI3hni7IZDhKo8VS9qB0pCfh92aRLi\nQiVFT+Zd6gX1UKi4y3idws5oe8sUd2DUCcYX5MXiJxCBA8jfrJBXDhbKTOUO9Wl1\niDstGrXtjBGoosXJRH/RPLe3kANCi13SQOqll2WUo/J9uhegh/WlN8StWPmM6hyp\nMlXlLHPqq73BW5T+C/3v8OVzGrrGIxMbBGs/RZlkkbgbS9CWSLsxKdKvE5Px4BF7\nBtzDDsV6sZGqUpg9HtHfylkOULlg/IXZi9c2TyAPz8hisyeM5N7CcSjsSzwSC/C7\nL8W+kkEODtkRTGh+RZtuw+7gfQvvaUFyW+YVdlSAqQCOq41Cs8bd+h0xAiEA0eVa\n13WM052wsTj9BM1npXMFDjb3U5jnXGCrraZci2kCggEBAIC2oJ79BE1drbZ3r8U2\ngvVc+LHBPb+AbZwCr3tuaiC94a93++6odmJl9n++sqTb3O+JrrthwrTgnCCKWQCF\nRRB/kVcMRsJbeCl9TEMF4uBEeS/exaN5l8vruBls2/zrsHiZfiMNLcX2kqi7bRFJ\nRfNDWOzddg0VXSsO89FxSU0YzX6mEbTozdPcJwAa/tcL5a9XW5cAriyel+bZvcAB\nLVs+I6uMPKPCNg0iSQ/sQmONxcvFV/MAJEYdlCNhz9uBk9S/ay7GPNDwSLDc41hk\nJq1uTMrV40tp2K9OO9RP2030zqGBEFiYdzB5PBNPQ+3yDXN6nEFExT1ZiPzsVWhS\nD4UDggEFAAKCAQAaq3OMg2Xgydhcj45ACTUXw/LhalTLW6LcYAQGNPt5h9chV/78\nh8ZPjRBjiDLfcIlSrVtm9hmbzvJ3LUfLF7h62bT9jNq43sdVYKXcs0e7P2EgVHEA\nEcPqhS3Op7GaMyYeIC1IcKXS2ZFolbhkth+4OfmNXuRfGN/HsN8z+4APSOLgoPeM\nvqA+YBPbZEjMMCHEW+sAndHoti4NDdqQQ5+AoGC2MGg6k/NwmoAZ0+yXBP7RzMU6\nUZyAy8ELpyZIpZm9pnnrw5QVgIVNygLS7sTDSKJvBDXBE5CRs+TXGLY4cn86SJwf\nqjgSTrde6dlCs1QaHbJV0LLFNKvAFDzRj+FM\n-----END PUBLIC KEY-----\n" }
  allow_any_instance_of(Account).to receive(:rsa_private_key) { "-----BEGIN RSA PRIVATE KEY-----\nMIIEowIBAAKCAQEAzPAseDYupK78ZUaSbGw7YyUCCeKo/1XqTACOcmTTHHGgeHac\nLK2j9UrbTlhW5h8Vyo0iUEHrY1Kgf4wwiGgFh0Yc+oDWDhq1bIertI03AE420Lbp\nUf6OTioX+nY0EInxXF3J7aAdx/R/nYgRJrLZ9ATWaQVSgf3vtxCtCwUeKxKZI41G\nA/9KHTcCmd3BryAQ1piYPr+qrEGf2NDJgr3WvVrMtnjeoordAaCTyYKtfm56WGXe\nXr43dfdejBuIkI5kqSzwVyoxhnjE/Rj6xks8ffH+dkAPNwm0IpxXJerybjmPWyv7\niyXEUN8CKG+6430D7NoYHp/c991ZHQBUs59gvwIDAQABAoIBAHb03ks04CQ1cknz\nCeEnfd1RyPol+ASmQSa2l/isr6HuDsB90K9aZzZlqiCyxFY1Kvf0rjs52EFB3+nJ\nXQ6AmtznhMCfciCjvjVuFuvpoEhsHgNOeOZgRQf4BQ0b+aKz/0anJiPpcf/z2vN8\n3L/CxyKOgEpbjYXo+XEgm+EuqlFDI3UZqhqFBTTf550QazjOihpItAMzf5yHP20Q\n8lA8PzYyYdkKqxdnaOt1IwhF+yFw2exZYPdHoWzmE/fI6RhQ5UyD9pidzBuW4xdH\nZQbWnsXPK7ZzNqN3Y1TkHl1TLPOKA0Ge5X/lcyCKB4v8zCVPUHOrVGDrsrHEc08P\nxCi52PkCgYEA5914ulPHrBN/h/G2nA45R1SE6QgFKPGQk8HaplV788aN+X73JNv5\nL8vSlhUJsUuGwuRkJkslxy/cA8do/39hSKESx2Tuu8EUeinCID26l1p4eczFoqps\nT7h4ggRsrJbN78bndG7ZkNQJPK2fEmZ/hp8XT9cJhgy2YwfUwydtLA0CgYEA4kUt\ne+7jlj7tQH5H/7ZpLhwckMNYr9Ojm8qCy+t40TAxVMBuGDfWhldMIjyzDU8wj9dr\nuKaejQ83jWqFlt/qbb1NFrLL7QKJajDlujI9hh55mG+jUa/bgfShuJnlMXPpCz+K\njhO5edT/jE4br3PgEAdnkbwVIJ8E+6vpjMQt8PsCgYAAoh85Sw9JjggUI/netT88\nzaNLS6VP9lDxxl7Fg4hCIzGyE8GzDRLCKalalZYgMNeeYqdPX3cr8xqDvCCySfPH\nEgGOH91zD9TxfHm2QtTmou2fT4repd6D3TofCMoPMp4/YGizbbYUai/YRZUgpL0G\nbhrPMgQppJE+9f+DxPDMZQKBgQCOG3RdicNV8V+ASc9eQmn8k5s9L/LbOsheZ+mN\nuO3AM8xHtjNu8mLBLMKcHhM2IK4XKOx2o+6gGRaCsowEHc1V7rYjs1dwG0/CacNe\nFX+eZDVqD3M7Mn9iNwn6rmzLikiqz9VtNeYfJi75J3Ur1FK8vmnFlaKPQlAW3/lm\ndy+DUQKBgEkNkmfafNVzCUZhgB5NDF1HNOqlPM0R9UrDraarG4pH7tVsl6lkEIc9\nujJSB6CauUNGVSx5zhiGXKLTYoQRTEWmdbBR0NK9EaK4icCTR+0cFS/jBpS4rJW8\n6hlMaiHG6DNtYdVbgtVqVC3EAXWrjfAPqBwoHP4CWq/vYfLK/53I\n-----END RSA PRIVATE KEY-----\n" }
  allow_any_instance_of(Account).to receive(:rsa_public_key) { "-----BEGIN PUBLIC KEY-----\nMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAzPAseDYupK78ZUaSbGw7\nYyUCCeKo/1XqTACOcmTTHHGgeHacLK2j9UrbTlhW5h8Vyo0iUEHrY1Kgf4wwiGgF\nh0Yc+oDWDhq1bIertI03AE420LbpUf6OTioX+nY0EInxXF3J7aAdx/R/nYgRJrLZ\n9ATWaQVSgf3vtxCtCwUeKxKZI41GA/9KHTcCmd3BryAQ1piYPr+qrEGf2NDJgr3W\nvVrMtnjeoordAaCTyYKtfm56WGXeXr43dfdejBuIkI5kqSzwVyoxhnjE/Rj6xks8\nffH+dkAPNwm0IpxXJerybjmPWyv7iyXEUN8CKG+6430D7NoYHp/c991ZHQBUs59g\nvwIDAQAB\n-----END PUBLIC KEY-----\n" }
  allow_any_instance_of(Account).to receive(:generate_ecdsa_keys!) { true }
  allow_any_instance_of(Account).to receive(:generate_dsa_keys!) { true }
  allow_any_instance_of(Account).to receive(:generate_rsa_keys!) { true }

  # FIXME(ezekg) Caching breaks due to stubbing
  allow(Rails.cache).to receive(:fetch) { |&block| block.call }

  stubbed!
end

Given /^the following "([^\"]*)" exist:$/ do |resource, table|
  stub_cryptography_keygens!

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
    when Crypto.schemes.rsa_2048_pkcs1_encrypt
      @crypt << create(resource.singularize.underscore, :rsa_2048_pkcs1_encrypt, account: @account, key: SecureRandom.hex)
    when Crypto.schemes.rsa_2048_pkcs1_sign
      @crypt << create(resource.singularize.underscore, :rsa_2048_pkcs1_sign, account: @account, key: SecureRandom.hex)
    when Crypto.schemes.rsa_2048_pkcs1_pss_sign
      @crypt << create(resource.singularize.underscore, :rsa_2048_pkcs1_pss_sign, account: @account, key: SecureRandom.hex)
    when Crypto.schemes.rsa_2048_jwt_rs256
      @crypt << create(resource.singularize.underscore, :rsa_2048_jwt_rs256, account: @account, key: JSON.generate(key: SecureRandom.hex))
    when Crypto.schemes.dsa_2048_sign
      @crypt << create(resource.singularize.underscore, :dsa_2048_sign, account: @account, key: SecureRandom.hex)
    when Crypto.schemes.ecdsa_secp256k1_sign
      @crypt << create(resource.singularize.underscore, :ecdsa_secp256k1_sign, account: @account, key: SecureRandom.hex)
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
