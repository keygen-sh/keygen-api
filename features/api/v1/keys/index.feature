@api/v1
Feature: List keys

  Background:
    Given the following "accounts" exist:
      | Name  | Subdomain |
      | Test1 | test1     |
      | Test2 | test2     |
    And I send and accept JSON

  Scenario: Admin retrieves all keys for their account
    Given I am an admin of account "test1"
    And I am on the subdomain "test1"
    And the current account has 3 "keys"
    And I use an authentication token
    When I send a GET request to "/keys"
    Then the response status should be "200"
    And the JSON response should be an array with 3 "keys"

  Scenario: Admin retrieves a paginated list of keys
    Given I am an admin of account "test1"
    And I am on the subdomain "test1"
    And the current account has 20 "keys"
    And I use an authentication token
    When I send a GET request to "/keys?page[number]=2&page[size]=5"
    Then the response status should be "200"
    And the JSON response should be an array with 5 "keys"

  Scenario: Admin retrieves a paginated list of keys with a page size that is too high
    Given I am an admin of account "test1"
    And I am on the subdomain "test1"
    And the current account has 20 "keys"
    And I use an authentication token
    When I send a GET request to "/keys?page[number]=1&page[size]=250"
    Then the response status should be "400"

  Scenario: Admin retrieves a paginated list of keys with a page size that is too low
    Given I am an admin of account "test1"
    And I am on the subdomain "test1"
    And the current account has 20 "keys"
    And I use an authentication token
    When I send a GET request to "/keys?page[number]=1&page[size]=-250"
    Then the response status should be "400"

  Scenario: Admin retrieves a paginated list of keys with an invalid page number
    Given I am an admin of account "test1"
    And I am on the subdomain "test1"
    And the current account has 20 "keys"
    And I use an authentication token
    When I send a GET request to "/keys?page[number]=-1&page[size]=10"
    Then the response status should be "400"

  Scenario: Admin retrieves all keys without a limit for their account
    Given I am an admin of account "test1"
    And I am on the subdomain "test1"
    And the current account has 20 "keys"
    And I use an authentication token
    When I send a GET request to "/keys"
    Then the response status should be "200"
    And the JSON response should be an array with 10 "keys"

  Scenario: Admin retrieves all keys with a low limit for their account
    Given I am an admin of account "test1"
    And I am on the subdomain "test1"
    And the current account has 10 "keys"
    And I use an authentication token
    When I send a GET request to "/keys?limit=5"
    Then the response status should be "200"
    And the JSON response should be an array with 5 "keys"

  Scenario: Admin retrieves all keys with a high limit for their account
    Given I am an admin of account "test1"
    And I am on the subdomain "test1"
    And the current account has 20 "keys"
    And I use an authentication token
    When I send a GET request to "/keys?limit=20"
    Then the response status should be "200"
    And the JSON response should be an array with 20 "keys"

  Scenario: Admin retrieves all keys with a limit that is too high
    Given I am an admin of account "test1"
    And I am on the subdomain "test1"
    And the current account has 2 "keys"
    And I use an authentication token
    When I send a GET request to "/keys?limit=900"
    Then the response status should be "400"

  Scenario: Admin retrieves all keys with a limit that is too low
    Given I am an admin of account "test1"
    And I am on the subdomain "test1"
    And the current account has 2 "keys"
    And I use an authentication token
    When I send a GET request to "/keys?limit=-900"
    Then the response status should be "400"

  Scenario: Product retrieves all keys for their product
    Given I am on the subdomain "test1"
    And the current account has 1 "product"
    And I am a product of account "test1"
    And I use an authentication token
    And the current account has 3 "keys"
    And the current product has 1 "key"
    When I send a GET request to "/keys"
    Then the response status should be "200"
    And the JSON response should be an array with 1 "key"

  Scenario: Admin attempts to retrieve all keys for another account
    Given I am an admin of account "test2"
    But I am on the subdomain "test1"
    And I use an authentication token
    When I send a GET request to "/keys"
    Then the response status should be "401"
    And the JSON response should be an array of 1 error

  Scenario: User attempts to retrieve all keys for their account
    Given I am on the subdomain "test1"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    And the current account has 3 "keys"
    When I send a GET request to "/keys"
    Then the response status should be "403"
    And the JSON response should be an array of 1 error
