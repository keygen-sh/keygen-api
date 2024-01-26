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
    And the response body should be an array of 11 "tokens"

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
    And the response body should be an array of 1 "token"

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
    And the response body should be an array of 1 "token"

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
    And the response body should be an array of 1 "token"

  @ee
  Scenario: Isolated environment requests their tokens while authenticated
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And the current account has 1 isolated "admin"
    And the current account has 1 isolated "token" for each "environment"
    And the current account has 2 isolated "products"
    And the current account has 1 isolated "token" for each "product"
    And the current account has 2 isolated "users"
    And the current account has 1 isolated "token" for each "user"
    And the current account has 2 isolated "licenses"
    And the current account has 1 isolated "token" for each "license"
    And I am an environment of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/tokens?environment=isolated"
    Then the response status should be "200"
    And the response body should be an array of 7 "tokens"

  @ee
  Scenario: Shared environment requests their tokens while authenticated
    Given the current account is "test1"
    And the current account has 1 shared "environment"
    And the current account has 1 shared "admin"
    And the current account has 1 shared "token" for each "environment"
    And the current account has 2 shared "products"
    And the current account has 1 shared "token" for each "product"
    And the current account has 2 shared "users"
    And the current account has 1 shared "token" for each "user"
    And the current account has 2 shared "licenses"
    And the current account has 1 shared "token" for each "license"
    And I am an environment of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/tokens?environment=shared"
    Then the response status should be "200"
    And the response body should be an array of 7 "tokens"

  Scenario: Product requests their tokens while authenticated
    Given the current account is "test1"
    And the current account has 3 "products"
    And the current account has 1 "token" for each "product"
    And the current account has 5 "users"
    And the current account has 1 "token" for each "user"
    And the current account has 1 "policy" for the last "product"
    And the current account has 2 "licenses" for the last "policy"
    And the first "license" has the following attributes:
      """
      { "userId": "$users[3]" }
      """
    And the current account has 1 "token" for each "license"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/tokens"
    Then the response status should be "200"
    And the response body should be an array of 1 "token"

  Scenario: Product requests all tokens for a specific license
    Given the current account is "test1"
    And the current account has 3 "products"
    And the current account has 1 "token" for each "product"
    And the current account has 1 "policy" for the first "product"
    And the current account has 2 "licenses" for the last "policy"
    And the current account has 2 "tokens" for each "license"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/tokens?bearer[type]=license&bearer[id]=$licenses[0]"
    Then the response status should be "200"
    And the response body should be an array of 2 "tokens"

  Scenario: Product requests all tokens for a specific user
    Given the current account is "test1"
    And the current account has 3 "products"
    And the current account has 1 "token" for each "product"
    And the current account has 1 "policy" for the first "product"
    And the current account has 2 "licenses" for the last "policy"
    And the current account has 2 "users"
    And the current account has 2 "tokens" for each "user"
    And the last "license" is associated to the last "user" as "owner"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/tokens?bearer[type]=user&bearer[id]=$users[2]"
    Then the response status should be "200"
    And the response body should be an array of 2 "tokens"

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
    And the response body should be an array of 1 "token"

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
    And the response body should be an array of 0 "tokens"

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
    And the response body should be an array of 1 "token"

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
    And the response body should be an array of 0 "tokens"

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
    And the response body should be an array of 0 "tokens"

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
    And the response body should be an array of 0 "tokens"

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
