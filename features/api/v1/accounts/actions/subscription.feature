@api/v1
@mp
Feature: Account subscription actions
  Background:
    Given the following "accounts" exist:
      | Name    | Slug  |
      | Test 1  | test1 |
      | Test 2  | test2 |
    And I send and accept JSON

  Scenario: Endpoint should be accessible when account is disabled
    Given the account "test1" is canceled
    When I send a POST request to "/accounts/test1/actions/pause-subscription"
    Then the response status should not be "403"

  Scenario: Admin manages their subscription account
    Given the account "test1" is subscribed
    And I am an admin of account "test1"
    And the account "test1" has 1 "webhook-endpoint"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/actions/manage-subscription"
    Then the response status should be "200"
    And the response should contain the following headers:
      """
      { "Location": "https://billing.stripe.com/session/test_session_secret" }
      """
    And the response body should be meta with the following:
      """
      { "url": "https://billing.stripe.com/session/test_session_secret" }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 0 "request-log" jobs

  @ee
  Scenario: Isolated admin manages their subscription account
    Given the account "test1" has 1 isolated "admin"
    And I am the last admin of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/actions/manage-subscription?environment=isolated"
    Then the response status should be "403"
    And sidekiq should have 0 "request-log" jobs

  @ee
  Scenario: Shared admin manages their subscription account
    Given the account "test1" has 1 shared "admin"
    And I am the last admin of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/actions/manage-subscription?environment=shared"
    Then the response status should be "403"
    And sidekiq should have 0 "request-log" jobs

  Scenario: Developer attempts to manage their subscription account
    Given the current account is "test1"
    And the current account has 1 "developer"
    And I am a developer of account "test1"
    And the account "test1" has 1 "webhook-endpoint"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/actions/manage-subscription"
    Then the response status should be "403"

  Scenario: Sales attempts to manage their subscription account
    Given the current account is "test1"
    And the current account has 1 "sales-agent"
    And I am a sales agent of account "test1"
    And the account "test1" has 1 "webhook-endpoint"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/actions/manage-subscription"
    Then the response status should be "403"

  Scenario: Support attempts to manage their subscription account
    Given the current account is "test1"
    And the current account has 1 "support-agent"
    And I am a support agent of account "test1"
    And the account "test1" has 1 "webhook-endpoint"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/actions/manage-subscription"
    Then the response status should be "403"

   Scenario: Read-only attempts to manage their subscription account
    Given the current account is "test1"
    And the current account has 1 "read-only"
    And I am a read only of account "test1"
    And the account "test1" has 1 "webhook-endpoint"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/actions/manage-subscription"
    Then the response status should be "403"

  @ee
  Scenario: Environment attempts to manage their subscription account
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And I am an environment of account "test1"
    And the account "test1" has 1 "webhook-endpoint"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    When I send a POST request to "/accounts/test1/actions/manage-subscription"
    Then the response status should be "403"

  Scenario: Product attempts to manage their subscription account
    Given the current account is "test1"
    And the current account has 1 "product"
    And I am a product of account "test1"
    And the account "test1" has 1 "webhook-endpoint"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/actions/manage-subscription"
    Then the response status should be "403"

  Scenario: Admin pauses their subscribed account
    Given the account "test1" is subscribed
    And I am an admin of account "test1"
    And the account "test1" has 1 "webhook-endpoint"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/actions/pause-subscription"
    Then the response status should be "204"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 0 "request-log" jobs

  Scenario: Admin resumes their paused account
    Given the account "test1" is paused
    And I am an admin of account "test1"
    And the account "test1" has 1 "webhook-endpoint"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/actions/resume-subscription"
    Then the response status should be "204"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 0 "request-log" jobs

  Scenario: Admin cancels their subscribed account
    Given the account "test1" is subscribed
    And I am an admin of account "test1"
    And the account "test1" has 1 "webhook-endpoint"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/actions/cancel-subscription"
    Then the response status should be "204"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 0 "request-log" jobs

  Scenario: Admin renews their canceling account
    Given the account "test1" is canceling
    And I am an admin of account "test1"
    And the account "test1" has 1 "webhook-endpoint"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/actions/renew-subscription"
    Then the response status should be "204"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 0 "request-log" jobs

  Scenario: Admin renews their canceled account
    Given the account "test1" is canceled
    And I am an admin of account "test1"
    And the account "test1" has 1 "webhook-endpoint"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/actions/renew-subscription"
    Then the response status should be "422"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 0 "request-log" jobs

  Scenario: Admin attempts to pause their paused account
    Given the account "test1" is paused
    And I am an admin of account "test1"
    And the account "test1" has 1 "webhook-endpoint"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/actions/pause-subscription"
    Then the response status should be "422"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 0 "request-log" jobs

  Scenario: Admin attempts to resume their subscribed account
    Given the account "test1" is subscribed
    And I am an admin of account "test1"
    And the account "test1" has 1 "webhook-endpoint"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/actions/resume-subscription"
    Then the response status should be "422"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 0 "request-log" jobs

  Scenario: Admin attempts to cancel their canceled account
    Given the account "test1" is canceled
    And I am an admin of account "test1"
    And the account "test1" has 1 "webhook-endpoint"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/actions/cancel-subscription"
    Then the response status should be "422"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 0 "request-log" jobs

  Scenario: Admin attempts to renews their subscribed account
    Given the account "test1" is subscribed
    And I am an admin of account "test1"
    And the account "test1" has 1 "webhook-endpoint"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/actions/renew-subscription"
    Then the response status should be "422"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 0 "request-log" jobs

  Scenario: Admin attempts to pause another account
    Given the account "test1" is subscribed
    And I am an admin of account "test2"
    And the account "test1" has 1 "webhook-endpoint"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/actions/pause-subscription"
    Then the response status should be "401"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 0 "request-log" jobs

  Scenario: Admin attempts to resume another account
    Given the account "test1" is paused
    And I am an admin of account "test2"
    And the account "test1" has 1 "webhook-endpoint"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/actions/resume-subscription"
    Then the response status should be "401"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 0 "request-log" jobs

  Scenario: Admin attempts to cancel another account
    Given the account "test1" is subscribed
    And I am an admin of account "test2"
    And the account "test1" has 1 "webhook-endpoint"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/actions/cancel-subscription"
    Then the response status should be "401"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 0 "request-log" jobs

  Scenario: Admin attempts to renew another account
    Given the account "test1" is canceled
    And I am an admin of account "test2"
    And the account "test1" has 1 "webhook-endpoint"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/actions/renew-subscription"
    Then the response status should be "401"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 0 "request-log" jobs
