@api/v1
Feature: Account plan relationship

  Background:
    Given the following "accounts" exist:
      | Name    | Slug  |
      | Test 1  | test1 |
      | Test 2  | test2 |
    And I send and accept JSON

  Scenario: Admin retrieves the plan for their account
    Given the account "test1" is subscribed
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/plan"
    Then the response status should be "200"
    And the JSON response should be a "plan"

  Scenario: Product attempts to retrieve the plan for their account
    Given the account "test1" is subscribed
    And the account "test1" has 1 "product"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/plan"
    Then the response status should be "403"

  Scenario: Admin attempts to retrieve the plan for another account
    Given the account "test1" is subscribed
    And I am an admin of account "test2"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/plan"
    Then the response status should be "401"

  Scenario: Admin changes subscribed account to a new plan
    Given the account "test1" is subscribed
    And there exists 3 "plans"
    And I am an admin of account "test1"
    And the account "test1" has 1 "webhookEndpoint"
    And I use an authentication token
    When I send a PUT request to "/accounts/test1/plan" with the following:
      """
      {
        "data": {
          "type": "plans",
          "id": "$plans[0]"
        }
      }
      """
    Then the response status should be "200"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 0 "metric" jobs

  Scenario: Admin changes trialing account to a new plan
    Given the account "test1" is trialing
    And there exists 3 "plans"
    And I am an admin of account "test1"
    And the account "test1" has 1 "webhookEndpoint"
    And I use an authentication token
    When I send a PUT request to "/accounts/test1/plan" with the following:
      """
      {
        "data": {
          "type": "plans",
          "id": "$plans[0]"
        }
      }
      """
    Then the response status should be "200"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 0 "metric" jobs

  Scenario: Admin changes pending account to a new plan
    Given the account "test1" is pending
    And there exists 3 "plans"
    And I am an admin of account "test1"
    And the account "test1" has 1 "webhookEndpoint"
    And I use an authentication token
    When I send a PUT request to "/accounts/test1/plan" with the following:
      """
      {
        "data": {
          "type": "plans",
          "id": "$plans[0]"
        }
      }
      """
    Then the response status should be "200"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 0 "metric" jobs

  Scenario: Admin changes paused account to a new plan
    Given the account "test1" is paused
    And there exists 3 "plans"
    And I am an admin of account "test1"
    And the account "test1" has 1 "webhookEndpoint"
    And I use an authentication token
    When I send a PUT request to "/accounts/test1/plan" with the following:
      """
      {
        "data": {
          "type": "plans",
          "id": "$plans[0]"
        }
      }
      """
    Then the response status should be "422"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs

  Scenario: Admin changes canceled account to a new plan
    Given the account "test1" is canceled
    And there exists 3 "plans"
    And I am an admin of account "test1"
    And the account "test1" has 1 "webhookEndpoint"
    And I use an authentication token
    When I send a PUT request to "/accounts/test1/plan" with the following:
      """
      {
        "data": {
          "type": "plans",
          "id": "$plans[0]"
        }
      }
      """
    Then the response status should be "200"
    And sidekiq should have 1 "webhook" jobs
    And sidekiq should have 0 "metric" jobs

  Scenario: Admin attempts to change to an invalid plan
    Given the account "test1" is subscribed
    And there exists 3 "plans"
    And I am an admin of account "test1"
    And the account "test1" has 1 "webhookEndpoint"
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
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs

  Scenario: Admin attempts to change plan for another account
    Given the account "test1" is subscribed
    And there exists 3 "plans"
    And I am an admin of account "test2"
    And the account "test1" has 1 "webhookEndpoint"
    And I use an authentication token
    When I send a PUT request to "/accounts/test1/plan" with the following:
      """
      {
        "data": {
          "type": "plans",
          "id": "$plans[0]"
        }
      }
      """
    Then the response status should be "401"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
