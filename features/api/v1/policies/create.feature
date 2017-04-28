@api/v1
Feature: Create policy

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
    And I use an authentication token
    When I send a POST request to "/accounts/test1/policies"
    Then the response status should be "403"

  Scenario: Admin creates a policy for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "webhookEndpoints"
    And the current account has 1 "product"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/policies" with the following:
      """
      {
        "data": {
          "type": "policies",
          "attributes": {
            "name": "Premium Add-On",
            "maxMachines": 5,
            "floating": true,
            "strict": false,
            "encrypted": true,
            "duration": $time.2.weeks
          },
          "relationships": {
            "product": {
              "data": {
                "type": "products",
                "id": "$products[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And sidekiq should have 2 "webhook" jobs
    And sidekiq should have 1 "metric" job

  Scenario: Admin attempts to create an incomplete policy for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhookEndpoint"
    And the current account has 1 "product"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/policies" with the following:
      """
      {
        "data": {
          "type": "policies",
          "attributes": {
            "name": "Premium Add-On",
            "maxMachines": 5,
            "floating": true,
            "strict": false,
            "encrypted": true,
            "duration": $time.2.weeks
          }
        }
      }
      """
    Then the response status should be "400"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs

  Scenario: Admin attempts to create a policy that is encrypted and uses a pool
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhookEndpoint"
    And the current account has 1 "product"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/policies" with the following:
      """
      {
        "data": {
          "type": "policies",
          "attributes": {
            "name": "Invalid",
            "encrypted": true,
            "usePool": true
          },
          "relationships": {
            "product": {
              "data": {
                "type": "products",
                "id": "$products[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "422"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs

  Scenario: Admin attempts to create a policy for another account
    Given I am an admin of account "test2"
    But the current account is "test1"
    And the current account has 7 "webhookEndpoints"
    And the current account has 1 "product"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/policies" with the following:
      """
      {
        "data": {
          "type": "policies",
          "attributes": {
            "name": "Basic",
            "maxMachines": 1,
            "floating": false,
            "strict": true,
            "duration": $time.2.weeks
          },
          "relationships": {
            "product": {
              "data": {
                "type": "products",
                "id": "$products[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "401"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs

  Scenario: Product attempts to create a policy for their product
    Given the current account is "test1"
    And the current account has 2 "webhookEndpoints"
    And the current account has 1 "product"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/policies" with the following:
      """
      {
        "data": {
          "type": "policies",
          "attributes": {
            "name": "Add-On",
            "maxMachines": 1,
            "floating": false,
            "strict": true,
            "encrypted": true,
            "duration": $time.2.weeks
          },
          "relationships": {
            "product": {
              "data": {
                "type": "products",
                "id": "$products[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And sidekiq should have 2 "webhook" jobs
    And sidekiq should have 1 "metric" job

  Scenario: User attempts to create a policy for their account
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/policies" with the following:
      """
      {
        "data": {
          "type": "policies",
          "attributes": {
            "name": "Basic",
            "maxMachines": 1,
            "floating": false,
            "strict": true,
            "duration": $time.2.weeks
          },
          "relationships": {
            "product": {
              "data": {
                "type": "products",
                "id": "$products[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
