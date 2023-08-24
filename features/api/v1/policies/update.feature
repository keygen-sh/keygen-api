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
      {
        "duration": 31557600,
        "maxCores": 12,
        "maxUses": 5
      }
      """
    And I use an authentication token
    And I use API version "1.1"
    When I send a PATCH request to "/accounts/test1/policies/$0" with the following:
      """
      {
        "data": {
          "type": "policies",
          "id": "$policies[0].id",
          "attributes": {
            "requireFingerprintScope": true,
            "requireComponentsScope": true,
            "name": "Trial",
            "maxCores": 32,
            "maxUses": 3
          }
        }
      }
      """
    Then the response status should be "200"
    And the response body should be a "policy" with a duration that is not nil
    And the response body should be a "policy" with a requireFingerprintScope
    And the response body should be a "policy" with a requireComponentsScope
    And the response body should be a "policy" with the name "Trial"
    And the response body should be a "policy" with the maxCores "32"
    And the response body should be a "policy" with the maxUses "3"
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
            "expirationStrategy": "REVOKE_ACCESS",
            "expirationBasis": "FROM_FIRST_ACTIVATION",
            "transferStrategy": "RESET_EXPIRY",
            "authenticationStrategy": "MIXED",
            "heartbeatCullStrategy": "KEEP_DEAD",
            "heartbeatResurrectionStrategy": "ALWAYS_REVIVE",
            "heartbeatBasis": "FROM_FIRST_PING",
            "leasingStrategy": "PER_LICENSE",
            "overageStrategy": "NO_OVERAGE",
            "requireHeartbeat": true,
            "name": "Test"
          }
        }
      }
      """
    Then the response status should be "200"
    And the response body should be a "policy" with the following attributes:
      """
      {
        "fingerprintUniquenessStrategy": "UNIQUE_PER_ACCOUNT",
        "fingerprintMatchingStrategy": "MATCH_MOST",
        "expirationStrategy": "REVOKE_ACCESS",
        "expirationBasis": "FROM_FIRST_ACTIVATION",
        "transferStrategy": "RESET_EXPIRY",
        "authenticationStrategy": "MIXED",
        "heartbeatCullStrategy": "KEEP_DEAD",
        "heartbeatResurrectionStrategy": "ALWAYS_REVIVE",
        "heartbeatBasis": "FROM_FIRST_PING",
        "leasingStrategy": "PER_LICENSE",
        "overageStrategy": "NO_OVERAGE",
        "requireHeartbeat": true,
        "name": "Test"
      }
      """

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

  Scenario: Read-only updates a policy for their account
    Given the current account is "test1"
    And the current account has 1 "read-only"
    And I am a read only of account "test1"
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
        "requireUserScope": true,
        "requireChecksumScope": false,
        "requireVersionScope": false,
        "requireCheckIn": true,
        "checkInInterval": "day",
        "checkInIntervalCount": 1,
        "duration": 86000
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
            "requireUserScope": false,
            "requireChecksumScope": true,
            "requireVersionScope": true,
            "requireCheckIn": false,
            "checkInInterval": null,
            "checkInIntervalCount": null,
            "duration": null
          }
        }
      }
      """
    Then the response status should be "200"
    And the response body should be a "policy" with the following attributes:
      """
      {
        "requireUserScope": false,
        "requireChecksumScope": true,
        "requireVersionScope": true,
        "requireCheckIn": false,
        "checkInInterval": null,
        "checkInIntervalCount": null,
        "duration": null
      }
      """
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
    And the response body should be a "policy" with a nil duration
    And sidekiq should have 3 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Environment updates an isolated policy
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And the current account has 2 isolated "webhook-endpoints"
    And the current account has 1 isolated "policy"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "keygen-environment": "isolated" }
      """
    When I send a PATCH request to "/accounts/test1/policies/$0" with the following:
      """
      {
        "data": {
          "type": "policies",
          "id": "$policies[0].id",
          "attributes": {
            "name": "Isolated Policy"
          }
        }
      }
      """
    Then the response status should be "200"
    And the response body should be a "policy" with the following attributes:
      """
      { "name": "Isolated Policy" }
      """
    And sidekiq should have 2 "webhook" jobs
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
    Then the response status should be "404"
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

  Scenario: Admin updates a policy to be concurrent (v1.2)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "policy"
    And I use an authentication token
    And I use API version "1.2"
    When I send a PATCH request to "/accounts/test1/policies/$0" with the following:
      """
      {
        "data": {
          "type": "policies",
          "id": "$policies[0].id",
          "attributes": {
            "concurrent": false
          }
        }
      }
      """
    Then the response status should be "400"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin updates a policy to be concurrent (v1.1)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "policy"
    And I use an authentication token
    And I use API version "1.1"
    When I send a PATCH request to "/accounts/test1/policies/$0" with the following:
      """
      {
        "data": {
          "type": "policies",
          "id": "$policies[0].id",
          "attributes": {
            "concurrent": false
          }
        }
      }
      """
    Then the response status should be "200"
    And the response body should be a "policy" with an overageStrategy "NO_OVERAGE"
    And the response body should be a "policy" that is not concurrent
    And sidekiq should have 2 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin updates a policy to be concurrent (v1.0)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "policy"
    And I use an authentication token
    And I use API version "1.0"
    When I send a PATCH request to "/accounts/test1/policies/$0" with the following:
      """
      {
        "data": {
          "type": "policies",
          "id": "$policies[0].id",
          "attributes": {
            "concurrent": false
          }
        }
      }
      """
    Then the response status should be "200"
    And the response body should be a "policy" with an overageStrategy "NO_OVERAGE"
    And the response body should be a "policy" that is not concurrent
    And sidekiq should have 2 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: License attempts to update their policy
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "license" for the last "policy"
    And I am a license of account "test1"
    And I use an authentication token
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
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: License attempts to update a policy
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 3 "policies"
    And the current account has 1 "license"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/policies/$1" with the following:
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
    Then the response status should be "404"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: User attempts to update their policy
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "license" for the last "policy"
    And the current account has 1 "user"
    And the last "license" belongs to the last "user"
    And I am a user of account "test1"
    And I use an authentication token
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
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: User attempts to update a policy
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 2 "policies"
    And the current account has 1 "user"
    And the current account has 1 "license" for the last "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/policies/$1" with the following:
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
    Then the response status should be "404"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" job
    And sidekiq should have 1 "request-log" job
