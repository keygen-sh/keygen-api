World Rack::Test::Methods

# Matches:
# $resource[0].attribute (where 0 is an index)
# $resource.attribute (random resource)
# $current.attribute (current user)
def parse_placeholders(str)
  str.dup.scan /((?<!\\)\$([-\w]+)(?:\[(\w+)\])?(?:\.([-.\w]+))?)/ do |pattern, *matches|
    resource, index, attribute = matches

    attribute =
      case attribute&.underscore
      when nil
        :hashid
      when "hashid"
        :id
      else
        attribute.underscore
      end

    value =
      case resource.underscore
      when "current"
        @bearer.send attribute
      when "time"
        case attribute
        when /(\d+)\.(\w+)\.(\w+)/
          $1.to_i.send($2).send $3
        when /(\d+)\.(\w+)/
          $1.to_i.send $2
        when /now/, /current/
          Time.current
        end
      else
        if @account
          @account.send(resource.underscore)
            .all
            .sort
            .send(*(index.nil? ? [:sample] : [:[], index.to_i]))
            .send attribute
        else
          resource.singularize
            .underscore
            .classify
            .constantize
            .all
            .sort
            .send(*(index.nil? ? [:sample] : [:[], index.to_i]))
            .send attribute
        end
      end

    str.sub! pattern.to_s, value.to_s
  end
end

# Matches:
# resource/$current (current user or account)
# resource/$0 (where 0 is a resource ID)
def parse_path_placeholders(str)
  str.dup.scan /([-\w]+)\/((?<!\\)\$(\w+))/ do |resource, pattern, index|
    value =
      case index
      when "current"
        case resource
        when "users", "products"
          @bearer.hashid
        else
          instance_variable_get("@#{resource.singularize}").hashid
        end
      else
        if @account
          case resource.underscore
          when "billing"
            @account.send(resource.underscore).hashid
          else
            @account.send(resource.underscore)
              .all
              .sort
              .send(*(index.nil? ? [:sample] : [:[], index.to_i]))
              .hashid
          end
        else
          resource.singularize
            .underscore
            .classify
            .constantize
            .all
            .sort
            .send(:[], index.to_i)
            .hashid
        end
      end

    str.sub! pattern.to_s, value
  end
end

# def association_plurality(resource, association)
#   case resource.reflect_on_all_associations.select { |a| a.name.to_s.singularize == association.singularize }.first
#   when ActiveRecord::Reflection::BelongsToReflection
#     association.singularize
#   when ActiveRecord::Reflection::HasOneReflection
#     association.singularize
#   when ActiveRecord::Reflection::HasManyReflection
#     association.pluralize
#   end
# end

Before "@api/v1" do
  @api_version = "v1"
end

Before do
  @stripe_helper = StripeMock.create_test_helper

  Stripe.api_key = "stripe_key"
  StripeMock.start
end

After do |s|
  Sidekiq::Worker.clear_all
  StripeMock.stop

  # Tell Cucumber to quit if a scenario fails
  if s.failed?
    puts last_request.url, last_response.status, last_response.body
    Cucumber.wants_to_quit = true
  end
end

Given /^the following (\w+) exist:$/ do |resource, table|
  data = table.hashes.map { |h| h.deep_transform_keys! &:underscore }
  data.each { |d| create resource.singularize, d }
end

Given /^there exists an(?:other)? account "([^\"]*)"$/ do |subdomain|
  create :account, subdomain: subdomain
end

Given /^I am an? (user|admin|product) of account "([^\"]*)"$/ do |role, subdomain|
  account = Account.find_by subdomain: subdomain
  @bearer =
    case role
    when "admin", "user"
      account.users.roles(role).first
    when "product"
      account.products.first
    end
end

Given /^I send and accept HTML$/ do
  header "Content-Type", "text/html"
  header "Accept", "text/html"
end

Given /^I send and accept JSON$/ do
  header "Content-Type", "application/vnd.api+json"
  header "Accept", "application/vnd.api+json"
end

Given /^I send the following headers:$/ do |body|
  parse_placeholders body
  headers = JSON.parse body

  # Base64 encode basic credentials
  if headers.key? "Authorization"
    /Basic "([.@\w\d]+):(.+)"/ =~ headers["Authorization"]
    credentials = Base64.encode64 "#{$1}:#{$2}"
    headers["Authorization"] = "Basic \"#{credentials}\""
  end

  headers.each do |name, value|
    header name, value
  end
end

Given /^I use my authentication token$/ do
  @bearer.token.update account: @bearer.account # FIXME ???
  token = @bearer.token.generate!

  header "Authorization", "Bearer \"#{token}\""
end

Given /^the account "([^\"]*)" has valid billing details$/ do |subdomain|
  plan = @stripe_helper.create_plan id: "plan", amount: 1500
  customer = Stripe::Customer.create(
    email: "johnny@appleseed.com",
    source: @stripe_helper.generate_card_token
  )
  subscription = customer.subscriptions.create(
    plan: plan.id
  )

  Plan.first.update external_plan_id: plan.id
  Account.find_by(subdomain: subdomain).update plan: Plan.first
  Account.find_by(subdomain: subdomain).billing.update(
    external_customer_id: customer.id,
    external_subscription_id: subscription.id,
    external_subscription_status: "active"
  )
end

Given /^the account "([^\"]*)" has the following attributes:$/ do |subdomain, body|
  parse_placeholders body
  attributes = JSON.parse(body).deep_transform_keys! &:underscore
  Account.find_by(subdomain: subdomain).update attributes
end

Given /^I have the following attributes:$/ do |body|
  parse_placeholders body
  attributes = JSON.parse(body).deep_transform_keys! &:underscore
  @bearer.update attributes
end

Given /^I am on the subdomain "([^\"]*)"$/ do |subdomain|
  @account = Account.find_by subdomain: subdomain
end

Given /^there exists (\d+) "([^\"]*)"$/ do |count, resource|
  create_list resource.singularize, count.to_i
end

Given /^the account "([^\"]*)" is not (\w+)$/ do |subdomain, attribute|
  Account.find_by(subdomain: subdomain).update "#{attribute}": false
end

Given /^the account "([^\"]*)" is (\w+)$/ do |subdomain, attribute|
  Account.find_by(subdomain: subdomain).update "#{attribute}": true
end

Given /^the account "([^\"]*)" has (\d+) "([^\"]*)"$/ do |subdomain, count, resource|
  count.to_i.times {
    create resource.singularize.underscore, account_id: Account.find_by(subdomain: subdomain).id
  }
end

Given /^the current account has (\d+) "([^\"]*)"$/ do |count, resource|
  count.to_i.times {
    create resource.singularize.underscore, account_id: @account.id
  }
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
  parse_placeholders body
  @account.send(resource.pluralize).update_all(
    JSON.parse(body).deep_transform_keys! &:underscore
  )
end

Given /^(\d+) "([^\"]*)" (?:have|has) the following attributes:$/ do |count, resource, body|
  parse_placeholders body
  @account.send(resource.pluralize).limit(count.to_i).all.each do |r|
    r.update JSON.parse(body).deep_transform_keys! &:underscore
  end
end

Given /^I have a valid payment token/ do
end

Given /^I have a payment token with an? "([^\"]*)" error$/ do |error|
  StripeMock.prepare_card_error(
    case error
    when "incorrect number"     then :incorrect_number
    when "invalid number"       then :invalid_number
    when "invalid expiry month" then :invalid_expiry_month
    when "invalid expiry year"  then :invalid_expiry_year
    when "invalid cvc"          then :invalid_cvc
    when "expired card"         then :expired_card
    when "incorrect cvc"        then :incorrect_cvc
    when "card declined"        then :card_declined
    when "missing"              then :missing
    when "processing error"     then :processing_error
    end, :new_customer
  )
end

When /^I send a GET request to "([^\"]*)"$/ do |path|
  parse_path_placeholders path
  if @account
    get "//#{@account.subdomain}.keygin.io/#{@api_version}/#{path.sub(/^\//, '')}"
  else
    get "//keygin.io/#{@api_version}/#{path.sub(/^\//, '')}"
  end
end

When /^I send a POST request to "([^\"]*)"$/ do |path|
  parse_path_placeholders path
  if @account
    post "//#{@account.subdomain}.keygin.io/#{@api_version}/#{path.sub(/^\//, '')}"
  else
    post "//keygin.io/#{@api_version}/#{path.sub(/^\//, '')}"
  end
end

When /^I send a POST request to "([^\"]*)" with the following:$/ do |path, body|
  parse_path_placeholders path
  parse_placeholders body
  if @account
    post "//#{@account.subdomain}.keygin.io/#{@api_version}/#{path.sub(/^\//, '')}", body
  else
    post "//keygin.io/#{@api_version}/#{path.sub(/^\//, '')}", body
  end
end

When /^I send a (?:PUT|PATCH) request to "([^\"]*)" with the following:$/ do |path, body|
  parse_path_placeholders path
  parse_placeholders body
  if @account
    put "//#{@account.subdomain}.keygin.io/#{@api_version}/#{path.sub(/^\//, '')}", body
  else
    put "//keygin.io/#{@api_version}/#{path.sub(/^\//, '')}", body
  end
end

When /^I send a DELETE request to "([^\"]*)"$/ do |path|
  parse_path_placeholders path
  if @account
    delete "//#{@account.subdomain}.keygin.io/#{@api_version}/#{path.sub(/^\//, '')}"
  else
    delete "//keygin.io/#{@api_version}/#{path.sub(/^\//, '')}"
  end
end

Then /^the response status should be "([^\"]*)"$/ do |status|
  assert_equal status.to_i, last_response.status
end

Then /^the JSON response should be an array with (\d+) "([^\"]*)"$/ do |count, name|
  json = JSON.parse last_response.body
  assert_equal count.to_i, json["data"].select { |d| d["type"] == name.pluralize }.length
end

Then /^the JSON response should be an? "([^\"]*)"$/ do |name|
  json = JSON.parse last_response.body
  assert_equal name.pluralize, json["data"]["type"]
end

Then /^the JSON response should be an? "([^\"]*)" with (?:the )?(\w+) "([^\"]*)"$/ do |name, attribute, value|
  json = JSON.parse last_response.body
  assert_equal name.pluralize, json["data"]["type"]
  assert_equal value.to_s, json["data"]["attributes"][attribute].to_s
end

Then /^the JSON response should be an? "([^\"]*)" that is (\w+)$/ do |name, attribute|
  json = JSON.parse last_response.body
  assert_equal name.pluralize, json["data"]["type"]
  assert_equal true, json["data"]["attributes"][attribute]
end

Then /^the JSON response should be an? "([^\"]*)" that is not (\w+)$/ do |name, attribute|
  json = JSON.parse last_response.body
  assert_equal name.pluralize, json["data"]["type"]
  assert_equal false, json["data"]["attributes"][attribute]
end

Then /^the JSON response should be an? "([^\"]*)" with the following (\w+):$/ do |name, attribute, body|
  json = JSON.parse last_response.body
  assert_equal name.pluralize, json["data"]["type"]
  assert_equal JSON.parse(body), json["data"]["attributes"][attribute]
end

Then /^the JSON response should be meta with the following:$/ do |body|
  json = JSON.parse last_response.body
  assert_equal JSON.parse(body), json["meta"]
end

Then /^the JSON response should be an array of (\d+) errors?$/ do |count|
  json = JSON.parse last_response.body
  assert_equal count.to_i, json["errors"].length
end

Then /^the current account should have (\d+) "([^\"]*)"$/ do |count, resource|
  if @account
    user = @account.users.roles(:admin).first
    user.token.update account: @account # FIXME ???

    token = user.token.generate!
    header "Authorization", "Bearer \"#{token}\""

    get "//#{@account.subdomain}.keygin.io/#{@api_version}/#{resource.pluralize.underscore.dasherize}"
  else
    get "//keygin.io/#{@api_version}/#{resource.pluralize.underscore.dasherize}"
  end
  json = JSON.parse last_response.body
  assert_equal count.to_i, json["data"].select { |d| d["type"] == resource.pluralize }.length
end

Then /^the account "([^\"]*)" should have (\d+) "([^\"]*)"$/ do |subdomain, count, resource|
  account = Account.find_by subdomain: subdomain

  user = account.users.roles(:admin).first
  user.token.update account: account # FIXME ???

  token = user.token.generate!
  header "Authorization", "Bearer \"#{token}\""

  case resource
  when /^admins?$/
    assert_equal count.to_i, account.users.admins.count
  else
    get "//#{account.subdomain}.keygin.io/#{@api_version}/#{resource.pluralize.underscore.dasherize}"

    json = JSON.parse last_response.body
    assert_equal count.to_i, json["data"].select { |d| d["type"] == resource.pluralize }.length
  end
end

Then /^sidekiq should have (\d+) "([^\"]*)" jobs?$/ do |count, resource|
  worker = "#{resource.singularize.underscore}_worker".classify.constantize
  assert_equal count.to_i, worker.jobs.size
end

Then /^the account should be charged$/ do
  json = JSON.parse last_response.body
  assert !json["data"]["relationships"]["billing"]["data"].empty? rescue nil
end

Then /^the account should not be charged$/ do
  json = JSON.parse last_response.body
  assert json["data"]["relationships"]["billing"]["data"].empty? rescue nil
end
