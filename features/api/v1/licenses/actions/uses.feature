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
    And sidekiq should have 1 "request-log" job

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
    And the response body should be a "license" with the following attributes:
      """
      { "uses": 1 }
      """
    And the response should contain a valid signature header for "test1"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

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
    And the response body should be a "license" with the following attributes:
      """
      { "uses": 100 }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

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
    And sidekiq should have 1 "request-log" job

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
    And sidekiq should have 1 "request-log" job

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
    And the response body should be a "license" with the following attributes:
      """
      { "uses": 1 }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Environment increments the usage count for an isolated license
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And the current account has 1 isolated "webhook-endpoint"
    And the current account has 1 isolated "policies" with the following:
      """
      { "maxUses": 5 }
      """
    And the current account has 1 isolated "license" for the last "policy"
    And the last "license" has the following attributes:
      """
      { "uses": 3 }
      """
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    When I send a POST request to "/accounts/test1/licenses/$0/actions/increment-usage"
    Then the response status should be "200"
    And the response body should be a "license" with the following attributes:
      """
      { "uses": 4 }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Product increments the usage count for a license
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And the current account has 1 "policy" for the last "product"
    And the last "policy" has the following attributes:
      """
      { "maxUses": 5 }
      """
    And the current account has 1 "license" for the last "policy"
    And the last "license" has the following attributes:
      """
      { "uses": 3 }
      """
    And I am a product of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/increment-usage"
    Then the response status should be "200"
    And the response body should be a "license" with the following attributes:
      """
      { "uses": 4 }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

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
    And the response body should be a "license" with the following attributes:
      """
      { "uses": 5 }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

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
        "code": "USES_LIMIT_EXCEEDED",
        "source": {
          "pointer": "/data/attributes/uses"
        }
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin increments the usage count for a license that would be at its usage limit but has an override
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
        "maxUses": 10,
        "uses": 5
      }
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/increment-usage"
    Then the response status should be "200"
    And the response body should be a "license" with the following attributes:
      """
      { "uses": 6 }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Product increments the usage count for a license that is at its usage limit
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And the current account has 1 "policy" for the last "product"
    And the last "policy" have the following attributes:
      """
      { "maxUses": 5 }
      """
    And the current account has 1 "license" for the last "policy"
    And the last "license" has the following attributes:
      """
      { "uses": 5 }
      """
    And I am a product of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/increment-usage"
    Then the response status should be "422"
    And the first error should have the following properties:
      """
      {
        "title": "Unprocessable resource",
        "detail": "usage exceeds maximum allowed by current policy (5)",
        "code": "USES_LIMIT_EXCEEDED",
        "source": {
          "pointer": "/data/attributes/uses"
        }
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: License increments the usage count for itself
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
    And I am a license of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/increment-usage"
    Then the response status should be "200"
    And the response body should be a "license" with the following attributes:
      """
      { "uses": 5 }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: License increments the usage count for another license
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And all "policies" have the following attributes:
      """
      { "maxUses": 5 }
      """
    And the current account has 2 "licenses"
    And the first "license" has the following attributes:
      """
      {
        "policyId": "$policies[0]",
        "uses": 4
      }
      """
    And I am a license of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$1/actions/increment-usage"
    Then the response status should be "404"
    And sidekiq should have 0 "webhook" job
    And sidekiq should have 0 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: User increments the usage count for an unprotected license that is at its usage limit
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 unprotected "policy"
    And the last "policy" has the following attributes:
      """
      { "maxUses": 5 }
      """
    And the current account has 1 "license" for the last "policy"
    And the last "license" has the following attributes:
      """
      { "uses": 5 }
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
        "code": "USES_LIMIT_EXCEEDED",
        "source": {
          "pointer": "/data/attributes/uses"
        }
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: User increments the usage count for a protected license that is at its usage limit
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 protected "policy"
    And the last "policy" has the following attributes:
      """
      { "maxUses": 5 }
      """
    And the current account has 1 "license" for the last "policy"
    And the last "license" has the following attributes:
      """
      { "uses": 5 }
      """
    And the current account has 1 "user"
    And I am a user of account "test1"
    And the current user has 1 "license"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/increment-usage"
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

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
    And sidekiq should have 1 "request-log" job

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
    And the response body should be a "license" with the following attributes:
      """
      { "uses": 1 }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

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
    And the response body should be a "license" with the following attributes:
      """
      { "uses": 25 }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Environment decrements the usage count for a shared license
    Given the current account is "test1"
    And the current account has 1 shared "environment"
    And the current account has 1 shared "webhook-endpoint"
    And the current account has 1 shared "policies" with the following:
      """
      { "maxUses": 5 }
      """
    And the current account has 1 shared "license" for the last "policy"
    And the last "license" has the following attributes:
      """
      { "uses": 3 }
      """
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
    When I send a POST request to "/accounts/test1/licenses/$0/actions/decrement-usage"
    Then the response status should be "200"
    And the response body should be a "license" with the following attributes:
      """
      { "uses": 2 }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Product decrements the usage count for a license
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And the current account has 1 "policy" for the last "product"
    And the last "policy" has the following attributes:
      """
      { "maxUses": 5 }
      """
    And the current account has 1 "license" for the last "policy"
    And the last "license" has the following attributes:
      """
      { "uses": 5 }
      """
    And I am a product of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/decrement-usage"
    Then the response status should be "200"
    And the response body should be a "license" with the following attributes:
      """
      { "uses": 4 }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

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
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

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
        "code": "USES_INVALID",
        "source": {
          "pointer": "/data/attributes/uses"
        }
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: License decrements the usage count for itself
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
    And I am a license of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/decrement-usage"
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" job
    And sidekiq should have 0 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: License decrements the usage count for another license
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policies"
    And all "policies" have the following attributes:
      """
      { "maxUses": 5 }
      """
    And the current account has 2 "licenses"
    And the first "license" has the following attributes:
      """
      {
        "policyId": "$policies[0]",
        "uses": 4
      }
      """
    And I am a license of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$1/actions/decrement-usage"
    Then the response status should be "404"
    And sidekiq should have 0 "webhook" job
    And sidekiq should have 0 "metric" job
    And sidekiq should have 1 "request-log" job

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
    And sidekiq should have 1 "request-log" job

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
    And the response body should be a "license" with the following attributes:
      """
      { "uses": 0 }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Environment resets the usage count for an isolated license
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And the current account has 1 isolated "webhook-endpoint"
    And the current account has 1 isolated "policies" with the following:
      """
      { "maxUses": 5 }
      """
    And the current account has 1 isolated "license" for the last "policy"
    And the last "license" has the following attributes:
      """
      { "uses": 3 }
      """
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    When I send a POST request to "/accounts/test1/licenses/$0/actions/reset-usage"
    Then the response status should be "200"
    And the response body should be a "license" with the following attributes:
      """
      { "uses": 0 }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Product resets the usage count for a license
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And the current account has 1 "policy" for the last "product"
    And the last "policy" has the following attributes:
      """
      { "maxUses": 5 }
      """
    And the current account has 1 "license" for the last "policy"
    And the last "license" has the following attributes:
      """
      { "uses": 5 }
      """
    And I am a product of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/reset-usage"
    Then the response status should be "200"
    And the response body should be a "license" with the following attributes:
      """
      { "uses": 0 }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

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
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: License decrements the usage count for itself
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
    And I am a license of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/reset-usage"
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" job
    And sidekiq should have 0 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: License decrements the usage count for another license
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
    And I am a license of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/reset-usage"
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" job
    And sidekiq should have 0 "metric" job
    And sidekiq should have 1 "request-log" job

  # Expiration basis
  Scenario: License increments its usage count with a usage expiration basis (not set)
    Given the current account is "test1"
    And the current account has 1 "policies"
    And the first "policy" has the following attributes:
      """
      {
        "expirationBasis": "FROM_FIRST_USE",
        "duration": $time.1.year
      }
      """
    And the current account has 1 "license"
    And the first "license" has the following attributes:
      """
      {
        "policyId": "$policies[0]",
        "expiry": null
      }
      """
    And I am a license of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/increment-usage"
    Then the response status should be "200"
    And sidekiq should process 1 "event-log" job
    And sidekiq should process 1 "event-notification" job
    And the first "license" should have a 1 year expiry

  Scenario: License increments its usage count with a usage expiration basis (set)
    Given the current account is "test1"
    And the current account has 1 "policies"
    And the first "policy" has the following attributes:
      """
      {
        "expirationBasis": "FROM_FIRST_USE",
        "duration": $time.1.year
      }
      """
    And the current account has 1 "license"
    And the first "license" has the following attributes:
      """
      {
        "policyId": "$policies[0]",
        "expiry": "2022-01-03T14:18:02.743Z"
      }
      """
    And I am a license of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/licenses/$0/actions/increment-usage"
    Then the response status should be "200"
    And sidekiq should process 1 "event-log" job
    And sidekiq should process 1 "event-notification" job
    And the first "license" should have the expiry "2022-01-03T14:18:02.743Z"
