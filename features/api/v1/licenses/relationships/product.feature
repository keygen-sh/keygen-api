@api/v1
Feature: License product relationship

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
    When I send a GET request to "/accounts/test1/licenses/$0/product"
    Then the response status should be "403"

  Scenario: Admin retrieves the product for a license
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 3 "licenses"
     And the first "license" has the following attributes:
      """
      { "key": "test-key" }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/test-key/product"
    Then the response status should be "200"
    And the JSON response should be a "product"
    And the response should contain a valid signature header for "test1"

  Scenario: Product retrieves the product for a license
    Given the current account is "test1"
    And the current account has 3 "licenses"
    And the current account has 1 "product"
    And I am a product of account "test1"
    And the current product has 3 "licenses"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0/product"
    Then the response status should be "200"
    And the JSON response should be a "product"

  Scenario: Product retrieves the product for a license of another product
    Given the current account is "test1"
    And the current account has 3 "licenses"
    And the current account has 1 "product"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0/product"
    Then the response status should be "403"

  Scenario: User attempts to retrieve the product for a license
    Given the current account is "test1"
    And the current account has 3 "licenses"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0/product"
    Then the response status should be "403"

  Scenario: Admin attempts to retrieve the product for a license of another account
    Given I am an admin of account "test2"
    And the current account is "test1"
    And the current account has 3 "licenses"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0/product"
    Then the response status should be "401"
