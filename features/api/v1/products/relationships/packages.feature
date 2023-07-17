@api/v1
Feature: Product package relationship
  Background:
    Given the following "accounts" exist:
      | name    | slug  |
      | Test 1  | test1 |
      | Test 2  | test2 |
    And I send and accept JSON

  # List
  Scenario: Endpoint should be inaccessible when account is disabled
    Given the account "test1" is canceled
    And the current account is "test1"
    And the current account has 1 "product"
    And the current account has 3 "packages" for the last "product"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products/$0/packages"
    Then the response status should be "403"

  Scenario: Admin lists all packages for a product
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 3 "packages" for the last "product"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products/$0/packages"
    Then the response status should be "200"
    And the response body should be an array with 3 "packages"

  @ee
  Scenario: Environment lists all packages for a shared product
    Given the current account is "test1"
    And the current account has 1 shared "environment"
    And the current account has 1 shared "product"
    And the current account has 3 shared "packages" for the last "product"
    And I am an environment of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products/$0/packages?environment=shared"
    Then the response status should be "200"
    And the response body should be an array with 3 "packages"

  Scenario: Product lists all packages for themself
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 3 "packages" for the last "product"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products/$0/packages"
    Then the response status should be "200"
    And the response body should be an array with 3 "package"

  Scenario: Product lists all packages for another product
    Given the current account is "test1"
    And the current account has 2 "products"
    And the current account has 1 "package" for the second "product"
    And I am the first product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products/$1/packages"
    Then the response status should be "404"

  Scenario: License lists all packages for their product
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 3 "packages" for the last "product"
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "license" for the last "policy"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products/$0/packages"
    Then the response status should be "200"
    And the response body should be an array with 3 "packages"

  Scenario: License lists all packages for another product
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "package" for the last "product"
    And the current account has 1 "license"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products/$0/packages"
    Then the response status should be "404"

  Scenario: User lists all packages for another product
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 3 "packages" for the last "product"
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "license" for the last "policy"
    And the current account has 1 "user"
    And the last "license" belongs to the last "user"
    And I am the last user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products/$0/packages"
    Then the response status should be "200"
    And the response body should be an array with 3 "packages"

  Scenario: User lists all packages for another product
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "package" for the last "product"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products/$0/packages"
    Then the response status should be "404"

  Scenario: Anonymous lists all packages for a licensed product
    Given the current account is "test1"
    And the current account has 1 licensed "product"
    And the current account has 1 "package" for the last "product"
    When I send a GET request to "/accounts/test1/products/$0/packages"
    Then the response status should be "401"

  Scenario: Anonymous lists all packages for a closed product
    Given the current account is "test1"
    And the current account has 1 closed "product"
    And the current account has 1 "package" for the last "product"
    When I send a GET request to "/accounts/test1/products/$0/packages"
    Then the response status should be "401"

  Scenario: Anonymous lists all packages for an open product
    Given the current account is "test1"
    And the current account has 1 open "product"
    And the current account has 3 "package" for the last "product"
    When I send a GET request to "/accounts/test1/products/$0/packages"
    Then the response status should be "401"

  Scenario: Admin lists all packages for a product of another account
    Given I am an admin of account "test2"
    But the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "package" for the last "product"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products/$0/packages"
    Then the response status should be "401"

  # Retrieve
  Scenario: Endpoint should be inaccessible when account is disabled
    Given the account "test1" is canceled
    And the current account is "test1"
    And the current account has 1 "product"
    And the current account has 3 "packages" for the last "product"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products/$0/packages/$0"
    Then the response status should be "403"

  Scenario: Admin lists all packages for a product
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 3 "packages" for the last "product"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products/$0/packages/$0"
    Then the response status should be "200"
    And the response body should be a "package"

  @ee
  Scenario: Environment lists all packages for an isolated product
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And the current account has 1 isolated "product"
    And the current account has 3 isolated "packages" for the last "product"
    And I am an environment of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products/$0/packages/$0?environment=isolated"
    Then the response status should be "200"
    And the response body should be a "package"

  Scenario: Product lists all packages for themself
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 3 "packages" for the last "product"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products/$0/packages/$0"
    Then the response status should be "200"
    And the response body should be a "package"

  Scenario: Product lists all packages for another product
    Given the current account is "test1"
    And the current account has 2 "products"
    And the current account has 1 "package" for the second "product"
    And I am the first product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products/$1/packages/$0"
    Then the response status should be "404"

  Scenario: License lists all packages for their product
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 3 "packages" for the last "product"
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "license" for the last "policy"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products/$0/packages/$0"
    Then the response status should be "200"
    And the response body should be a "package"

  Scenario: License lists all packages for another product
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "package" for the last "product"
    And the current account has 1 "license"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products/$0/packages/$0"
    Then the response status should be "404"

  Scenario: User lists all packages for another product
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 3 "packages" for the last "product"
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "license" for the last "policy"
    And the current account has 1 "user"
    And the last "license" belongs to the last "user"
    And I am the last user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products/$0/packages/$0"
    Then the response status should be "200"
    And the response body should be a "package"

  Scenario: User lists all packages for another product
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "package" for the last "product"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products/$0/packages/$0"
    Then the response status should be "404"

  Scenario: Anonymous lists all packages for a licensed product
    Given the current account is "test1"
    And the current account has 1 licensed "product"
    And the current account has 1 "package" for the last "product"
    When I send a GET request to "/accounts/test1/products/$0/packages/$0"
    Then the response status should be "401"

  Scenario: Anonymous lists all packages for a closed product
    Given the current account is "test1"
    And the current account has 1 closed "product"
    And the current account has 1 "package" for the last "product"
    When I send a GET request to "/accounts/test1/products/$0/packages/$0"
    Then the response status should be "401"

  Scenario: Anonymous lists all packages for an open product
    Given the current account is "test1"
    And the current account has 1 open "product"
    And the current account has 3 "package" for the last "product"
    When I send a GET request to "/accounts/test1/products/$0/packages/$0"
    Then the response status should be "401"

  Scenario: Admin lists all packages for a product of another account
    Given I am an admin of account "test2"
    But the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "package" for the last "product"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products/$0/packages/$0"
    Then the response status should be "401"