@api/v1
Feature: List metrics

  Background:
    Given the following "accounts" exist:
      | Name    | Slug  |
      | Test 1  | test1 |
      | Test 2  | test2 |
    And I send and accept JSON

  Scenario: Admin retrieves all metrics for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 3 "metrics"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/metrics"
    Then the response status should be "200"
    And the JSON response should be an array with 3 "metrics"

  Scenario: Admin retrieves a paginated list of metrics
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 20 "metrics"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/metrics?page[number]=2&page[size]=5"
    Then the response status should be "200"
    And the JSON response should be an array with 5 "metrics"

  Scenario: Admin retrieves a paginated list of metrics with a page size that is too high
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 20 "metrics"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/metrics?page[number]=1&page[size]=250"
    Then the response status should be "400"

  Scenario: Admin retrieves a paginated list of metrics with a page size that is too low
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 20 "metrics"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/metrics?page[number]=1&page[size]=-10"
    Then the response status should be "400"

  Scenario: Admin retrieves a paginated list of metrics with an invalid page number
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 20 "metrics"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/metrics?page[number]=-1&page[size]=10"
    Then the response status should be "400"

  Scenario: Admin retrieves all metrics without a limit for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 20 "metrics"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/metrics"
    Then the response status should be "200"
    And the JSON response should be an array with 10 "metrics"

  Scenario: Admin retrieves all metrics with a low limit for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 10 "metrics"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/metrics?limit=5"
    Then the response status should be "200"
    And the JSON response should be an array with 5 "metrics"

  Scenario: Admin retrieves all metrics with a high limit for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 20 "metrics"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/metrics?limit=20"
    Then the response status should be "200"
    And the JSON response should be an array with 20 "metrics"

  Scenario: Admin retrieves all metrics with a limit that is too high
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 20 "metrics"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/metrics?limit=900"
    Then the response status should be "400"

  Scenario: Admin retrieves all metrics with a limit that is too low
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 20 "metrics"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/metrics?limit=-10"
    Then the response status should be "400"

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

  Scenario: Admin retrieves filters metrics by metric type that doesn't exist
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 20 "metrics"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/metrics?metrics[]=bad.metric"
    Then the response status should be "200"
    And the JSON response should be an array with 0 "metrics"

  Scenario: Admin attempts to retrieve all metrics for another account
    Given I am an admin of account "test2"
    But the current account is "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/metrics"
    Then the response status should be "401"
    And the JSON response should be an array of 1 error

  Scenario: User attempts to retrieve all metrics for their account
    Given the current account is "test1"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    And the current account has 3 "metrics"
    When I send a GET request to "/accounts/test1/metrics"
    Then the response status should be "403"
    And the JSON response should be an array of 1 error
