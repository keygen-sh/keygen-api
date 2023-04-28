@api/v1
Feature: Metric counts

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
    And the current account has 2 "metrics"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/metrics/actions/count"
    Then the response status should be "403"
    And sidekiq should have 0 "request-log" jobs

  Scenario: Admin retrieves metric counts for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 52 "metrics"
    And the first 19 "metrics" have the following attributes:
      """
      { "createdDate": "$time.4.days.ago" }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/metrics/actions/count"
    Then the response status should be "200"
    And the response body should contain meta with the following:
      """
      {
        "$time.13.days.ago.format": 0,
        "$time.12.days.ago.format": 0,
        "$time.11.days.ago.format": 0,
        "$time.10.days.ago.format": 0,
        "$time.9.days.ago.format": 0,
        "$time.8.days.ago.format": 0,
        "$time.7.days.ago.format": 0,
        "$time.6.days.ago.format": 0,
        "$time.5.days.ago.format": 0,
        "$time.4.days.ago.format": 19,
        "$time.3.days.ago.format": 0,
        "$time.2.days.ago.format": 0,
        "$time.1.day.ago.format": 0,
        "$date.format": 33
      }
      """
    And sidekiq should have 0 "request-log" jobs

  Scenario: Admin retrieves metric counts for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 52 "metrics"
    And the first 19 "metrics" have the following attributes:
      """
      {
        "eventTypeId": "$event_types[license.validation.succeeded]"
      }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/metrics/actions/count?metrics[]=license.validation.succeeded"
    Then the response status should be "200"
    And the response body should contain meta which includes the following:
      """
      {
        "$date.format": 19
      }
      """
    And sidekiq should have 0 "request-log" jobs

  @ee
  Scenario: Environment attempts to retrieve metric counts for their account
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And I am an environment of account "test1"
    And I use an authentication token
    And the current account has 3 "metrics"
    When I send a GET request to "/accounts/test1/metrics/actions/count?environment=isolated"
    Then the response status should be "403"
    And the response body should be an array of 1 error
    And sidekiq should have 0 "request-log" jobs

  Scenario: Product attempts to retrieve metric counts for their account
    Given the current account is "test1"
    And the current account has 1 "product"
    And I am a product of account "test1"
    And I use an authentication token
    And the current account has 3 "metrics"
    When I send a GET request to "/accounts/test1/metrics/actions/count"
    Then the response status should be "403"
    And the response body should be an array of 1 error
    And sidekiq should have 0 "request-log" jobs

  Scenario: License attempts to retrieve metric counts for their account
    Given the current account is "test1"
    And the current account has 1 "license"
    And I am a license of account "test1"
    And I use an authentication token
    And the current account has 3 "metrics"
    When I send a GET request to "/accounts/test1/metrics/actions/count"
    Then the response status should be "403"
    And the response body should be an array of 1 error
    And sidekiq should have 0 "request-log" jobs

  Scenario: User attempts to retrieve metric counts for their account
    Given the current account is "test1"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    And the current account has 3 "metrics"
    When I send a GET request to "/accounts/test1/metrics/actions/count"
    Then the response status should be "403"
    And the response body should be an array of 1 error
    And sidekiq should have 0 "request-log" jobs
