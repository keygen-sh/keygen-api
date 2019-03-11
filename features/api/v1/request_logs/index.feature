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
    And the current account has 2 "request-logs"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/request-logs"
    Then the response status should be "403"

  Scenario: Admin retrieves all logs for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 3 "request-logs"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/request-logs"
    Then the response status should be "200"
    And the JSON response should be an array with 3 "request-logs"

  Scenario: Admin retrieves a list of logs that is automatically paginated
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 250 "request-logs"
    And 50 "request-logs" have the following attributes:
      """
      { "createdAt": "$time.1.year.ago" }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/request-logs?date[start]=$date.yesterday&date[end]=$date.tomorrow"
    Then the response status should be "200"
    And the JSON response should be an array with 100 "request-logs"
    And the JSON response should contain the following links:
      """
      {
        "self": "/v1/accounts/test1/request-logs?date[end]=$date.tomorrow&date[start]=$date.yesterday&page[number]=1&page[size]=100",
        "prev": null,
        "next": "/v1/accounts/test1/request-logs?date[end]=$date.tomorrow&date[start]=$date.yesterday&page[number]=2&page[size]=100",
        "first": "/v1/accounts/test1/request-logs?date[end]=$date.tomorrow&date[start]=$date.yesterday&page[number]=1&page[size]=100",
        "last": "/v1/accounts/test1/request-logs?date[end]=$date.tomorrow&date[start]=$date.yesterday&page[number]=2&page[size]=100",
        "meta": {
          "pages": 2,
          "count": 200
        }
      }
      """

  Scenario: Admin retrieves an unsupported paginated list of logs
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 20 "request-logs"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/request-logs?page[number]=2&page[size]=5"
    Then the response status should be "200"
    And the JSON response should be an array with 5 "request-logs"
    And the JSON response should contain the following links:
      """
      {
        "self": "/v1/accounts/test1/request-logs?page[number]=2&page[size]=5",
        "prev": "/v1/accounts/test1/request-logs?page[number]=1&page[size]=5",
        "next": "/v1/accounts/test1/request-logs?page[number]=3&page[size]=5",
        "first": "/v1/accounts/test1/request-logs?page[number]=1&page[size]=5",
        "last": "/v1/accounts/test1/request-logs?page[number]=4&page[size]=5",
        "meta": {
          "pages": 4,
          "count": 20
        }
      }
      """

  Scenario: Admin retrieves a list of logs within a date range that's full
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 20 "request-logs"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/request-logs?date[start]=$date.yesterday&date[end]=$date.tomorrow"
    Then the response status should be "200"
    And the JSON response should be an array with 20 "request-logs"

  Scenario: Admin retrieves a list of logs within a date range that's empty
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 20 "request-logs"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/request-logs?date[start]=2017-1-2&date[end]=2017-01-03"
    Then the response status should be "200"
    And the JSON response should be an array with 0 "request-logs"

  Scenario: Admin retrieves a list of logs within a date range that's too far
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 20 "request-logs"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/request-logs?date[start]=2017-1-1&date[end]=2017-02-02"
    Then the response status should be "400"

  Scenario: Admin retrieves a list of logs within a date range that's invalid
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 20 "request-logs"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/request-logs?date[start]=foo&date[end]=bar"
    Then the response status should be "400"

  Scenario: Admin attempts to retrieve all logs for another account
    Given I am an admin of account "test2"
    But the current account is "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/request-logs"
    Then the response status should be "401"
    And the JSON response should be an array of 1 error

  Scenario: User attempts to retrieve all logs for their account
    Given the current account is "test1"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    And the current account has 3 "request-logs"
    When I send a GET request to "/accounts/test1/request-logs"
    Then the response status should be "403"
    And the JSON response should be an array of 1 error
