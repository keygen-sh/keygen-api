@api/v1
Feature: Process Stripe webhook events

  Background:
    Given we are receiving Stripe webhook events
    And I send and accept JSON

  Scenario: We receive a "customer.created" event
    Given there is an incoming "customer.created" event
    And the account doesn't have a subscription
    When the event is received at "/stripe"
    Then a new "subscription" should be created
    And the response status should be "202"

  Scenario: We receive a "customer.subscription.created" event
    Given there is an incoming "customer.subscription.created" event
    And the account doesn't have a subscription
    When the event is received at "/stripe"
    Then the account should have a subscription
    And the response status should be "202"

  Scenario: A pending account receives a "customer.subscription.created" event with an "active" status
    Given there is an incoming "customer.subscription.created" event with an "active" status
    And the account is in a "pending" state
    When the event is received at "/stripe"
    Then the account should be in a "subscribed" state
    And the response status should be "202"

  Scenario: A trialing account receives a "customer.subscription.created" event with an "active" status
    Given there is an incoming "customer.subscription.created" event with an "active" status
    And the account is in a "trialing" state
    When the event is received at "/stripe"
    Then the account should be in a "subscribed" state
    And the response status should be "202"

  Scenario: A pending account receives a "customer.subscription.updated" event with a "trialing" status
    Given there is an incoming "customer.subscription.updated" event with a "trialing" status
    And the account is in a "pending" state
    When the event is received at "/stripe"
    Then the account should be in a "trialing" state
    And the response status should be "202"

  Scenario: A paused account receives a "customer.subscription.updated" event with a "canceled" status
    Given there is an incoming "customer.subscription.updated" event with a "canceled" status
    And the account is in a "paused" state
    When the event is received at "/stripe"
    Then the account should be in a "paused" state
    And the response status should be "202"

  Scenario: A paused account receives a "customer.subscription.updated" event with an "active" status
    Given there is an incoming "customer.subscription.updated" event with an "active" status
    And the account is in a "paused" state
    When the event is received at "/stripe"
    Then the account should be in a "paused" state
    And the response status should be "202"

  Scenario: A subscribed account receives a "customer.subscription.updated" event with a "canceled" status
    Given there is an incoming "customer.subscription.updated" event with a "canceled" status
    And the account is in a "subscribed" state
    When the event is received at "/stripe"
    Then the account should be in a "canceled" state
    And the response status should be "202"

  Scenario: We receive a "customer.subscription.deleted" event when trialing
    Given there is an incoming "customer.subscription.deleted" event
    And the account is in a "trialing" state
    When the event is received at "/stripe"
    Then the account should not have a subscription
    And the account should be in a "canceled" state
    And the account should not receive a "subscription canceled" email
    And the response status should be "202"

  Scenario: We receive a "customer.subscription.deleted" event when paused
    Given there is an incoming "customer.subscription.deleted" event
    And the account is in a "paused" state
    When the event is received at "/stripe"
    Then the account should not have a subscription
    And the account should be in a "paused" state
    And the account should not receive a "subscription canceled" email
    And the response status should be "202"

  Scenario: We receive a "customer.subscription.deleted" event when subscribed
    Given there is an incoming "customer.subscription.deleted" event
    And the account is in a "subscribed" state
    When the event is received at "/stripe"
    Then the account should not have a subscription
    And the account should be in a "canceled" state
    And the account should receive a "subscription_canceled" email
    And the response status should be "202"

  Scenario: We receive a "customer.source.created" event
    Given there is an incoming "customer.source.created" event
    When the event is received at "/stripe"
    Then the account should have a new card
    And the response status should be "202"

  Scenario: We receive a "customer.source.updated" event
    Given there is an incoming "customer.source.updated" event
    When the event is received at "/stripe"
    Then the account should have an updated card
    And the response status should be "202"

  Scenario: We receive a "customer.subscription.trial_will_end" event
    Given there is an incoming "customer.subscription.trial_will_end" event
    When the event is received at "/stripe"
    Then the account should receive a "payment method missing" email
    And the response status should be "202"

  Scenario: We receive a "invoice.payment_succeeded" event
    Given there is an incoming "invoice.payment_succeeded" event
    When the event is received at "/stripe"
    Then the account should contain 1 "paid" receipt
    And the response status should be "202"

  Scenario: We receive a "invoice.payment_failed" event
    Given there is an incoming "invoice.payment_failed" event
    When the event is received at "/stripe"
    Then the account should contain 1 "unpaid" receipt
    And the response status should be "202"
