@api/v1
Feature: Show machine

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
    And the current account has 1 "machine"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/machines/$0"
    Then the response status should be "403"

  Scenario: Admin retrieves a machine for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 3 "machines"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/machines/$0"
    Then the response status should be "200"
    And the JSON response should be a "machine"
    And the response should contain a valid signature header for "test1"

  Scenario: Admin retrieves a license for their account that has a user
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "user"
    And the current account has 1 "license"
    And the first "license" has the following attributes:
      """
      { "userId": "$users[1]" }
      """
    And the current account has 3 "machines"
    And all "machines" have the following attributes:
      """
      { "licenseId": "$licenses[0]" }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/machines/$0"
    Then the response status should be "200"
    And the JSON response should be a "machine"
    And the response should contain a valid signature header for "test1"
    And the JSON response should be a "machine" with the following relationships:
      """
      {
        "user": {
          "links": { "related": "/v1/accounts/$account/machines/$machines[0]/user" },
          "data": { "type": "users", "id": "$users[1]" }
        }
      }
      """

  Scenario: Admin retrieves a license for their account that doesn't have a user
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "license"
    And the first "license" has the following attributes:
      """
      { "userId": null }
      """
    And the current account has 1 "machine"
    And the first "machine" has the following attributes:
      """
      { "licenseId": "$licenses[0]" }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/machines/$0"
    Then the response status should be "200"
    And the JSON response should be a "machine"
    And the response should contain a valid signature header for "test1"
    And the JSON response should be a "machine" with the following relationships:
      """
      {
        "user": {
          "links": { "related": "/v1/accounts/$account/machines/$machines[0]/user" },
          "data": null
        }
      }
      """

  Scenario: Admin retrieves an invalid machine for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/machines/invalid"
    Then the response status should be "404"
    And the first error should have the following properties:
      """
      {
        "title": "Not found",
        "detail": "The requested machine 'invalid' was not found"
      }
      """

  Scenario: Product retrieves a machine for their product
    Given the current account is "test1"
    And the current account has 1 "product"
    And I am a product of account "test1"
    And I use an authentication token
    And the current account has 1 "machine"
    And the current product has 1 "machine"
    When I send a GET request to "/accounts/test1/machines/$0"
    Then the response status should be "200"
    And the JSON response should be a "machine"

  Scenario: User retrieves a machine for their license
    Given the current account is "test1"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    And the current account has 1 "machine"
    And the current user has 1 "machine"
    When I send a GET request to "/accounts/test1/machines/$0"
    Then the response status should be "200"
    And the JSON response should be a "machine"

  Scenario: License retrieves a machine for their license
    Given the current account is "test1"
    And the current account has 1 "license"
    And the current account has 1 "machine"
    And all "machines" have the following attributes:
      """
      { "licenseId": "$licenses[0]" }
      """
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/machines/$0"
    Then the response status should be "200"
    And the JSON response should be a "machine"

  Scenario: License retrieves a machine for another license
    Given the current account is "test1"
    And the current account has 2 "licenses"
    And the current account has 1 "machine"
    And all "machines" have the following attributes:
      """
      { "licenseId": "$licenses[1]" }
      """
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/machines/$0"
    Then the response status should be "403"

  Scenario: Product attempts to retrieve a machine for another product
    Given the current account is "test1"
    And the current account has 1 "product"
    And I am a product of account "test1"
    And I use an authentication token
    And the current account has 1 "machine"
    When I send a GET request to "/accounts/test1/machines/$0"
    Then the response status should be "403"

  Scenario: Admin attempts to retrieve a machine for another account
    Given I am an admin of account "test2"
    But the current account is "test1"
    And the account "test1" has 3 "machines"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/machines/$0"
    Then the response status should be "401"
    And the JSON response should be an array of 1 error
