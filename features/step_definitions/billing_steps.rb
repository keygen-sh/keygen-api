World Rack::Test::Methods

Given /^the account "([^\"]*)" is (\w+)$/ do |name, state|
  account = Account.find_by name: name

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

Given /^we are receiving Stripe webhook events$/ do
  @events = []

  allow_any_instance_of(Billings::CreateSubscriptionService).to receive(:execute) { @events << :subscription_created }
  allow_any_instance_of(Billings::DeleteSubscriptionService).to receive(:execute) { @events << :subscription_deleted }
  allow_any_instance_of(Billings::UpdateSubscriptionService).to receive(:execute) { @events << :subscription_updated }
  allow_any_instance_of(Billings::CreateCustomerService).to receive(:execute) { @events << :customer_created }
  allow_any_instance_of(Billings::DeleteCustomerService).to receive(:execute) { @events << :customer_deleted }
  allow_any_instance_of(Billings::UpdateCustomerService).to receive(:execute) { @events << :customer_updated }
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
    subscription_period_start: @subscription.current_period_start,
    subscription_period_end: @subscription.current_period_end
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
  post "//api.keygen.sh/#{@api_version}/stripe", id: @event.id
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

Then /^the account should have a(?:n? (?:new|updated)) card$/ do
  expect(@billing.reload.card.expiry).to eq DateTime.new(@event.data.object.exp_year, @event.data.object.exp_month)
  expect(@billing.reload.card.last4).to eq @event.data.object.last4
  expect(@billing.reload.card.brand).to eq @event.data.object.brand
end

Then /^the account should receive an email$/ do
  expect(Sidekiq::Queues["mailers"]).to_not be_empty
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
