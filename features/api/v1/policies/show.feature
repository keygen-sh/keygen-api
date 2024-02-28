@api/v1
Feature: Show policy

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
    When I send a GET request to "/accounts/test1/policies/$0"
    Then the response status should be "403"

  Scenario: Admin retrieves a policy for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 3 "policies"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/policies/$0"
    Then the response status should be "200"
    And the response body should be a "policy"

  Scenario: Developer retrieves a policy for their account
    Given the current account is "test1"
    And the current account has 1 "developer"
    And I am a developer of account "test1"
    And the current account has 3 "policies"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/policies/$0"
    Then the response status should be "200"

  Scenario: Sales retrieves a policy for their account
    Given the current account is "test1"
    And the current account has 1 "sales-agent"
    And I am a sales agent of account "test1"
    And the current account has 3 "policies"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/policies/$0"
    Then the response status should be "200"

  Scenario: Support retrieves a policy for their account
    Given the current account is "test1"
    And the current account has 1 "support-agent"
    And I am a support agent of account "test1"
    And the current account has 3 "policies"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/policies/$0"
    Then the response status should be "200"

  Scenario: Read-only retrieves a policy for their account
    Given the current account is "test1"
    And the current account has 1 "read-only"
    And I am a read only of account "test1"
    And the current account has 3 "policies"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/policies/$0"
    Then the response status should be "200"

  Scenario: Admin retrieves an invalid policy for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/policies/invalid"
    Then the response status should be "404"
    And the first error should have the following properties:
      """
      {
        "title": "Not found",
        "detail": "The requested policy 'invalid' was not found",
        "code": "NOT_FOUND"
      }
      """

  @ee
  Scenario: Product retrieves an isolated policy
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And the current account has 1 isolated "policy"
    And I am an environment of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/policies/$0?environment=isolated"
    Then the response status should be "200"
    And the response body should be a "policy"

  Scenario: Product retrieves a policy for their product
    Given the current account is "test1"
    And the current account has 1 "product"
    And I am a product of account "test1"
    And I use an authentication token
    And the current account has 1 "policy"
    And the current product has 1 "policy"
    When I send a GET request to "/accounts/test1/policies/$0"
    Then the response status should be "200"
    And the response body should be a "policy"

  Scenario: Product attempts to retrieve a policy for another product
    Given the current account is "test1"
    And the current account has 1 "product"
    And I am a product of account "test1"
    And I use an authentication token
    And the current account has 1 "policy"
    When I send a GET request to "/accounts/test1/policies/$0"
    Then the response status should be "404"

  Scenario: Admin attempts to retrieve a policy for another account
    Given I am an admin of account "test2"
    But the current account is "test1"
    And the account "test1" has 3 "policies"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/policies/$0"
    Then the response status should be "401"
    And the response body should be an array of 1 error

  Scenario: License attempts to retrieve their policy (default permissions)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "license" for the last "policy"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/policies/$0"
    Then the response status should be "403"
    And sidekiq should have 1 "request-log" job

  Scenario: License attempts to retrieve their policy (explicit permission)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "license" for the last "policy"
    And the last "license" has the following attributes:
      """
      { "permissions": ["policy.read"] }
      """
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/policies/$0"
    Then the response status should be "200"
    And the response body should be a "policy"
    And sidekiq should have 1 "request-log" job

  Scenario: License attempts to retrieve their policy (no permission)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "license" for the last "policy"
    And the last "license" has the following attributes:
      """
      { "permissions": ["license.validate"] }
      """
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/policies/$0"
    Then the response status should be "403"
    And sidekiq should have 1 "request-log" job

  Scenario: License attempts to retrieve a policy
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 3 "policies"
    And the current account has 1 "license"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/policies/$1"
    Then the response status should be "404"
    And sidekiq should have 1 "request-log" job

  Scenario: User attempts to retrieve their policy (default permissions)
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "license" for the last "policy"
    And the current account has 1 "user"
    And the first "license" belongs to the last "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/policies/$0"
    Then the response status should be "403"
    And sidekiq should have 1 "request-log" job

   Scenario: User attempts to retrieve their policy (explicit permission)
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "license" for the last "policy"
    And the current account has 1 "user"
    And the last "user" has the following attributes:
      """
      { "permissions": ["policy.read"] }
      """
    And the last "license" belongs to the last "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/policies/$0"
    Then the response status should be "200"
    And the response body should be a "policy"
    And sidekiq should have 1 "request-log" job

  Scenario: User attempts to retrieve their policy (no permission)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "license" for the last "policy"
    And the current account has 1 "user"
    And the last "user" has the following attributes:
      """
      { "permissions": ["license.validate"] }
      """
    And the last "license" belongs to the last "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/policies/$0"
    Then the response status should be "403"
    And sidekiq should have 1 "request-log" job

  Scenario: User attempts to retrieve a policy
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 2 "policies"
    And the current account has 1 "user"
    And the current account has 1 "license" for the last "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/policies/$1"
    Then the response status should be "404"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin retrieves a policy with a machine uniqueness strategy (v1.4)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "policy" with the following:
      """
      { "machineUniquenessStrategy": "UNIQUE_PER_PRODUCT" }
      """
    And I use an authentication token
    And I use API version "1.4"
    When I send a GET request to "/accounts/test1/policies/$0"
    Then the response status should be "200"
    And the response body should be a "policy" with the following attributes:
      """
      { "machineUniquenessStrategy": "UNIQUE_PER_PRODUCT" }
      """
    Then the response should contain the following headers:
      """
      { "Keygen-Version": "1.4" }
      """

  Scenario: Admin retrieves a policy with a machine uniqueness strategy (v1.3)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "policy" with the following:
      """
      { "machineUniquenessStrategy": "UNIQUE_PER_PRODUCT" }
      """
    And I use an authentication token
    And I use API version "1.3"
    When I send a GET request to "/accounts/test1/policies/$0"
    Then the response status should be "200"
    And the response body should be a "policy" with the following attributes:
      """
      { "fingerprintUniquenessStrategy": "UNIQUE_PER_PRODUCT" }
      """
    Then the response should contain the following headers:
      """
      { "Keygen-Version": "1.3" }
      """

  Scenario: Admin retrieves a policy with a machine uniqueness strategy (v1.2)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "policy" with the following:
      """
      { "machineUniquenessStrategy": "UNIQUE_PER_PRODUCT" }
      """
    And I use an authentication token
    And I use API version "1.2"
    When I send a GET request to "/accounts/test1/policies/$0"
    Then the response status should be "200"
    And the response body should be a "policy" with the following attributes:
      """
      { "fingerprintUniquenessStrategy": "UNIQUE_PER_PRODUCT" }
      """
    Then the response should contain the following headers:
      """
      { "Keygen-Version": "1.2" }
      """

  Scenario: Admin retrieves a policy with a machine uniqueness strategy (v1.1)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "policy" with the following:
      """
      { "machineUniquenessStrategy": "UNIQUE_PER_PRODUCT" }
      """
    And I use an authentication token
    And I use API version "1.1"
    When I send a GET request to "/accounts/test1/policies/$0"
    Then the response status should be "200"
    And the response body should be a "policy" with the following attributes:
      """
      { "fingerprintUniquenessStrategy": "UNIQUE_PER_PRODUCT" }
      """
    Then the response should contain the following headers:
      """
      { "Keygen-Version": "1.1" }
      """

  Scenario: Admin retrieves a policy with a machine uniqueness strategy (v1.0)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "policy" with the following:
      """
      { "machineUniquenessStrategy": "UNIQUE_PER_PRODUCT" }
      """
    And I use an authentication token
    And I use API version "1.0"
    When I send a GET request to "/accounts/test1/policies/$0"
    Then the response status should be "200"
    And the response body should be a "policy" with the following attributes:
      """
      { "fingerprintUniquenessStrategy": "UNIQUE_PER_PRODUCT" }
      """
    Then the response should contain the following headers:
      """
      { "Keygen-Version": "1.0" }
      """

  Scenario: Admin retrieves a policy with a machine matching strategy (v1.4)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "policy" with the following:
      """
      { "machineMatchingStrategy": "MATCH_ANY" }
      """
    And I use an authentication token
    And I use API version "1.4"
    When I send a GET request to "/accounts/test1/policies/$0"
    Then the response status should be "200"
    And the response body should be a "policy" with the following attributes:
      """
      { "machineMatchingStrategy": "MATCH_ANY" }
      """
    Then the response should contain the following headers:
      """
      { "Keygen-Version": "1.4" }
      """

  Scenario: Admin retrieves a policy with a machine matching strategy (v1.3)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "policy" with the following:
      """
      { "machineMatchingStrategy": "MATCH_ANY" }
      """
    And I use an authentication token
    And I use API version "1.3"
    When I send a GET request to "/accounts/test1/policies/$0"
    Then the response status should be "200"
    And the response body should be a "policy" with the following attributes:
      """
      { "fingerprintMatchingStrategy": "MATCH_ANY" }
      """
    Then the response should contain the following headers:
      """
      { "Keygen-Version": "1.3" }
      """

  Scenario: Admin retrieves a policy with a machine matching strategy (v1.2)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "policy" with the following:
      """
      { "machineMatchingStrategy": "MATCH_ANY" }
      """
    And I use an authentication token
    And I use API version "1.2"
    When I send a GET request to "/accounts/test1/policies/$0"
    Then the response status should be "200"
    And the response body should be a "policy" with the following attributes:
      """
      { "fingerprintMatchingStrategy": "MATCH_ANY" }
      """
    Then the response should contain the following headers:
      """
      { "Keygen-Version": "1.2" }
      """

  Scenario: Admin retrieves a policy with a machine matching strategy (v1.1)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "policy" with the following:
      """
      { "machineMatchingStrategy": "MATCH_ANY" }
      """
    And I use an authentication token
    And I use API version "1.1"
    When I send a GET request to "/accounts/test1/policies/$0"
    Then the response status should be "200"
    And the response body should be a "policy" with the following attributes:
      """
      { "fingerprintMatchingStrategy": "MATCH_ANY" }
      """
    Then the response should contain the following headers:
      """
      { "Keygen-Version": "1.1" }
      """

  Scenario: Admin retrieves a policy with a machine matching strategy (v1.0)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "policy" with the following:
      """
      { "machineMatchingStrategy": "MATCH_ANY" }
      """
    And I use an authentication token
    And I use API version "1.0"
    When I send a GET request to "/accounts/test1/policies/$0"
    Then the response status should be "200"
    And the response body should be a "policy" with the following attributes:
      """
      { "fingerprintMatchingStrategy": "MATCH_ANY" }
      """
    Then the response should contain the following headers:
      """
      { "Keygen-Version": "1.0" }
      """

