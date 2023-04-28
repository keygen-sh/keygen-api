@api/v1
Feature: Show metric

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
    And the current account has 1 "metric"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/metrics/$0"
    Then the response status should be "403"
    And sidekiq should have 0 "request-log" jobs

  Scenario: Admin retrieves a metric for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 3 "metrics"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/metrics/$0"
    Then the response status should be "200"
    And the response body should be a "metric"
    And sidekiq should have 0 "request-log" jobs

  Scenario: Admin retrieves an invalid metric for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/metrics/invalid"
    Then the response status should be "404"
    And the first error should have the following properties:
      """
      {
        "title": "Not found",
        "detail": "The requested metric 'invalid' was not found",
        "code": "NOT_FOUND"
      }
      """
    And sidekiq should have 0 "request-log" jobs

  Scenario: Admin attempts to retrieve a metric for another account
    Given I am an admin of account "test2"
    But the current account is "test1"
    And the account "test1" has 3 "metrics"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/metrics/$0"
    Then the response status should be "401"
    And the response body should be an array of 1 error
    And sidekiq should have 0 "request-log" jobs

  @ee
  Scenario: Environment retrieves a metric for their account
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And the current account has 3 "metrics"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "keygen-environment": "isolated" }
      """
    When I send a GET request to "/accounts/test1/metrics/$0"
    Then the response status should be "404"
    And sidekiq should have 0 "request-log" jobs

  Scenario: Product retrieves a metric for their account
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 3 "metrics"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/metrics/$0"
    Then the response status should be "404"
    And sidekiq should have 0 "request-log" jobs

  Scenario: License retrieves a metric for their account
    Given the current account is "test1"
    And the current account has 1 "license"
    And the current account has 3 "metrics"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/metrics/$0"
    Then the response status should be "404"
    And sidekiq should have 0 "request-log" jobs

  Scenario: User retrieves a metric for their account
    Given the current account is "test1"
    And the current account has 1 "user"
    And the current account has 3 "metrics"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/metrics/$0"
    Then the response status should be "404"
    And sidekiq should have 0 "request-log" jobs
