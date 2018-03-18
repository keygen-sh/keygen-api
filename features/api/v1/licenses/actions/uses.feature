@api/v1
Feature: License usage actions

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
    And the current account has 1 "license"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/increment-usage"
    Then the response status should be "403"

  Scenario: Anonymous increments the usage count for a license
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And all "policies" have the following attributes:
      """
      { "maxUses": 5 }
      """
    And the current account has 1 "license"
    And the first "license" has the following attributes:
      """
      {
        "policyId": "$policies[0]",
        "uses": 0
      }
      """
    When I send a POST request to "/accounts/test1/licenses/$0/actions/increment-usage"
    Then the response status should be "401"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs

  Scenario: Admin increments the usage count for a license by key
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And all "policies" have the following attributes:
      """
      { "maxUses": 5 }
      """
    And the current account has 1 "license"
    And the first "license" has the following attributes:
      """
      {
        "policyId": "$policies[0]",
        "key": "key1"
      }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/key1/actions/increment-usage"
    Then the response status should be "200"
    And the JSON response should be a "license" with the following attributes:
      """
      { "uses": 1 }
      """
    And the response should contain a valid signature header for "test1"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job

  Scenario: Admin increments the usage count for a license by 100
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And all "policies" have the following attributes:
      """
      { "maxUses": 100 }
      """
    And the current account has 1 "license"
    And the first "license" has the following attributes:
      """
      {
        "policyId": "$policies[0]"
      }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/increment-usage" with the following:
      """
      {
        "meta": {
          "increment": 100
        }
      }
      """
    Then the response status should be "200"
    And the JSON response should be a "license" with the following attributes:
      """
      { "uses": 100 }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job

  Scenario: Admin increments the usage count for a license by 100 for a policy that only allows 99
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And all "policies" have the following attributes:
      """
      { "maxUses": 99 }
      """
    And the current account has 1 "license"
    And the first "license" has the following attributes:
      """
      {
        "policyId": "$policies[0]"
      }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/increment-usage" with the following:
      """
      {
        "meta": {
          "increment": 100
        }
      }
      """
    Then the response status should be "422"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs

  Scenario: Admin increments the usage count for a license by a int larger than max int
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And all "policies" have the following attributes:
      """
      { "maxUses": null }
      """
    And the current account has 1 "license"
    And the first "license" has the following attributes:
      """
      {
        "policyId": "$policies[0]"
      }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/increment-usage" with the following:
      """
      {
        "meta": {
          "increment": 46116860184273879031
        }
      }
      """
    Then the response status should be "400"
    And the first error should have the following properties:
      """
      {
        "title": "Bad request",
        "detail": "integer is too large",
        "source": {
          "pointer": "/meta/increment"
        }
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs

  Scenario: Admin increments the usage count for a license that has no usage limit
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And all "policies" have the following attributes:
      """
      { "maxUses": null }
      """
    And the current account has 1 "license"
    And the first "license" has the following attributes:
      """
      {
        "policyId": "$policies[0]",
        "uses": null
      }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/increment-usage"
    Then the response status should be "200"
    And the JSON response should be a "license" with the following attributes:
      """
      { "uses": 1 }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job

  Scenario: Product increments the usage count for a license
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And all "policies" have the following attributes:
      """
      { "maxUses": 5 }
      """
    And the current account has 1 "license"
    And the first "license" has the following attributes:
      """
      {
        "policyId": "$policies[0]",
        "uses": 3
      }
      """
    And the current account has 1 "product"
    And I am a product of account "test1"
    And the current product has 1 "policy"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/increment-usage"
    Then the response status should be "200"
    And the JSON response should be a "license" with the following attributes:
      """
      { "uses": 4 }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job

  Scenario: User increments the usage count for a license
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And all "policies" have the following attributes:
      """
      { "maxUses": 5 }
      """
    And the current account has 1 "license"
    And the first "license" has the following attributes:
      """
      {
        "policyId": "$policies[0]",
        "uses": 4
      }
      """
    And the current account has 1 "user"
    And I am a user of account "test1"
    And the current user has 1 "license"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/increment-usage"
    Then the response status should be "200"
    And the JSON response should be a "license" with the following attributes:
      """
      { "uses": 5 }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job

  Scenario: Admin increments the usage count for a license that is at its usage limit
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And all "policies" have the following attributes:
      """
      { "maxUses": 5 }
      """
    And the current account has 1 "license"
    And the first "license" has the following attributes:
      """
      {
        "policyId": "$policies[0]",
        "uses": 5
      }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/increment-usage"
    Then the response status should be "422"
    And the first error should have the following properties:
      """
      {
        "title": "Unprocessable resource",
        "detail": "usage exceeds maximum allowed by current policy (5)",
        "source": {
          "pointer": "/data/attributes/uses"
        }
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs

  Scenario: Product increments the usage count for a license that is at its usage limit
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And all "policies" have the following attributes:
      """
      { "maxUses": 5 }
      """
    And the current account has 1 "license"
    And the first "license" has the following attributes:
      """
      {
        "policyId": "$policies[0]",
        "uses": 5
      }
      """
    And the current account has 1 "product"
    And I am a product of account "test1"
    And the current product has 1 "policy"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/increment-usage"
    Then the response status should be "422"
    And the first error should have the following properties:
      """
      {
        "title": "Unprocessable resource",
        "detail": "usage exceeds maximum allowed by current policy (5)",
        "source": {
          "pointer": "/data/attributes/uses"
        }
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs

  Scenario: User increments the usage count for an unprotected license that is at its usage limit
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And all "policies" have the following attributes:
      """
      {
        "protected": false,
        "maxUses": 5
      }
      """
    And the current account has 1 "license"
    And the first "license" has the following attributes:
      """
      {
        "policyId": "$policies[0]",
        "uses": 5
      }
      """
    And the current account has 1 "user"
    And I am a user of account "test1"
    And the current user has 1 "license"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/increment-usage"
    Then the response status should be "422"
    And the first error should have the following properties:
      """
      {
        "title": "Unprocessable resource",
        "detail": "usage exceeds maximum allowed by current policy (5)",
        "source": {
          "pointer": "/data/attributes/uses"
        }
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs

  Scenario: User increments the usage count for a protected license that is at its usage limit
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And all "policies" have the following attributes:
      """
      {
        "protected": true,
        "maxUses": 5
      }
      """
    And the current account has 1 "license"
    And the first "license" has the following attributes:
      """
      {
        "policyId": "$policies[0]",
        "uses": 5
      }
      """
    And the current account has 1 "user"
    And I am a user of account "test1"
    And the current user has 1 "license"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/increment-usage"
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs

  Scenario: Anonymous decrements the usage count for a license
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And all "policies" have the following attributes:
      """
      { "maxUses": 5 }
      """
    And the current account has 1 "license"
    And the first "license" has the following attributes:
      """
      {
        "policyId": "$policies[0]",
        "uses": 2
      }
      """
    When I send a POST request to "/accounts/test1/licenses/$0/actions/decrement-usage"
    Then the response status should be "401"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs

  Scenario: Admin decrements the usage count for a license
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And all "policies" have the following attributes:
      """
      { "maxUses": 5 }
      """
    And the current account has 1 "license"
    And the first "license" has the following attributes:
      """
      {
        "policyId": "$policies[0]",
        "uses": 2
      }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/decrement-usage"
    Then the response status should be "200"
    And the JSON response should be a "license" with the following attributes:
      """
      { "uses": 1 }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job

  Scenario: Admin decrements the usage count for a license by 50
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And all "policies" have the following attributes:
      """
      { "maxUses": 100 }
      """
    And the current account has 1 "license"
    And the first "license" has the following attributes:
      """
      {
        "policyId": "$policies[0]",
        "uses": 75
      }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/decrement-usage" with the following:
      """
      {
        "meta": {
          "decrement": 50
        }
      }
      """
    Then the response status should be "200"
    And the JSON response should be a "license" with the following attributes:
      """
      { "uses": 25 }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job

  Scenario: Product decrements the usage count for a license
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And all "policies" have the following attributes:
      """
      { "maxUses": 5 }
      """
    And the current account has 1 "license"
    And the first "license" has the following attributes:
      """
      {
        "policyId": "$policies[0]",
        "uses": 5
      }
      """
    And the current account has 1 "product"
    And I am a product of account "test1"
    And the current product has 1 "policy"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/decrement-usage"
    Then the response status should be "200"
    And the JSON response should be a "license" with the following attributes:
      """
      { "uses": 4 }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job

  Scenario: User decrements the usage count for a license
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And all "policies" have the following attributes:
      """
      { "maxUses": 5 }
      """
    And the current account has 1 "license"
    And the first "license" has the following attributes:
      """
      {
        "policyId": "$policies[0]",
        "uses": 1
      }
      """
    And the current account has 1 "user"
    And I am a user of account "test1"
    And the current user has 1 "license"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/decrement-usage"
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" job
    And sidekiq should have 0 "metric" job

  Scenario: Admin decrements the usage count for a license that is at 0
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And all "policies" have the following attributes:
      """
      { "maxUses": 5 }
      """
    And the current account has 1 "license"
    And the first "license" has the following attributes:
      """
      {
        "policyId": "$policies[0]",
        "uses": 0
      }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/decrement-usage"
    Then the response status should be "422"
    And the first error should have the following properties:
      """
      {
        "title": "Unprocessable resource",
        "detail": "must be greater than or equal to 0",
        "source": {
          "pointer": "/data/attributes/uses"
        }
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs

  Scenario: Anonymous resets the usage count for a license
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And all "policies" have the following attributes:
      """
      { "maxUses": 5 }
      """
    And the current account has 1 "license"
    And the first "license" has the following attributes:
      """
      {
        "policyId": "$policies[0]",
        "uses": 2
      }
      """
    When I send a POST request to "/accounts/test1/licenses/$0/actions/reset-usage"
    Then the response status should be "401"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs

  Scenario: Admin resets the usage count for a license
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And all "policies" have the following attributes:
      """
      { "maxUses": 5 }
      """
    And the current account has 1 "license"
    And the first "license" has the following attributes:
      """
      {
        "policyId": "$policies[0]",
        "uses": 2
      }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/reset-usage"
    Then the response status should be "200"
    And the JSON response should be a "license" with the following attributes:
      """
      { "uses": 0 }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job

  Scenario: Product resets the usage count for a license
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And all "policies" have the following attributes:
      """
      { "maxUses": 5 }
      """
    And the current account has 1 "license"
    And the first "license" has the following attributes:
      """
      {
        "policyId": "$policies[0]",
        "uses": 5
      }
      """
    And the current account has 1 "product"
    And I am a product of account "test1"
    And the current product has 1 "policy"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/reset-usage"
    Then the response status should be "200"
    And the JSON response should be a "license" with the following attributes:
      """
      { "uses": 0 }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job

  Scenario: User resets the usage count for a license
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And all "policies" have the following attributes:
      """
      { "maxUses": 5 }
      """
    And the current account has 1 "license"
    And the first "license" has the following attributes:
      """
      {
        "policyId": "$policies[0]",
        "uses": 1
      }
      """
    And the current account has 1 "user"
    And I am a user of account "test1"
    And the current user has 1 "license"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/reset-usage"
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" job
    And sidekiq should have 0 "metric" job