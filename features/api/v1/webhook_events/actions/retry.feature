@api/v1
Feature: Retry webhook events

  Background:
    Given the following "accounts" exist:
      | Name    | Slug  |
      | Test 1  | test1 |
      | Test 2  | test2 |
    And I send and accept JSON

  Scenario: Endpoint should be inaccessible when account is disabled
    Given the account "test1" is canceled
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 3 "webhook-events"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/webhook-events/$0/actions/retry"
    Then the response status should be "403"

  Scenario: Admin retries a webhook event for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the first "webhook-endpoint" has the following attributes:
      """
      { "url": "https://example.com/webhooks" }
      """
    And the current account has 3 "webhook-events"
    And all "webhook-events" have the following attributes:
      """
      { "endpoint": "https://example.com/webhooks" }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/webhook-events/$0/actions/retry"
    Then the response status should be "201"
    And the response body should be a "webhook-event" with the following attributes:
      """
      {
        "payload": $!webhook-events[0].payload
      }
      """
    And the response body should be a "webhook-event" with the following meta:
      """
      {
        "idempotencyToken": "$webhook-events[0].idempotency_token"
      }
      """
    And the response should contain a valid signature header for "test1"
    And the current account should have 4 "webhook-events"

  Scenario: Admin retries a webhook event for their account that is no longer available
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 3 "webhook-events"
    And all "webhook-events" have the following attributes:
      """
      { "endpoint": "https://example.com/webhooks" }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/webhook-events/$0/actions/retry"
    Then the response status should be "422"
    And the response should contain a valid signature header for "test1"
    And the current account should have 3 "webhook-events"

  Scenario: Admin retries a webhook event for another account
    Given I am an admin of account "test2"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the first "webhook-endpoint" has the following attributes:
      """
      { "url": "https://example.com/webhooks" }
      """
    And the current account has 3 "webhook-events"
    And all "webhook-events" have the following attributes:
      """
      { "endpoint": "https://example.com/webhooks" }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/webhook-events/$0/actions/retry"
    Then the response status should be "401"
    And the response body should be an array of 1 error
    And the current account should have 3 "webhook-events"

  @ee
  Scenario: Environment retries an isolated webhook event for their account
    Given the current account is "test1"
    And the current account has 1 isolated "webhook-endpoint" with the following:
      """
      { "url": "https://isolated.example/webhooks" }
      """
    And the current account has 1 isolated "webhook-event" with the following:
      """
      { "endpoint": "https://isolated.example/webhooks" }
      """
    And the current account has 1 isolated "environment"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "keygen-environment": "isolated" }
      """
    When I send a POST request to "/accounts/test1/webhook-events/$0/actions/retry"
    Then the response status should be "201"

  Scenario: Product retries their webhook event for their account
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "webhook-endpoint" for the last "product"
    And the current account has 3 "webhook-events" for the last "webhook-endpoint"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/webhook-events/$0/actions/retry"
    Then the response status should be "403"
    And the response body should be an array of 1 error
    And the current account should have 3 "webhook-events"

  Scenario: Product retries a webhook event for their account
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 3 "webhook-events"
    And the current account has 1 "product"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/webhook-events/$0/actions/retry"
    Then the response status should be "404"

  Scenario: License retries a webhook event for their account
    Given the current account is "test1"
    And the current account has 1 "license"
    And I am a license of account "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 3 "webhook-events"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/webhook-events/$0/actions/retry"
    Then the response status should be "404"
    And the response body should be an array of 1 error
    And the current account should have 3 "webhook-events"

  Scenario: User retries a webhook event for their account
    Given the current account is "test1"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 3 "webhook-events"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/webhook-events/$0/actions/retry"
    Then the response status should be "404"
    And the response body should be an array of 1 error
    And the current account should have 3 "webhook-events"

  Scenario: Anonymous retries a webhook event for an account
    Given the current account is "test1"
    And the current account has 3 "webhook-events"
    When I send a POST request to "/accounts/test1/webhook-events/$0/actions/retry"
    Then the response status should be "401"
