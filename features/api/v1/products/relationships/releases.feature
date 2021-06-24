@api/v1
Feature: Product releases relationship

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
    And the current account has 1 "product"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products/$0/releases"
    Then the response status should be "403"

  Scenario: Admin retrieves the releases for a product
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "product"
    And the current account has 3 "releases"
    And all "releases" have the following attributes:
      """
      { "productId": "$products[0]" }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products/$0/releases"
    Then the response status should be "200"
    And the JSON response should be an array with 3 "releases"

  Scenario: Product retrieves the releases for a product
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 3 "releases"
    And all "releases" have the following attributes:
      """
      { "productId": "$products[0]" }
      """
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products/$0/releases"
    Then the response status should be "200"
    And the JSON response should be an array with 3 "releases"

  Scenario: Admin retrieves a release for a product
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "release"
    And all "releases" have the following attributes:
      """
      { "productId": "$products[0]" }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products/$0/releases/$0"
    Then the response status should be "200"
    And the JSON response should be a "release"

  Scenario: Product retrieves a release for a product
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "release"
    And all "releases" have the following attributes:
      """
      { "productId": "$products[0]" }
      """
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products/$0/releases/$0"
    Then the response status should be "200"
    And the JSON response should be a "release"

  Scenario: Product retrieves the releases of another product
    Given the current account is "test1"
    And the current account has 2 "products"
    And the current account has 1 "release"
    And all "releases" have the following attributes:
      """
      { "productId": "$products[1]" }
      """
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products/$1/releases"
    Then the response status should be "403"

  Scenario: User attempts to retrieve the releases for a product
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "release"
    And all "releases" have the following attributes:
      """
      { "productId": "$products[0]" }
      """
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products/$0/releases"
    Then the response status should be "403"

  Scenario: Admin attempts to retrieve the releases for a product of another account
    Given I am an admin of account "test2"
    And the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "release"
    And all "releases" have the following attributes:
      """
      { "productId": "$products[0]" }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products/$0/releases"
    Then the response status should be "401"
