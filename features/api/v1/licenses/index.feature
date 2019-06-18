@api/v1
Feature: List license

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
    And the current account has 2 "licenses"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses"
    Then the response status should be "403"

  Scenario: Admin retrieves all licenses for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 3 "licenses"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses"
    Then the response status should be "200"
    And the JSON response should be an array with 3 "licenses"

  Scenario: Admin retrieves a paginated list of licenses
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 20 "licenses"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses?page[number]=4&page[size]=5"
    Then the response status should be "200"
    And the JSON response should be an array with 5 "licenses"
    And the JSON response should contain the following links:
      """
      {
        "self": "/v1/accounts/test1/licenses?page[number]=4&page[size]=5",
        "prev": "/v1/accounts/test1/licenses?page[number]=3&page[size]=5",
        "first": "/v1/accounts/test1/licenses?page[number]=1&page[size]=5",
        "meta": {
          "pages": 4,
          "count": 20
        }
      }
      """
    And the response should contain a valid signature header for "test1"

  Scenario: Admin retrieves a paginated list of licenses with a page size that is too high
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 20 "licenses"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses?page[number]=1&page[size]=250"
    Then the response status should be "400"

  Scenario: Admin retrieves a paginated list of licenses with a page size that is too low
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 20 "licenses"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses?page[number]=1&page[size]=-250"
    Then the response status should be "400"

  Scenario: Admin retrieves a paginated list of licenses with an invalid page number
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 20 "licenses"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses?page[number]=-1&page[size]=10"
    Then the response status should be "400"

  Scenario: Admin retrieves all licenses without a limit for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 20 "licenses"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses"
    Then the response status should be "200"
    And the JSON response should be an array with 10 "licenses"

  Scenario: Admin retrieves all licenses with a low limit for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 10 "licenses"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses?limit=5"
    Then the response status should be "200"
    And the JSON response should be an array with 5 "licenses"

  Scenario: Admin retrieves all licenses with a high limit for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 20 "licenses"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses?limit=20"
    Then the response status should be "200"
    And the JSON response should be an array with 20 "licenses"

  Scenario: Admin retrieves all licenses with a limit that is too high
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "licenses"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses?limit=900"
    Then the response status should be "400"

  Scenario: Admin retrieves all licenses with a limit that is too low
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "licenses"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses?limit=-900"
    Then the response status should be "400"

  Scenario: Admin retrieves all suspended licenses
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 10 "licenses"
    And the first "license" has the following attributes:
      """
      { "suspended": true }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses?suspended=true"
    Then the response status should be "200"
    And the JSON response should be an array with 1 "license"

  Scenario: Admin retrieves all non-suspended licenses
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 10 "licenses"
    And the first "license" has the following attributes:
      """
      { "suspended": true }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses?suspended=false"
    Then the response status should be "200"
    And the JSON response should be an array with 9 "licenses"

  Scenario: Admin retrieves all expired licenses
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 10 "licenses"
    And the first "license" has the following attributes:
      """
      { "expiry": "$time.1.hour.ago" }
      """
    And the second "license" has the following attributes:
      """
      { "expiry": null }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses?expired=true"
    Then the response status should be "200"
    And the JSON response should be an array with 1 "license"

  Scenario: Admin retrieves all non-expired licenses
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 10 "licenses"
    And the first "license" has the following attributes:
      """
      { "expiry": "$time.1.hour.ago" }
      """
    And the second "license" has the following attributes:
      """
      { "expiry": null }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses?expired=false"
    Then the response status should be "200"
    And the JSON response should be an array with 9 "licenses"

  Scenario: Product retrieves all licenses for their product
    Given the current account is "test1"
    And the current account has 1 "product"
    And I am a product of account "test1"
    And I use an authentication token
    And the current account has 3 "licenses"
    And the current product has 1 "license"
    When I send a GET request to "/accounts/test1/licenses"
    Then the response status should be "200"
    And the JSON response should be an array with 1 "license"

  Scenario: Admin attempts to retrieve all licenses for another account
    Given I am an admin of account "test2"
    But the current account is "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses"
    Then the response status should be "401"
    And the JSON response should be an array of 1 error

  Scenario: User attempts to retrieve all licenses for their account
    Given the current account is "test1"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    And the current account has 3 "licenses"
    And the current user has 1 "license"
    When I send a GET request to "/accounts/test1/licenses"
    Then the response status should be "200"
    And the JSON response should be an array with 1 "license"
