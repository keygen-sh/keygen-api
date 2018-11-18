@api/v1
Feature: List metrics

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
    When I send a GET request to "/accounts/test1/metrics"
    Then the response status should be "403"

  Scenario: Admin retrieves all metrics for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 3 "metrics"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/metrics"
    Then the response status should be "200"
    And the JSON response should be an array with 3 "metrics"
    And sidekiq should have 0 "log" jobs

  Scenario: Admin retrieves a list of metrics that is automatically paginated
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 250 "metrics"
    And 50 "metrics" have the following attributes:
      """
      { "createdAt": "$time.1.year.ago" }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/metrics?date[start]=$date.yesterday&date[end]=$date.tomorrow"
    Then the response status should be "200"
    And the JSON response should be an array with 100 "metrics"
    And the JSON response should contain the following links:
      """
      {
        "self": "/v1/accounts/test1/metrics?date[end]=$date.tomorrow&date[start]=$date.yesterday&page[number]=1&page[size]=100",
        "prev": null,
        "next": "/v1/accounts/test1/metrics?date[end]=$date.tomorrow&date[start]=$date.yesterday&page[number]=2&page[size]=100",
        "first": "/v1/accounts/test1/metrics?date[end]=$date.tomorrow&date[start]=$date.yesterday&page[number]=1&page[size]=100",
        "last": "/v1/accounts/test1/metrics?date[end]=$date.tomorrow&date[start]=$date.yesterday&page[number]=2&page[size]=100"
      }
      """
      And sidekiq should have 0 "log" jobs

  Scenario: Admin retrieves an unsupported paginated list of metrics
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 20 "metrics"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/metrics?page[number]=2&page[size]=5"
    Then the response status should be "200"
    And the JSON response should be an array with 5 "metrics"
    And the JSON response should contain the following links:
      """
      {
        "self": "/v1/accounts/test1/metrics?page[number]=2&page[size]=5",
        "prev": "/v1/accounts/test1/metrics?page[number]=1&page[size]=5",
        "next": "/v1/accounts/test1/metrics?page[number]=3&page[size]=5",
        "first": "/v1/accounts/test1/metrics?page[number]=1&page[size]=5",
        "last": "/v1/accounts/test1/metrics?page[number]=4&page[size]=5"
      }
      """
      And sidekiq should have 0 "log" jobs

  Scenario: Admin retrieves a list of metrics within a date range that's full
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 20 "metrics"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/metrics?date[start]=$date.yesterday&date[end]=$date.tomorrow"
    Then the response status should be "200"
    And the JSON response should be an array with 20 "metrics"
    And sidekiq should have 0 "log" jobs

  Scenario: Admin retrieves a list of metrics within a date range that's empty
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 20 "metrics"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/metrics?date[start]=2017-1-2&date[end]=2017-01-03"
    Then the response status should be "200"
    And the JSON response should be an array with 0 "metrics"
    And sidekiq should have 0 "log" jobs

  Scenario: Admin retrieves a list of metrics within a date range that's too far
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 20 "metrics"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/metrics?date[start]=2017-1-1&date[end]=2017-02-02"
    Then the response status should be "400"
    And sidekiq should have 0 "log" jobs

  Scenario: Admin retrieves a list of metrics within a date range that's invalid
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 20 "metrics"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/metrics?date[start]=foo&date[end]=bar"
    Then the response status should be "400"
    And sidekiq should have 0 "log" jobs

  Scenario: Admin retrieves filters metrics by metric type
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 20 "metrics"
    And the first "metric" has the following attributes:
      """
      { "metric": "real.metric" }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/metrics?metrics[]=real.metric"
    Then the response status should be "200"
    And the JSON response should be an array with 1 "metrics"
    And sidekiq should have 0 "log" jobs

  Scenario: Admin retrieves filters metrics by metric type that doesn't exist
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 20 "metrics"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/metrics?metrics[]=bad.metric"
    Then the response status should be "200"
    And the JSON response should be an array with 0 "metrics"
    And sidekiq should have 0 "log" jobs

  Scenario: Admin attempts to retrieve all metrics for another account
    Given I am an admin of account "test2"
    But the current account is "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/metrics"
    Then the response status should be "401"
    And the JSON response should be an array of 1 error
    And sidekiq should have 0 "log" jobs

  Scenario: User attempts to retrieve all metrics for their account
    Given the current account is "test1"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    And the current account has 3 "metrics"
    When I send a GET request to "/accounts/test1/metrics"
    Then the response status should be "403"
    And the JSON response should be an array of 1 error
    And sidekiq should have 0 "log" jobs
