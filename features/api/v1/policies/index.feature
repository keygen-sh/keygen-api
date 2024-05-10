@api/v1
Feature: List policies
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
    And the current account has 2 "policies"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/policies"
    Then the response status should be "403"

  Scenario: Admin retrieves all policies for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 3 "policies"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/policies"
    Then the response status should be "200"
    And the response body should be an array with 3 "policies"

  Scenario: Developer retrieves all policies for their account
    Given the current account is "test1"
    And the current account has 1 "developer"
    And I am a developer of account "test1"
    And the current account has 3 "policies"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/policies"
    Then the response status should be "200"

  Scenario: Sales retrieves all policies for their account
    Given the current account is "test1"
    And the current account has 1 "sales-agent"
    And I am a sales agent of account "test1"
    And the current account has 3 "policies"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/policies"
    Then the response status should be "200"

  Scenario: Support retrieves all policies for their account
    Given the current account is "test1"
    And the current account has 1 "support-agent"
    And I am a support agent of account "test1"
    And the current account has 3 "policies"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/policies"
    Then the response status should be "200"

  Scenario: Read-only retrieves all policies for their account
    Given the current account is "test1"
    And the current account has 1 "read-only"
    And I am a read only of account "test1"
    And the current account has 3 "policies"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/policies"
    Then the response status should be "200"

  Scenario: Admin retrieves a paginated list of policies
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 20 "policies"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/policies?page[number]=2&page[size]=5"
    Then the response status should be "200"
    And the response body should be an array with 5 "policies"

  Scenario: Admin retrieves a paginated list of policies with a page size that is too high
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 20 "policies"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/policies?page[number]=1&page[size]=250"
    Then the response status should be "400"

  Scenario: Admin retrieves a paginated list of policies with a page size that is too low
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 20 "policies"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/policies?page[number]=1&page[size]=-10"
    Then the response status should be "400"

  Scenario: Admin retrieves a paginated list of policies with an invalid page number
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 20 "policies"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/policies?page[number]=-1&page[size]=10"
    Then the response status should be "400"

  Scenario: Admin retrieves all policies without a limit for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 20 "policies"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/policies"
    Then the response status should be "200"
    And the response body should be an array with 10 "policies"

  Scenario: Admin retrieves all policies with a low limit for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 10 "policies"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/policies?limit=5"
    Then the response status should be "200"
    And the response body should be an array with 5 "policies"

  Scenario: Admin retrieves all policies with a high limit for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 20 "policies"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/policies?limit=20"
    Then the response status should be "200"
    And the response body should be an array with 20 "policies"

  Scenario: Admin retrieves all policies with a limit that is too high
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 20 "policies"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/policies?limit=900"
    Then the response status should be "400"

  Scenario: Admin retrieves all policies with a limit that is too low
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 20 "policies"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/policies?limit=-10"
    Then the response status should be "400"

  @ee
  Scenario: Environment retrieves all isolated policies
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And the current account has 3 isolated "policy"
    And the current account has 1 shared "policy"
    And the current account has 1 global "policy"
    And I am an environment of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/policies?environment=isolated"
    Then the response status should be "200"
    And the response body should be an array with 3 "policies"

  @ee
  Scenario: Environment retrieves all shared policies
    Given the current account is "test1"
    And the current account has 1 shared "environment"
    And the current account has 3 isolated "policy"
    And the current account has 1 shared "policy"
    And the current account has 1 global "policy"
    And I am an environment of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/policies?environment=shared"
    Then the response status should be "200"
    And the response body should be an array with 2 "policies"

  Scenario: Product retrieves all policies for their product
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "policy" for the last "product"
    And the current account has 2 "policies"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/policies"
    Then the response status should be "200"
    And the response body should be an array with 1 "policy"

  Scenario: Admin attempts to retrieve all policies for another account
    Given I am an admin of account "test2"
    But the current account is "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/policies"
    Then the response status should be "401"
    And the response body should be an array of 1 error

  Scenario: License attempts to retrieve their policies (default permissions)
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 3 "policies" for the last "product"
    And the current account has 1 "license" for the last "policy"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/policies"
    Then the response status should be "403"
    And sidekiq should have 1 "request-log" job

  Scenario: License attempts to retrieve their policies (explicit permission)
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 3 "policies" for the last "product"
    And the current account has 1 "license" for the last "policy"
    And the last "license" has the following attributes:
      """
      { "permissions": ["policy.read"] }
      """
    And I am the last license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/policies"
    Then the response status should be "200"
    And the response body should be an array with 1 "policy"
    And sidekiq should have 1 "request-log" job

  Scenario: License attempts to retrieve their policies (no permission)
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 3 "policies" for the last "product"
    And the current account has 1 "license" for the last "policy"
    And the last "license" has the following attributes:
      """
      { "permissions": ["license.validate"] }
      """
    And I am the last license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/policies"
    Then the response status should be "403"
    And sidekiq should have 1 "request-log" job

  Scenario: License attempts to retrieve all policies
    Given the current account is "test1"
    And the current account has 5 "policies"
    And the current account has 1 "license"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/policies"
    Then the response status should be "403"
    And sidekiq should have 1 "request-log" job

  Scenario: User attempts to retrieve their policies (default permissions)
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 3 "policies" for the last "product"
    And the current account has 1 "license" for the last "policy"
    And the current account has 1 "user"
    And the last "license" belongs to the last "user" through "owner"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/policies"
    Then the response status should be "403"
    And sidekiq should have 1 "request-log" job

  Scenario: User attempts to retrieve their policies (license owner, explicit permission)
    Given the current account is "test1"
    And the current account has 2 "products"
    And the current account has 4 "policies" for each "product"
    And the current account has 2 "licenses" for each "policy"
    And the current account has 1 "user"
    And the last "user" has the following attributes:
      """
      { "permissions": ["policy.read"] }
      """
    And the first "license" belongs to the last "user" through "owner"
    And the second "license" belongs to the last "user" through "owner"
    And the third "license" belongs to the last "user" through "owner"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/policies"
    Then the response status should be "200"
    And the response body should be an array with 2 "policies"
    And sidekiq should have 1 "request-log" job

  Scenario: User attempts to retrieve their policies (license user, explicit permission)
    Given the current account is "test1"
    And the current account has 2 "products"
    And the current account has 4 "policies" for each "product"
    And the current account has 2 "licenses" for each "policy"
    And the current account has 1 "user"
    And the last "user" has the following attributes:
      """
      { "permissions": ["policy.read"] }
      """
    And the current account has 1 "license-user" for the first "license" and the last "user"
    And the current account has 1 "license-user" for the second "license" and the last "user"
    And the current account has 1 "license-user" for the third "license" and the last "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/policies"
    Then the response status should be "200"
    And the response body should be an array with 2 "policies"
    And sidekiq should have 1 "request-log" job

  Scenario: User attempts to retrieve their policies (no permission)
    Given the current account is "test1"
    And the current account has 2 "products"
    And the current account has 4 "policies" for each "product"
    And the current account has 1 "license" for each "policy"
    And the current account has 1 "user"
    And the last "user" has the following attributes:
      """
      { "permissions": ["license.validate"] }
      """
    And the first "license" belongs to the last "user" through "owner"
    And the second "license" belongs to the last "user" through "owner"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/policies"
    Then the response status should be "403"
    And sidekiq should have 1 "request-log" job

  Scenario: User attempts to retrieve all policies
    Given the current account is "test1"
    And the current account has 5 "policies"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/policies"
    Then the response status should be "403"
    And sidekiq should have 1 "request-log" job

  Scenario: Admin retrieves policies with leasing strategies (v1.6)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "policies" with the following:
      """
      {
        "machineLeasingStrategy": "PER_LICENSE",
        "processLeasingStrategy": "PER_MACHINE"
      }
      """
    And I use an authentication token
    And I use API version "1.6"
    When I send a GET request to "/accounts/test1/policies"
    Then the response status should be "200"
    And the response body should be an array with 2 "policies"
    And the response body should be an array of 2 "policies" with the following attributes:
      """
      {
        "machineLeasingStrategy": "PER_LICENSE",
        "leasingStrategy": "PER_MACHINE"
      }
      """
    And the response should contain a valid signature header for "test1"
    And the response should contain the following headers:
      """
      {
        "Keygen-Account": "$account",
        "Keygen-Version": "1.6"
      }
      """

  Scenario: Admin retrieves policies with machine strategies (v1.4)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "policies" with the following:
      """
      {
        "machineUniquenessStrategy": "UNIQUE_PER_POLICY",
        "machineMatchingStrategy": "MATCH_TWO"
      }
      """
    And I use an authentication token
    And I use API version "1.4"
    When I send a GET request to "/accounts/test1/policies"
    Then the response status should be "200"
    And the response body should be an array with 2 "policies"
    And the response body should be an array of 2 "policies" with the following attributes:
      """
      {
        "machineUniquenessStrategy": "UNIQUE_PER_POLICY",
        "machineMatchingStrategy": "MATCH_TWO"
      }
      """
    And the response should contain a valid signature header for "test1"
    And the response should contain the following headers:
      """
      {
        "Keygen-Account": "$account",
        "Keygen-Version": "1.4"
      }
      """

  Scenario: Admin retrieves policies with machine strategies (v1.3)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "policies" with the following:
      """
      {
        "machineUniquenessStrategy": "UNIQUE_PER_POLICY",
        "machineMatchingStrategy": "MATCH_TWO"
      }
      """
    And I use an authentication token
    And I use API version "1.3"
    When I send a GET request to "/accounts/test1/policies"
    Then the response status should be "200"
    And the response body should be an array with 2 "policies"
    And the response body should be an array of 2 "policies" with the following attributes:
      """
      {
        "fingerprintUniquenessStrategy": "UNIQUE_PER_POLICY",
        "fingerprintMatchingStrategy": "MATCH_TWO"
      }
      """
    And the response should contain a valid signature header for "test1"
    And the response should contain the following headers:
      """
      {
        "Keygen-Account-Id": "$account",
        "Keygen-Version": "1.3"
      }
      """
