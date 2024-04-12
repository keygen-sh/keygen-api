@api/v1
Feature: Release product relationship

  Background:
    Given the following "accounts" exist:
      | name    | slug  |
      | Test 1  | test1 |
      | Test 2  | test2 |
    And I send and accept JSON

  Scenario: Endpoint should be inaccessible when account is disabled
    Given the account "test1" is canceled
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "release"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$0/product"
    Then the response status should be "403"

  Scenario: Admin retrieves the product for a release
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 3 "releases"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$0/product"
    Then the response status should be "200"
    And the response body should be a "product"

  @ee
  Scenario: Environment retrieves the product for an isolated release
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And the current account has 3 isolated "releases"
    And I am an environment of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$0/product?environment=isolated"
    Then the response status should be "200"
    And the response body should be a "product"

  Scenario: Product retrieves the product for a release
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 3 "releases" for the last "product"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$0/product"
    Then the response status should be "200"
    And the response body should be a "product"

  Scenario: Product retrieves the product for a release of another product
    Given the current account is "test1"
    And the current account has 2 "products"
    And the current account has 1 "release"
    And all "releases" have the following attributes:
      """
      { "productId": "$products[1]" }
      """
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$0/product"
    Then the response status should be "404"

  Scenario: User attempts to retrieve the product for a release
    Given the current account is "test1"
    And the current account has 3 "releases"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$0/product"
    Then the response status should be "404"

  Scenario: Admin attempts to retrieve the product for a release of another account
    Given I am an admin of account "test2"
    And the current account is "test1"
    And the current account has 3 "releases"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$0/product"
    Then the response status should be "401"
