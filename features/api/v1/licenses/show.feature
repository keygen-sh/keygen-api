@api/v1
Feature: Show license

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
    And the current account has 1 "license"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0"
    Then the response status should be "403"

  Scenario: Admin retrieves a license for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 3 "licenses"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0"
    Then the response status should be "200"
    And the JSON response should be a "license"

  Scenario: Admin retrieves a license for their account with correct relationship data
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 3 "licenses"
    And the current account has 21 "machines"
    And all "machines" have the following attributes:
      """
      { "licenseId": "$licenses[0]" }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0"
    Then the response status should be "200"
    And the JSON response should be a "license" with the following relationships:
      """
      {
        "machines": {
          "links": { "related": "/v1/accounts/$accounts[0]/licenses/$licenses[0]/machines" },
          "meta": { "count": 21 }
        }
      }
      """

  Scenario: Admin retrieves an invalid license for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/invalid"
    Then the response status should be "404"

  Scenario: Admin retrieves an encrypted license for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 3 encrypted "licenses"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0"
    Then the response status should be "200"
    And the JSON response should be a "license" with a nil key

  Scenario: Product retrieves a license for their product
    Given the current account is "test1"
    And the current account has 1 "product"
    And I am a product of account "test1"
    And I use an authentication token
    And the current account has 1 "license"
    And the current product has 1 "license"
    When I send a GET request to "/accounts/test1/licenses/$0"
    Then the response status should be "200"
    And the JSON response should be a "license"

  Scenario: Product attempts to retrieve a license for another product
    Given the current account is "test1"
    And the current account has 1 "product"
    And I am a product of account "test1"
    And I use an authentication token
    And the current account has 1 "license"
    When I send a GET request to "/accounts/test1/licenses/$0"
    Then the response status should be "403"

  Scenario: Admin attempts to retrieve a license for another account
    Given I am an admin of account "test2"
    But the current account is "test1"
    And the account "test1" has 3 "licenses"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0"
    Then the response status should be "401"
    And the JSON response should be an array of 1 error
