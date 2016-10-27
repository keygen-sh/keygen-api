World Rack::Test::Methods

Given /^the account "([^\"]*)" is (\w+)$/ do |subdomain, state|
  account = Account.find_by subdomain: subdomain

  # Set up a fake subscription
  plan = create :plan
  customer = create :customer
  subscription = create :subscription, customer: customer.id, plan: plan.plan_id

  account.billing.update(
    customer_id: customer.id,
    subscription_id: subscription.id,
    subscription_status: subscription.status,
    subscription_period_start: subscription.current_period_start,
    subscription_period_end: subscription.current_period_end,
    state: state
  )

  case state.to_sym
  when :paused
    account.billing.update subscription_id: nil
  when :canceled
    account.billing.update subscription_id: nil, subscription_period_start: nil, subscription_period_end: nil
  end
end

Given /^I have a valid payment token/ do
end

Given /^I have a payment token with an? "([^\"]*)" error$/ do |error|
  StripeHelper.prepare_card_error(
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

Then /^the account should be charged$/ do
  json = JSON.parse last_response.body
  assert !json["data"]["relationships"]["billing"]["data"].empty? rescue nil
end

Then /^the account should not be charged$/ do
  json = JSON.parse last_response.body
  assert json["data"]["relationships"]["billing"]["data"].empty? rescue nil
end
