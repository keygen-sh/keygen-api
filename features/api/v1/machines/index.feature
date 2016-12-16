@api/v1
Feature: List machines

  Background:
    Given the following "accounts" exist:
      | Name    | Slug  |
      | Test 1  | test1 |
      | Test 2  | test2 |
    And I send and accept JSON

  Scenario: Admin retrieves all machines for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 3 "machines"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/machines"
    Then the response status should be "200"
    And the JSON response should be an array with 3 "machines"

  Scenario: Admin retrieves a paginated list of machines
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 20 "machines"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/machines?page[number]=2&page[size]=5"
    Then the response status should be "200"
    And the JSON response should be an array with 5 "machines"

  Scenario: Admin retrieves a paginated list of machines with a page size that is too high
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 20 "machines"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/machines?page[number]=1&page[size]=250"
    Then the response status should be "400"

  Scenario: Admin retrieves a paginated list of machines with a page size that is too low
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 20 "machines"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/machines?page[number]=1&page[size]=0"
    Then the response status should be "400"

  Scenario: Admin retrieves a paginated list of machines with an invalid page number
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 20 "machines"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/machines?page[number]=-1&page[size]=10"
    Then the response status should be "400"

  Scenario: Admin retrieves all machines without a limit for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 20 "machines"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/machines"
    Then the response status should be "200"
    And the JSON response should be an array with 10 "machines"

  Scenario: Admin retrieves all machines with a low limit for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 10 "machines"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/machines?limit=5"
    Then the response status should be "200"
    And the JSON response should be an array with 5 "machines"

  Scenario: Admin retrieves all machines with a high limit for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 20 "machines"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/machines?limit=20"
    Then the response status should be "200"
    And the JSON response should be an array with 20 "machines"

  Scenario: Admin retrieves all machines with a limit that is too high
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "machines"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/machines?limit=900"
    Then the response status should be "400"

  Scenario: Admin retrieves all machines with a limit that is too low
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "machines"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/machines?limit=0"
    Then the response status should be "400"

  Scenario: Product retrieves all machines for their product
    Given the current account is "test1"
    And the current account has 1 "product"
    And I am a product of account "test1"
    And I use an authentication token
    And the current account has 3 "machines"
    And the current product has 1 "machine"
    When I send a GET request to "/accounts/test1/machines"
    Then the response status should be "200"
    And the JSON response should be an array with 1 "machine"

  Scenario: Admin attempts to retrieve all machines for another account
    Given I am an admin of account "test2"
    But the current account is "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/machines"
    Then the response status should be "401"
    And the JSON response should be an array of 1 error

  Scenario: User attempts to retrieve all machines for their account
    Given the current account is "test1"
    And the current account has 1 "user"
    And the current account has 1 "license"
    And the first "license" has the following attributes:
      """
      { "userId": "$users[1]" }
      """
    And I am a user of account "test1"
    And the current account has 5 "machines"
    And 3 "machines" have the following attributes:
      """
      { "licenseId": "$licenses[0]" }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/machines"
    Then the response status should be "200"
    And the JSON response should be an array with 3 "machines"

  Scenario: User attempts to retrieve machines for their account scoped by fingerprint
    Given the current account is "test1"
    And the current account has 1 "user"
    And the current account has 1 "license"
    And the first "license" has the following attributes:
      """
      { "userId": "$users[1]" }
      """
    And I am a user of account "test1"
    And the current account has 5 "machines"
    And 5 "machines" have the following attributes:
      """
      { "licenseId": "$licenses[0]" }
      """
    And the third "machine" has the following attributes:
      """
      { "fingerprint": "test" }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/machines?fingerprint=test"
    Then the response status should be "200"
    And the JSON response should be an array with 1 "machine"
