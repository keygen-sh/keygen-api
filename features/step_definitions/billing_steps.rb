# frozen_string_literal: true

World Rack::Test::Methods

Given /^the account "([^\"]*)" is (\w+)$/ do |id, state|
  account = FindByAliasService.call(Account, id:, aliases: :slug)

  # Set up a fake subscription
  customer = create :customer, :with_card
  plan = account.plan
  plan = create :plan if plan.nil?
  subscription = create :subscription, customer: customer.id, plan: plan.plan_id

  account.update plan: plan
  account.billing.update(
    customer_id: customer.id,
    subscription_id: subscription.id,
    subscription_status: subscription.status,
    subscription_period_start: Time.at(subscription.current_period_start),
    subscription_period_end: Time.at(subscription.current_period_end),
    state: state
  )

  case state.to_sym
  when :active
    account.billing.update subscription_status: "active"
  when :trialing
    account.billing.update subscription_status: "trialing"
  when :paused
    account.billing.update subscription_id: nil
  when :canceled
    account.billing.update subscription_id: nil, subscription_period_start: nil, subscription_period_end: nil
  end
end

Given /^the account does have a card on file$/ do
  @billing.update card_brand: 'Visa', card_last4: '4242', card_expiry: 2.years.from_now
end

Given /^the account does not have a card on file$/ do
  @billing.update card_brand: nil, card_last4: nil, card_expiry: nil
end

Given /^the account "([^\"]*)" does have a card on file$/ do |id|
  account = FindByAliasService.call(Account, id:, aliases: :slug)

  account.billing.update card_brand: 'Visa', card_last4: '4242', card_expiry: 2.years.from_now
end

Given /^the account "([^\"]*)" does not have a card on file$/ do |id|
  account = FindByAliasService.call(Account, id:, aliases: :slug)

  account.billing.update card_brand: nil, card_last4: nil, card_expiry: nil
end

Given /^I have a valid payment token$/ do
  # Default
end

Given /^I have a valid coupon$/ do
  StripeHelper.create_coupon id: "COUPON_CODE"
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

Given /^we are receiving Stripe webhook events$/ do
  @events = []

  allow_any_instance_of(Billings::CreateSubscriptionService).to receive(:call) { @events << :subscription_created }
  allow_any_instance_of(Billings::DeleteSubscriptionService).to receive(:call) { @events << :subscription_deleted }
  allow_any_instance_of(Billings::UpdateSubscriptionService).to receive(:call) { @events << :subscription_updated }
  allow_any_instance_of(Billings::CreateCustomerService).to receive(:call) { @events << :customer_created }
  allow_any_instance_of(Billings::DeleteCustomerService).to receive(:call) { @events << :customer_deleted }
  allow_any_instance_of(Billings::UpdateCustomerService).to receive(:call) { @events << :customer_updated }
end

Given /^there is an incoming "([^\"]*)" event(?: with an? "([^\"]*)" status)?$/ do |type, status|
  @plan = create :plan
  @customer = create :customer
  @subscription = create :subscription, customer: @customer.id, plan: @plan.plan_id

  @account = create :account
  @billing = create :billing, {
    account: @account,
    customer_id: @customer.id,
    subscription_id: @subscription.id,
    subscription_status: @subscription.status,
    subscription_period_start: Time.at(@subscription.current_period_start),
    subscription_period_end: Time.at(@subscription.current_period_end),
  }

  @event = StripeMock.mock_webhook_event type, Proc.new {
    overrides =
      case type
      when /^customer.(\w+)$/
        {
          subscription: @subscription.id,
          id: @customer.id
        }
      when /^customer\.subscription\.(\w)+$/
        {
          customer: @customer.id,
          id: @subscription.id
        }
      else
        {
          subscription: @subscription.id,
          customer: @customer.id
        }
      end

    overrides.merge! status: status if status

    overrides
  }.call
end

Given /^there is an incoming "([^\"]*)" event with a new plan$/ do |event_type|
  @plan         = create :plan
  @customer     = create :customer
  @subscription = create :subscription, customer: @customer.id, plan: @plan.plan_id

  @account = create :account
  @billing = create :billing, {
    account: @account,
    customer_id: @customer.id,
    subscription_id: @subscription.id,
    subscription_status: @subscription.status,
    subscription_period_start: Time.at(@subscription.current_period_start),
    subscription_period_end: Time.at(@subscription.current_period_end),
  }

  @event = StripeMock.mock_webhook_event event_type, Proc.new {
    {
      customer: @customer.id,
      id: @subscription.id,
      items: [{
        plan: { id: @plan.plan_id }
      }],
    }
  }.call
end

Given /^the account doesn't have a subscription$/ do
  @billing.update(
    subscription_id: nil,
    subscription_status: nil,
    subscription_period_start: nil,
    subscription_period_end: nil
  )
end

Given /^the account is in a "([^\"]*)" state$/ do |state|
  @billing.update state: state
end

When /^the event is received at "\/stripe"$/ do
  post "//api.keygen.sh/#{@api_version}/stripe", { id: @event.id }.to_json
end

Then /^a new "([^\"]*)" should be (\w+)$/ do |type, event|
  expect(@events).to include "#{type.underscore}_#{event}".to_sym
end

Then /^the account should have a subscription$/ do
  expect(@billing.reload.subscription_id).to eq @subscription.id
end

Then /^the account should not have a subscription$/ do
  expect(@billing.reload.subscription_status).to_not eq @subscription.status
  expect(@billing.reload.subscription_id).to eq @subscription.id
end

Then /^the account should be in a "([^\"]*)" state$/ do |state|
  expect(@billing.reload.state).to eq state
end

Then /^the account should have a(?:n? (?:new|updated)) plan$/ do
  expect(@account.reload.plan.plan_id).to eq @event.data.object.items.first.plan.id
end

Then /^the account should have a(?:n? (?:new|updated)) card$/ do
  expect(@billing.reload.card.expiry).to eq DateTime.new(@event.data.object.exp_year, @event.data.object.exp_month)
  expect(@billing.reload.card.last4).to eq @event.data.object.last4
  expect(@billing.reload.card.brand).to eq @event.data.object.brand
end

Then /^the account should contain (\d+) "(paid|unpaid)" receipts?$/ do |count, status|
  expect(@billing.receipts.send(status).count).to be count.to_i
end

Then /^the account should be charged$/ do
  json = JSON.parse last_response.body

  expect(json["data"]["relationships"]["billing"]["data"]).to_not be_empty
end

Then /^the account should not be charged$/ do
  json = JSON.parse last_response.body

  expect(json["data"]["relationships"]["billing"]["data"]).to be_empty
end
