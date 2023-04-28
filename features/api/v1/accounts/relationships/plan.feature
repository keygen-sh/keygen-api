@api/v1
@mp
Feature: Account plan relationship
  Background:
    Given the following "accounts" exist:
      | Name    | Slug  |
      | Test 1  | test1 |
      | Test 2  | test2 |
    And I send and accept JSON

  Scenario: Endpoint should be accessible when account is disabled
    Given the account "test1" is canceled
    When I send a GET request to "/accounts/test1/plan"
    Then the response status should not be "403"

  # Retrieve
  Scenario: Admin retrieves the plan for their account
    Given the account "test1" is subscribed
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/plan"
    Then the response status should be "200"
    And the response body should be a "plan"
    And sidekiq should have 0 "request-log" jobs

  @ee
  Scenario: Isolated admin retrieves the plan for their account
    Given the account "test1" has 1 isolated "admin"
    And I am the last admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/plan?environment=isolated"
    Then the response status should be "200"
    And sidekiq should have 0 "request-log" jobs

  @ee
  Scenario: Shared admin retrieves the plan for their account
    Given the account "test1" has 1 shared "admin"
    And I am the last admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/plan?environment=shared"
    Then the response status should be "200"
    And sidekiq should have 0 "request-log" jobs

  Scenario: Developer attempts to retrieve the plan for their account
    Given the current account is "test1"
    And the current account has 1 "developer"
    And I am a developer of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/plan"
    Then the response status should be "200"

  Scenario: Sales attempts to retrieve the plan for their account
    Given the current account is "test1"
    And the current account has 1 "sales-agent"
    And I am a sales agent of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/plan"
    Then the response status should be "200"

  Scenario: Support attempts to retrieve the plan for their account
    Given the current account is "test1"
    And the current account has 1 "support-agent"
    And I am a support agent of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/plan"
    Then the response status should be "200"

  Scenario: Read-only attempts to retrieve the plan for their account
    Given the current account is "test1"
    And the current account has 1 "read-only"
    And I am a read only of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/plan"
    Then the response status should be "200"

  @ce
  Scenario: Environment attempts to retrieve the plan for their account (isolated)
    Given the account "test1" is subscribed
    And the account "test1" has 1 isolated "environment"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    When I send a GET request to "/accounts/test1/plan"
    Then the response status should be "400"
    And sidekiq should have 0 "request-log" jobs

  @ee
  Scenario: Environment attempts to retrieve the plan for their account (isolated)
    Given the account "test1" is subscribed
    And the account "test1" has 1 isolated "environment"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    When I send a GET request to "/accounts/test1/plan"
    Then the response status should be "403"
    And sidekiq should have 0 "request-log" jobs

  @ee
  Scenario: Environment attempts to retrieve the plan for their account (shared)
    Given the account "test1" is subscribed
    And the account "test1" has 1 shared "environment"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
    When I send a GET request to "/accounts/test1/plan"
    Then the response status should be "403"
    And sidekiq should have 0 "request-log" jobs

  @ee
  Scenario: Environment attempts to retrieve the plan for their account (global)
    Given the account "test1" is subscribed
    And the account "test1" has 1 shared "environment"
    And I am an environment of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/plan"
    Then the response status should be "401"
    And sidekiq should have 0 "request-log" jobs

  Scenario: Product attempts to retrieve the plan for their account
    Given the account "test1" is subscribed
    And the account "test1" has 1 "product"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/plan"
    Then the response status should be "403"
    And sidekiq should have 0 "request-log" jobs

  Scenario: Admin attempts to retrieve the plan for another account
    Given the account "test1" is subscribed
    And I am an admin of account "test2"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/plan"
    Then the response status should be "401"
    And sidekiq should have 0 "request-log" jobs

  # Update
  Scenario: Admin changes subscribed account to a new plan
    Given the account "test1" is subscribed
    And there exists 3 "plans"
    And I am an admin of account "test1"
    And the account "test1" has 1 "webhook-endpoint"
    And I use an authentication token
    When I send a PUT request to "/accounts/test1/plan" with the following:
      """
      {
        "data": {
          "type": "plans",
          "id": "$plans[1]"
        }
      }
      """
    Then the response status should be "200"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 0 "request-log" jobs

  Scenario: Admin changes trialing account to a new plan
    Given the account "test1" is trialing
    And there exists 3 "plans"
    And I am an admin of account "test1"
    And the account "test1" has 1 "webhook-endpoint"
    And I use an authentication token
    When I send a PUT request to "/accounts/test1/plan" with the following:
      """
      {
        "data": {
          "type": "plans",
          "id": "$plans[1]"
        }
      }
      """
    Then the response status should be "200"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 0 "request-log" jobs

  Scenario: Admin changes pending account to a new plan
    Given the account "test1" is pending
    And there exists 3 "plans"
    And I am an admin of account "test1"
    And the account "test1" has 1 "webhook-endpoint"
    And I use an authentication token
    When I send a PUT request to "/accounts/test1/plan" with the following:
      """
      {
        "data": {
          "type": "plans",
          "id": "$plans[1]"
        }
      }
      """
    Then the response status should be "200"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 0 "request-log" jobs

  Scenario: Admin changes paused account to a new plan
    Given the account "test1" is paused
    And there exists 3 "plans"
    And I am an admin of account "test1"
    And the account "test1" has 1 "webhook-endpoint"
    And I use an authentication token
    When I send a PUT request to "/accounts/test1/plan" with the following:
      """
      {
        "data": {
          "type": "plans",
          "id": "$plans[1]"
        }
      }
      """
    Then the response status should be "422"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 0 "request-log" jobs

  Scenario: Admin changes canceled account to a new plan
    Given the account "test1" is canceled
    And there exists 3 "plans"
    And I am an admin of account "test1"
    And the account "test1" has 1 "webhook-endpoint"
    And I use an authentication token
    When I send a PUT request to "/accounts/test1/plan" with the following:
      """
      {
        "data": {
          "type": "plans",
          "id": "$plans[1]"
        }
      }
      """
    Then the response status should be "200"
    And sidekiq should have 1 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 0 "request-log" jobs

  Scenario: Admin attempts to change to an invalid plan
    Given the account "test1" is subscribed
    And there exists 3 "plans"
    And I am an admin of account "test1"
    And the account "test1" has 1 "webhook-endpoint"
    And I use an authentication token
    When I send a PUT request to "/accounts/test1/plan" with the following:
      """
      {
        "data": {
          "type": "plans",
          "id": "invalid"
        }
      }
      """
    Then the response status should be "404"
    And the first error should have the following properties:
      """
      {
        "title": "Not found",
        "detail": "The requested plan 'invalid' was not found",
        "code": "NOT_FOUND"
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 0 "request-log" jobs

  @ee
  Scenario: Isolated admin updates the plan for their account
    Given the account "test1" is subscribed
    And there exists 3 "plans"
    And the account "test1" has 1 isolated "admin"
    And I am the last admin of account "test1"
    And I use an authentication token
    When I send a PUT request to "/accounts/test1/plan?environment=isolated" with the following:
      """
      {
        "data": {
          "type": "plans",
          "id": "$plans[1]"
        }
      }
      """
    Then the response status should be "403"
    And sidekiq should have 0 "request-log" jobs

  @ee
  Scenario: Shared admin updates the plan for their account
    Given the account "test1" is subscribed
    And there exists 3 "plans"
    And the account "test1" has 1 shared "admin"
    And I am the last admin of account "test1"
    And I use an authentication token
    When I send a PUT request to "/accounts/test1/plan?environment=shared" with the following:
      """
      {
        "data": {
          "type": "plans",
          "id": "$plans[1]"
        }
      }
      """
    Then the response status should be "403"
    And sidekiq should have 0 "request-log" jobs

  Scenario: Admin attempts to change plan for another account
    Given the account "test1" is subscribed
    And there exists 3 "plans"
    And I am an admin of account "test2"
    And the account "test1" has 1 "webhook-endpoint"
    And I use an authentication token
    When I send a PUT request to "/accounts/test1/plan" with the following:
      """
      {
        "data": {
          "type": "plans",
          "id": "$plans[1]"
        }
      }
      """
    Then the response status should be "401"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 0 "request-log" jobs
