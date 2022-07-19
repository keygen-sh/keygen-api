@api/v1
Feature: List authentication tokens

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
    And I use an authentication token
    When I send a GET request to "/accounts/test1/tokens"
    Then the response status should be "403"

  Scenario: Admin requests all tokens while authenticated
    Given the current account is "test1"
    And the current account has 3 "products"
    And the current account has 1 "token" for each "product"
    And the current account has 5 "users"
    And the current account has 1 "token" for each "user"
    And the current account has 2 "licenses"
    And the current account has 1 "token" for each "license"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/tokens?limit=100"
    Then the response status should be "200"
    And the JSON response should be an array of 11 "tokens"

  Scenario: Admin requests all tokens for a specific user
    Given the current account is "test1"
    And I am an admin of account "test1"
    And the current account has 3 "products"
    And the current account has 1 "token" for each "product"
    And the current account has 5 "users"
    And the current account has 1 "token" for each "user"
    And the current account has 2 "licenses"
    And the current account has 1 "token" for each "license"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/tokens?bearer[type]=user&bearer[id]=$users[3]"
    Then the response status should be "200"
    And the JSON response should be an array of 1 "token"

  Scenario: Admin requests all tokens for a specific product
    Given the current account is "test1"
    And I am an admin of account "test1"
    And the current account has 3 "products"
    And the current account has 1 "token" for each "product"
    And the current account has 5 "users"
    And the current account has 1 "token" for each "user"
    And the current account has 2 "licenses"
    And the current account has 1 "token" for each "license"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/tokens?bearer[type]=product&bearer[id]=$products[1]"
    Then the response status should be "200"
    And the JSON response should be an array of 1 "token"

  Scenario: Admin requests all tokens for a specific license
    Given the current account is "test1"
    And I am an admin of account "test1"
    And the current account has 3 "products"
    And the current account has 1 "token" for each "product"
    And the current account has 5 "users"
    And the current account has 1 "token" for each "user"
    And the current account has 2 "licenses"
    And the current account has 1 "token" for each "license"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/tokens?bearer[type]=license&bearer[id]=$licenses[0]"
    Then the response status should be "200"
    And the JSON response should be an array of 1 "token"

  Scenario: Product requests their tokens while authenticated
    Given the current account is "test1"
    And the current account has 3 "products"
    And the current account has 1 "token" for each "product"
    And the current account has 5 "users"
    And the current account has 1 "token" for each "user"
    And the current account has 2 "licenses"
    And the current account has 1 "token" for each "license"
    And I am a product of account "test1"
    And the current product has 2 "users"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/tokens"
    Then the response status should be "200"
    And the JSON response should be an array of 1 "token"

  Scenario: License requests their tokens while authenticated
    Given the current account is "test1"
    And the current account has 3 "products"
    And the current account has 1 "token" for each "product"
    And the current account has 5 "users"
    And the current account has 1 "token" for each "user"
    And the current account has 2 "licenses"
    And the current account has 1 "token" for each "license"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/tokens"
    Then the response status should be "200"
    And the JSON response should be an array of 1 "token"

  Scenario: License requests tokens for another license
    Given the current account is "test1"
    And the current account has 3 "products"
    And the current account has 1 "token" for each "product"
    And the current account has 5 "users"
    And the current account has 1 "token" for each "user"
    And the current account has 2 "licenses"
    And the current account has 1 "token" for each "license"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/tokens?bearer[type]=license&bearer[id]=$licenses[1]"
    Then the response status should be "200"
    And the JSON response should be an array of 0 "tokens"

  Scenario: User requests their tokens while authenticated
    Given the current account is "test1"
    And the current account has 3 "products"
    And the current account has 1 "token" for each "product"
    And the current account has 5 "users"
    And the current account has 1 "token" for each "user"
    And the current account has 2 "licenses"
    And the current account has 1 "token" for each "license"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/tokens"
    Then the response status should be "200"
    And the JSON response should be an array of 1 "token"

  Scenario: User requests another user's tokens
    Given the current account is "test1"
    And the current account has 3 "products"
    And the current account has 1 "token" for each "product"
    And the current account has 5 "users"
    And the current account has 1 "token" for each "user"
    And the current account has 2 "licenses"
    And the current account has 1 "token" for each "license"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/tokens?bearer[type]=user&bearer[id]=$users[0]"
    And the JSON response should be an array of 0 "tokens"

  Scenario: User requests a product's tokens
    Given the current account is "test1"
    And the current account has 3 "products"
    And the current account has 1 "token" for each "product"
    And the current account has 5 "users"
    And the current account has 1 "token" for each "user"
    And the current account has 2 "licenses"
    And the current account has 1 "token" for each "license"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/tokens?bearer[type]=product&bearer[id]=$products[0]"
    And the JSON response should be an array of 0 "tokens"

  Scenario: User requests a license's tokens
    Given the current account is "test1"
    And the current account has 3 "products"
    And the current account has 1 "token" for each "product"
    And the current account has 5 "users"
    And the current account has 1 "token" for each "user"
    And the current account has 2 "licenses"
    And the current account has 1 "token" for each "license"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/tokens?bearer[type]=license&bearer[id]=$licenses[1]"
    And the JSON response should be an array of 0 "tokens"

  Scenario: Anonymous requests a user's tokens
    Given the current account is "test1"
    And the current account has 3 "products"
    And the current account has 1 "token" for each "product"
    And the current account has 5 "users"
    And the current account has 1 "token" for each "user"
    And the current account has 2 "licenses"
    And the current account has 1 "token" for each "license"
    And I am a user of account "test1"
    When I send a GET request to "/accounts/test1/tokens"
    Then the response status should be "401"
