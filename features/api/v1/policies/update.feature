@api/v1
Feature: Update policy

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
    And the current account has 1 "policy"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/policies/$0"
    Then the response status should be "403"

  Scenario: Admin updates a policy for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "policy"
    And the first "policy" has the following attributes:
      """
      { "duration": 31557600 }
      """
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/policies/$0" with the following:
      """
      {
        "data": {
          "type": "policies",
          "id": "$policies[0].id",
          "attributes": {
            "requireFingerprintScope": true,
            "concurrent": false,
            "name": "Trial",
            "maxUses": 3
          }
        }
      }
      """
    Then the response status should be "200"
    And the JSON response should be a "policy" with a duration that is not nil
    And the JSON response should be a "policy" with a requireFingerprintScope
    And the JSON response should be a "policy" that is not concurrent
    And the JSON response should be a "policy" with the name "Trial"
    And the JSON response should be a "policy" with the maxUses "3"
    And sidekiq should have 2 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Developer updates a policy for their account
    Given the current account is "test1"
    And the current account has 1 "developer"
    And I am a developer of account "test1"
    And the current account has 1 "policy"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/policies/$0" with the following:
      """
      {
        "data": {
          "type": "policies",
          "id": "$policies[0].id",
          "attributes": {
            "fingerprintUniquenessStrategy": "UNIQUE_PER_ACCOUNT",
            "fingerprintMatchingStrategy": "MATCH_MOST",
            "name": "Test"
          }
        }
      }
      """
    Then the response status should be "200"

  Scenario: Sales updates a policy for their account
    Given the current account is "test1"
    And the current account has 1 "sales-agent"
    And I am a sales agent of account "test1"
    And the current account has 1 "policy"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/policies/$0" with the following:
      """
      {
        "data": {
          "type": "policies",
          "id": "$policies[0].id",
          "attributes": {
            "name": "Test"
          }
        }
      }
      """
    Then the response status should be "200"

  Scenario: Support updates a policy for their account
    Given the current account is "test1"
    And the current account has 1 "support-agent"
    And I am a support agent of account "test1"
    And the current account has 1 "policy"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/policies/$0" with the following:
      """
      {
        "data": {
          "type": "policies",
          "id": "$policies[0].id",
          "attributes": {
            "name": "Test"
          }
        }
      }
      """
    Then the response status should be "403"

  Scenario: Admin removes attributes from a policy for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "policy"
    And the first "policy" has the following attributes:
      """
      {
        "requireCheckIn": true,
        "checkInInterval": "day",
        "checkInIntervalCount": 1
      }
      """
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/policies/$0" with the following:
      """
      {
        "data": {
          "type": "policies",
          "id": "$policies[0].id",
          "attributes": {
            "requireCheckIn": false,
            "checkInInterval": null,
            "checkInIntervalCount": null,
            "duration": null
          }
        }
      }
      """
    Then the response status should be "200"
    And the JSON response should be a "policy" with a nil checkInInterval
    And the JSON response should be a "policy" with a nil checkInIntervalCount
    And sidekiq should have 2 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin attempts to update a policy for another account
    Given I am an admin of account "test2"
    But the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the account "test1" has 1 "policy"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/policies/$0" with the following:
      """
      {
        "data": {
          "type": "policies",
          "attributes": {
            "name": "Product Add-On"
          }
        }
      }
      """
    Then the response status should be "401"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Product updates a policy for their product
    Given the current account is "test1"
    And the current account has 3 "webhook-endpoints"
    And the current account has 1 "product"
    And I am a product of account "test1"
    And I use an authentication token
    And the current account has 1 "policy"
    And the current product has 1 "policy"
    When I send a PATCH request to "/accounts/test1/policies/$0" with the following:
      """
      {
        "data": {
          "type": "policies",
          "attributes": {
            "duration": null
          }
        }
      }
      """
    Then the response status should be "200"
    And the JSON response should be a "policy" with a nil duration
    And sidekiq should have 3 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Product attempts to update a policy for another product
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And I am a product of account "test1"
    And I use an authentication token
    And the current account has 1 "policy"
    When I send a PATCH request to "/accounts/test1/policies/$0" with the following:
      """
      {
        "data": {
          "type": "policies",
          "attributes": {
            "name": "Product B"
          }
        }
      }
      """
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin updates a policy's scheme attribute for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "policy"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/policies/$0" with the following:
      """
      {
        "data": {
          "type": "policies",
          "attributes": {
            "scheme": "RSA_2048_PKCS1_SIGN"
          }
        }
      }
      """
    Then the response status should be "400"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin updates a policy's encrypted attribute for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "policy"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/policies/$0" with the following:
      """
      {
        "data": {
          "type": "policies",
          "attributes": {
            "encrypted": false
          }
        }
      }
      """
    Then the response status should be "400"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin updates a policy for their account to use a pool
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "policy"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/policies/$0" with the following:
      """
      {
        "data": {
          "type": "policies",
          "attributes": {
            "usePool": true
          }
        }
      }
      """
    Then the response status should be "400"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job
