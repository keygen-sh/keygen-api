@api/v1
@ee
Feature: Request log counts
  Background:
    Given the following "accounts" exist:
      | Name    | Slug  |
      | Test 1  | test1 |
      | Test 2  | test2 |
    And I send and accept JSON

  Scenario: Endpoint should be accessible when account is disabled
    Given the account "test1" is canceled
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "request-logs"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/request-logs/actions/count"
    Then the response status should be "200"
    And sidekiq should have 0 "request-log" jobs

  Scenario: Admin retrieves log counts for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 52 "request-logs"
    And the first 10 "request-logs" have the following attributes:
      """
      { "createdDate": "$time.8.days.ago" }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/request-logs/actions/count"
    Then the response status should be "200"
    And the response body should contain meta with the following:
      """
      {
        "$time.13.days.ago.format": 0,
        "$time.12.days.ago.format": 0,
        "$time.11.days.ago.format": 0,
        "$time.10.days.ago.format": 0,
        "$time.9.days.ago.format": 0,
        "$time.8.days.ago.format": 10,
        "$time.7.days.ago.format": 0,
        "$time.6.days.ago.format": 0,
        "$time.5.days.ago.format": 0,
        "$time.4.days.ago.format": 0,
        "$time.3.days.ago.format": 0,
        "$time.2.days.ago.format": 0,
        "$time.1.day.ago.format": 0,
        "$date.format": 42
      }
      """
    And sidekiq should have 0 "request-log" jobs

  @skip
  Scenario: Environment attempts to retrieve isolated log counts for their account
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And the current account has 3 isolated "request-logs"
    And the current account has 3 shared "request-logs"
    And the current account has 3 global "request-logs"
    And I am an environment of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/request-logs/actions/count?environment=isolated"
    Then the response status should be "200"
    And the response body should contain meta with the following:
      """
      { "$date.format": 3 }
      """

  @skip
  Scenario: Environment attempts to retrieve shared log counts for their account
    Given the current account is "test1"
    And the current account has 1 shared "environment"
    And the current account has 3 isolated "request-logs"
    And the current account has 3 shared "request-logs"
    And the current account has 3 global "request-logs"
    And I am an environment of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/request-logs/actions/count?environment=isolated"
    Then the response status should be "200"
    And the response body should contain meta with the following:
      """
      { "$date.format": 6 }
      """

  Scenario: Product attempts to retrieve log counts for their account
    Given the current account is "test1"
    And the current account has 3 "request-logs"
    And the current account has 1 "product"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/request-logs/actions/count"
    Then the response status should be "403"
    And the response body should be an array of 1 error
    And sidekiq should have 0 "request-log" jobs

  Scenario: License attempts to retrieve log counts for their account
    Given the current account is "test1"
    And the current account has 3 "request-logs"
    And the current account has 1 "license"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/request-logs/actions/count"
    Then the response status should be "403"
    And the response body should be an array of 1 error
    And sidekiq should have 0 "request-log" jobs

  Scenario: User attempts to retrieve log counts for their account
    Given the current account is "test1"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    And the current account has 3 "request-logs"
    When I send a GET request to "/accounts/test1/request-logs/actions/count"
    Then the response status should be "403"
    And the response body should be an array of 1 error
    And sidekiq should have 0 "request-log" jobs
