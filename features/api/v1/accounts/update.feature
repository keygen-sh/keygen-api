@api/v1
Feature: Update account

  Background:
    Given the following "accounts" exist:
      | Name    | Slug  |
      | Test 1  | test1 |
      | Test 2  | test2 |
    And I send and accept JSON

  Scenario: Endpoint should be accessible when account is disabled
    Given the account "test1" is canceled
    When I send a GET request to "/accounts/test1"
    Then the response status should not be "403"

  Scenario: Admin updates their account
    Given I am an admin of account "test1"
    And the account "test1" has 1 "webhook-endpoint"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1" with the following:
      """
      {
        "data": {
          "type": "accounts",
          "id": "$accounts[0].id",
          "attributes": {
            "name": "Company Name"
          }
        }
      }
      """
    Then the response status should be "200"
    And the JSON response should be an "account" with the name "Company Name"
    And the JSON response should be an "account" with the following meta:
      """
      {
        "publicKeys": {
          "rsa": "$~accounts[0].rsa_public_key",
          "dsa": "$~accounts[0].dsa_public_key"
          "ecdsa": "$accounts[0].ecdsa_public_key"
        }
      }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 0 "request-log" jobs

  Scenario: Admin updates the name for their account
    Given I am an admin of account "test1"
    And the account "test1" has 1 "webhook-endpoint"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1" with the following:
      """
      {
        "data": {
          "type": "accounts",
          "attributes": {
            "slug": "new-name"
          }
        }
      }
      """
    Then the response status should be "200"
    And the JSON response should be an "account" with the slug "new-name"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 0 "request-log" jobs

  Scenario: Admin attempts to update another account
    Given I am an admin of account "test2"
    And the account "test1" has 1 "webhook-endpoint"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1" with the following:
      """
      {
        "data": {
          "type": "accounts",
          "attributes": {
            "name": "Company Name"
          }
        }
      }
      """
    Then the response status should be "401"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 0 "request-log" jobs

  Scenario: User attempts to update an account
    Given the account "test1" has 1 "user"
    And the account "test1" has 1 "webhook-endpoint"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1" with the following:
      """
      {
        "data": {
          "type": "accounts",
          "attributes": {
            "name": "Company Name"
          }
        }
      }
      """
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 0 "request-log" jobs
