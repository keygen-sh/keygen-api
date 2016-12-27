@api/v1
Feature: Product policies relationship

  Background:
    Given the following "accounts" exist:
      | Name    | Slug  |
      | Test 1  | test1 |
      | Test 2  | test2 |
    And I send and accept JSON

  Scenario: Admin retrieves the policies for a product
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "product"
    And the current account has 3 "policies"
    And all "policies" have the following attributes:
      """
      { "productId": "$products[0]" }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products/$0/policies"
    Then the response status should be "200"
    And the JSON response should be an array with 3 "policies"

  Scenario: Product retrieves the policies for a product
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 3 "policies"
    And all "policies" have the following attributes:
      """
      { "productId": "$products[0]" }
      """
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products/$0/policies"
    Then the response status should be "200"
    And the JSON response should be an array with 3 "policies"

  Scenario: Admin retrieves a policy for a product
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "policy"
    And all "policies" have the following attributes:
      """
      { "productId": "$products[0]" }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products/$0/policies/$0"
    Then the response status should be "200"
    And the JSON response should be a "policy"

  Scenario: Product retrieves a policy for a product
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "policy"
    And all "policies" have the following attributes:
      """
      { "productId": "$products[0]" }
      """
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products/$0/policies/$0"
    Then the response status should be "200"
    And the JSON response should be a "policy"

  Scenario: Product retrieves the policies of another product
    Given the current account is "test1"
    And the current account has 2 "products"
    And the current account has 1 "policy"
    And all "policies" have the following attributes:
      """
      { "productId": "$products[1]" }
      """
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products/$1/policies"
    Then the response status should be "403"

  Scenario: User attempts to retrieve the policies for a product
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "policy"
    And all "policies" have the following attributes:
      """
      { "productId": "$products[0]" }
      """
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products/$0/policies"
    Then the response status should be "403"

  Scenario: Admin attempts to retrieve the policies for a product of another account
    Given I am an admin of account "test2"
    And the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "policy"
    And all "policies" have the following attributes:
      """
      { "productId": "$products[0]" }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products/$0/policies"
    Then the response status should be "401"
