@api/v1
Feature: Show release platform

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
    When I send a GET request to "/accounts/test1/platforms/$0"
    Then the response status should be "403"

  Scenario: Admin retrieves a platform for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 3 "releases"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/platforms/$0"
    Then the response status should be "200"
    And the JSON response should be a "platform"

  Scenario: Developer retrieves a platform for their account
    Given the current account is "test1"
    And the current account has 1 "developer"
    And I am a developer of account "test1"
    And the current account has 3 "releases"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/platforms/$0"
    Then the response status should be "200"

  Scenario: Sales retrieves a platform for their account
    Given the current account is "test1"
    And the current account has 1 "sales-agent"
    And I am a sales agent of account "test1"
    And the current account has 3 "releases"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/platforms/$0"
    Then the response status should be "200"

  Scenario: Support retrieves a platform for their account
    Given the current account is "test1"
    And the current account has 1 "support-agent"
    And I am a support agent of account "test1"
    And the current account has 3 "releases"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/platforms/$0"
    Then the response status should be "200"

  Scenario: Admin retrieves an invalid platform for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/platforms/invalid"
    Then the response status should be "404"
    And the first error should have the following properties:
      """
      {
        "title": "Not found",
        "detail": "The requested release platform 'invalid' was not found"
      }
      """

  Scenario: Product retrieves a platform for their product
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "release"
    And I am a product of account "test1"
    And I use an authentication token
    And the current product has 1 "release"
    When I send a GET request to "/accounts/test1/platforms/$0"
    Then the response status should be "200"
    And the JSON response should be a "platform"

  Scenario: Product retrieves a platform for another product
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "release"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/platforms/$0"
    Then the response status should be "404"

  Scenario: User retrieves a platform without a license for it
    Given the current account is "test1"
    And the current account has 1 "user"
    And the current account has 1 "release"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/platforms/$0"
    Then the response status should be "404"

  Scenario: User retrieves a platform with a license for it
    Given the current account is "test1"
    And the current account has 1 "user"
    And the current account has 1 "product"
    And the current account has 1 "release" for an existing "product"
    And the current account has 1 "policy" for an existing "product"
    And the current account has 1 "license" for an existing "policy"
    And I am a user of account "test1"
    And I use an authentication token
    And the current user has 1 "license"
    When I send a GET request to "/accounts/test1/platforms/$0"
    Then the response status should be "200"

  Scenario: License retrieves a platform of a different product
    Given the current account is "test1"
    And the current account has 1 "license"
    And the current account has 1 "release"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/platforms/$0"
    Then the response status should be "404"

  Scenario: License retrieves a platform of their product
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "release" for an existing "product"
    And the current account has 1 "policy" for an existing "product"
    And the current account has 1 "license" for an existing "policy"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/platforms/$0"
    Then the response status should be "200"

  Scenario: Anonymous retrieves a platform
    Given the current account is "test1"
    And the current account has 1 "release"
    When I send a GET request to "/accounts/test1/platforms/$0"
    Then the response status should be "401"

  Scenario: Admin attempts to retrieve a platform for another account
    Given I am an admin of account "test2"
    But the current account is "test1"
    And the account "test1" has 3 "releases"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/platforms/$0"
    Then the response status should be "401"
    And the JSON response should be an array of 1 error
