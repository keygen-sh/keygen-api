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

  Scenario: Admin retrieves a paginated list of machines for a license
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
    And the JSON response should be an array with 2 "machines"
    And the JSON response should contain the following links:
      """
      {
        "self": "/v1/accounts/test1/licenses/$licenses[0]/machines?page[number]=1&page[size]=5",
        "prev": "/v1/accounts/test1/licenses/$licenses[0]/machines?page[number]=1&page[size]=5",
        "next": "/v1/accounts/test1/licenses/$licenses[0]/machines?page[number]=1&page[size]=5",
        "first": "/v1/accounts/test1/licenses/$licenses[0]/machines?page[number]=1&page[size]=5",
        "last": "/v1/accounts/test1/licenses/$licenses[0]/machines?page[number]=1&page[size]=5"
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
    And the JSON response should be an array with 3 "machines"

  Scenario: Product retrieves the machines for a license
    Given the current account is "test1"
    And the current account has 1 "license"
    And the current account has 3 "machines"
    And all "machines" have the following attributes:
      """
      { "licenseId": "$licenses[0]" }
      """
    And the current account has 1 "product"
    And I am a product of account "test1"
    And the current product has 1 "license"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0/machines"
    Then the response status should be "200"
    And the JSON response should be an array with 3 "machines"

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
    And the JSON response should be a "machine"

  Scenario: Product retrieves a machine for a license
    Given the current account is "test1"
    And the current account has 1 "license"
    And the current account has 3 "machines"
    And all "machines" have the following attributes:
      """
      { "licenseId": "$licenses[0]" }
      """
    And the current account has 1 "product"
    And I am a product of account "test1"
    And the current product has 1 "license"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0/machines/$0"
    Then the response status should be "200"
    And the JSON response should be a "machine"

  Scenario: Product retrieves the machines for a license of another product
    Given the current account is "test1"
    And the current account has 1 "license"
    And the current account has 3 "machines"
    And all "machines" have the following attributes:
      """
      { "licenseId": "$licenses[0]" }
      """
    And the current account has 1 "product"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0/machines"
    Then the response status should be "403"

  Scenario: User attempts to retrieve the machines for a license
    Given the current account is "test1"
    And the current account has 1 "license"
    And the current account has 3 "machines"
    And all "machines" have the following attributes:
      """
      { "licenseId": "$licenses[0]" }
      """
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0/machines"
    Then the response status should be "403"

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
