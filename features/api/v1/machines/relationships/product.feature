@api/v1
Feature: Machine product relationship

  Background:
    Given the following "accounts" exist:
      | Name    | Slug  |
      | Test 1  | test1 |
      | Test 2  | test2 |
    And I send and accept JSON

  Scenario: Admin retrieves the product for a machine
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 3 "machines"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/machines/$0/product"
    Then the response status should be "200"
    And the JSON response should be a "product"

  Scenario: Product retrieves the product for a machine
    Given the current account is "test1"
    And the current account has 3 "machines"
    And the current account has 1 "product"
    And I am a product of account "test1"
    And the current product has 3 "machines"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/machines/$0/product"
    Then the response status should be "200"
    And the JSON response should be a "product"

  Scenario: Product retrieves the product for a machine of another product
    Given the current account is "test1"
    And the current account has 3 "machines"
    And the current account has 1 "product"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/machines/$0/product"
    Then the response status should be "403"

  Scenario: User attempts to retrieve the product for a machine
    Given the current account is "test1"
    And the current account has 3 "machines"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/machines/$0/product"
    Then the response status should be "403"

  Scenario: Admin attempts to retrieve the product for a machine of another account
    Given I am an admin of account "test2"
    And the current account is "test1"
    And the current account has 3 "machines"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/machines/$0/product"
    Then the response status should be "401"
