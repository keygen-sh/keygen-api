@api/v1
Feature: Show key

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
    And the current account has 3 "keys"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/keys/$0"
    Then the response status should be "403"

  Scenario: Admin retrieves a key for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 3 "keys"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/keys/$0"
    Then the response status should be "200"
    And the response body should be a "key"
    And the response should contain a valid signature header for "test1"
    And sidekiq should have 1 "request-log" job

  Scenario: Admin retrieves an invalid key for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/keys/invalid"
    Then the response status should be "404"
    And the first error should have the following properties:
      """
      {
        "title": "Not found",
        "detail": "The requested key 'invalid' was not found",
        "code": "NOT_FOUND"
      }
      """
    And sidekiq should have 1 "request-log" job

  @ce
  Scenario: Environment retrieves a key (isolated)
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And the current account has 1 isolated "key"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    When I send a GET request to "/accounts/test1/keys/$0"
    Then the response status should be "400"

  @ee
  Scenario: Environment retrieves a key (isolated)
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And the current account has 1 isolated "key"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    When I send a GET request to "/accounts/test1/keys/$0"
    Then the response status should be "200"
    And the response body should be an "key"

  @ee
  Scenario: Environment retrieves a key (shared)
    Given the current account is "test1"
    And the current account has 1 shared "environment"
    And the current account has 1 shared "key"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
    When I send a GET request to "/accounts/test1/keys/$0"
    Then the response status should be "200"
    And the response body should be an "key"

  Scenario: Product retrieves a key for their product
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 pooled "policy" for the last "product"
    And the current account has 1 "key" for the last "policy"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/keys/$0"
    Then the response status should be "200"
    And the response body should be a "key"
    And sidekiq should have 1 "request-log" job

  Scenario: Product attempts to retrieve a key for another product
    Given the current account is "test1"
    And the current account has 1 "product"
    And I am a product of account "test1"
    And I use an authentication token
    And the current account has 1 "key"
    When I send a GET request to "/accounts/test1/keys/$0"
    Then the response status should be "404"
    And sidekiq should have 1 "request-log" job

  Scenario: License attempts to retrieve a key
    Given the current account is "test1"
    And the current account has 1 "key"
    And the current account has 1 "license"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/keys/$0"
    Then the response status should be "404"
    And sidekiq should have 1 "request-log" job

  Scenario: User attempts to retrieve a key
    Given the current account is "test1"
    And the current account has 1 "key"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/keys/$0"
    Then the response status should be "404"
    And sidekiq should have 1 "request-log" job

  Scenario: Admin attempts to retrieve a key for another account
    Given I am an admin of account "test2"
    But the current account is "test1"
    And the account "test1" has 3 "keys"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/keys/$0"
    Then the response status should be "401"
    And the response body should be an array of 1 error
    And sidekiq should have 1 "request-log" job
