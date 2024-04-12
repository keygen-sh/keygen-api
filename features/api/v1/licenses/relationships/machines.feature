@api/v1
Feature: License machines relationship

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
    When I send a GET request to "/accounts/test1/licenses/$0/machines"
    Then the response status should be "403"

  Scenario: Admin retrieves a paginated list of machines for a license with no other pages
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "license"
    And the first "license" has the following attributes:
      """
      { "key": "test-key" }
      """
    And the current account has 2 "machines"
    And all "machines" have the following attributes:
      """
      { "licenseId": "$licenses[0]" }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0/machines?page[number]=1&page[size]=5"
    Then the response status should be "200"
    And the response body should be an array with 2 "machines"
    And the response body should contain the following links:
      """
      {
        "self": "/v1/accounts/test1/licenses/$licenses[0]/machines?page[number]=1&page[size]=5",
        "prev": null,
        "next": null,
        "first": "/v1/accounts/test1/licenses/$licenses[0]/machines?page[number]=1&page[size]=5",
        "last": "/v1/accounts/test1/licenses/$licenses[0]/machines?page[number]=1&page[size]=5",
        "meta": {
          "pages": 1,
          "count": 2
        }
      }
      """
    And the response should contain a valid signature header for "test1"

  Scenario: Admin retrieves a paginated list of machines for a license with other pages
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "license"
    And the first "license" has the following attributes:
      """
      { "key": "test-key" }
      """
    And the current account has 20 "machines"
    And all "machines" have the following attributes:
      """
      { "licenseId": "$licenses[0]" }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0/machines?page[number]=1&page[size]=5"
    Then the response status should be "200"
    And the response body should be an array with 5 "machines"
    And the response body should contain the following links:
      """
      {
        "self": "/v1/accounts/test1/licenses/$licenses[0]/machines?page[number]=1&page[size]=5",
        "prev": null,
        "next": "/v1/accounts/test1/licenses/$licenses[0]/machines?page[number]=2&page[size]=5",
        "first": "/v1/accounts/test1/licenses/$licenses[0]/machines?page[number]=1&page[size]=5",
        "last": "/v1/accounts/test1/licenses/$licenses[0]/machines?page[number]=4&page[size]=5",
        "meta": {
          "pages": 4,
          "count": 20
        }
      }
      """

  Scenario: Admin retrieves the machines for a license
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "license"
    And the first "license" has the following attributes:
      """
      { "key": "test-key" }
      """
    And the current account has 3 "machines"
    And all "machines" have the following attributes:
      """
      { "licenseId": "$licenses[0]" }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/test-key/machines"
    Then the response status should be "200"
    And the response body should be an array with 3 "machines"

  @ee
  Scenario: Environment retrieves the machines for an isolated license
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And the current account has 1 isolated "license"
    And the current account has 3 isolated "machines" for the last "license"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    When I send a GET request to "/accounts/test1/licenses/$0/machines"
    Then the response status should be "200"
    And the response body should be an array with 3 "machines"

  Scenario: Product retrieves the machines for a license
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "license" for the last "policy"
    And the current account has 3 "machines" for the last "license"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0/machines"
    Then the response status should be "200"
    And the response body should be an array with 3 "machines"

  Scenario: Admin retrieves a machine for a license
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "license"
    And the current account has 3 "machines"
    And all "machines" have the following attributes:
      """
      { "licenseId": "$licenses[0]" }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0/machines/$0"
    Then the response status should be "200"
    And the response body should be a "machine"

  Scenario: Product retrieves a machine for a license
    Given the current account is "test1"
    And the current account has 2 "products"
    And the current account has 1 "policy" for the first "product"
    And the current account has 1 "license" for the first "policy"
    And the current account has 3 "machines" for the first "license"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0/machines/$0"
    Then the response status should be "200"
    And the response body should be a "machine"

  Scenario: Product retrieves the machines for a license of another product
    Given the current account is "test1"
    And the current account has 2 "products"
    And the current account has 1 "policy"
    And all "policies" have the following attributes:
      """
      { "productId": "$products[1]" }
      """
    And the current account has 1 "license"
    And all "licenses" have the following attributes:
      """
      { "policyId": "$policies[0]" }
      """
    And the current account has 3 "machines"
    And all "machines" have the following attributes:
      """
      { "licenseId": "$licenses[0]" }
      """
    And the current account has 1 "product"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0/machines"
    Then the response status should be "404"

  Scenario: User attempts to retrieve the machines for a license they own
    Given the current account is "test1"
    And the current account has 1 "license"
    And the current account has 3 "machines"
    And all "machines" have the following attributes:
      """
      { "licenseId": "$licenses[0]" }
      """
    And the current account has 1 "user"
    And I am a user of account "test1"
    And the current user has 1 "license"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0/machines"
    Then the response status should be "200"

  Scenario: User attempts to retrieve the machines for a license they don't own
    Given the current account is "test1"
    And the current account has 3 "users"
    And the current account has 1 "license"
    And all "licenses" have the following attributes:
      """
      { "userId": "$users[3]" }
      """
    And the current account has 3 "machines"
    And all "machines" have the following attributes:
      """
      { "licenseId": "$licenses[0]" }
      """
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0/machines"
    Then the response status should be "404"

  Scenario: Admin attempts to retrieve the machines for a license of another account
    Given I am an admin of account "test2"
    And the current account is "test1"
    And the current account has 1 "license"
    And the current account has 3 "machines"
    And all "machines" have the following attributes:
      """
      { "licenseId": "$licenses[0]" }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0/machines"
    Then the response status should be "401"

  @ee
  Scenario: Environment retrieves an isolated machine for an isolated license
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And the current account has 1 isolated "license"
    And the current account has 3 isolated "machines" for the last "license"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    When I send a GET request to "/accounts/test1/licenses/$0/machines/$0"
    Then the response status should be "200"
    And the response body should be a "machine"

  @ee
  Scenario: Environment retrieves a shared machine for a shared license
    Given the current account is "test1"
    And the current account has 1 shared "environment"
    And the current account has 1 shared "license"
    And the current account has 3 shared "machines" for the last "license"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
    When I send a GET request to "/accounts/test1/licenses/$0/machines/$0"
    Then the response status should be "200"
    And the response body should be a "machine"

  @ee
  Scenario: Environment retrieves a shared machine for a global license
    Given the current account is "test1"
    And the current account has 1 shared "environment"
    And the current account has 1 global "license"
    And the current account has 3 shared "machines" for the last "license"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
    When I send a GET request to "/accounts/test1/licenses/$0/machines/$0"
    Then the response status should be "200"
    And the response body should be a "machine"
