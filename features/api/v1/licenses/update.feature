@api/v1
Feature: Update license

  Background:
    Given the following accounts exist:
      | Name  | Subdomain |
      | Test1 | test1     |
      | Test2 | test2     |
    And I send and accept JSON

  Scenario: Admin updates a license expiry
    Given I am an admin of account "test1"
    And I am on the subdomain "test1"
    And the current account has 1 "product"
    And the current account has 1 "policies"
    And the current account has 1 "user"
    And the current account has 1 "license"
    And I use my auth token
    When I send a PATCH request to "/licenses/$0" with the following:
      """
      { "license": { "expiry": "2016-09-05T22:53:37.000Z" } }
      """
    Then the response status should be "200"
    And the JSON response should be a "license" with the expiry "2016-09-05T22:53:37.000Z"

  Scenario: Admin updates a license policy
    Given I am an admin of account "test1"
    And I am on the subdomain "test1"
    And the current account has 1 "product"
    And the current account has 2 "policies"
    And the current account has 1 "user"
    And the current account has 1 "license"
    And I use my auth token
    When I send a PATCH request to "/licenses/$0" with the following:
      """
      { "license": { "policy": "$policies[1]" } }
      """
    Then the response status should be "400"

  Scenario: Admin updates a license key
    Given I am an admin of account "test1"
    And I am on the subdomain "test1"
    And the current account has 1 "product"
    And the current account has 1 "policies"
    And the current account has 1 "user"
    And the current account has 1 "license"
    And I use my auth token
    When I send a PATCH request to "/licenses/$0" with the following:
      """
      { "license": { "key": "a" } }
      """
    Then the response status should be "200"
    And the JSON response should be a "license" with the key "a"

  Scenario: Product updates a license for their product
    Given I am on the subdomain "test1"
    And the current account has 1 "product"
    And I am a product of account "test1"
    And I use my auth token
    And the current account has 1 "license"
    And the current product has 1 "license"
    When I send a PATCH request to "/licenses/$0" with the following:
      """
      { "license": { "key": "b" } }
      """
    Then the response status should be "200"
    And the JSON response should be a "license" with the key "b"

  Scenario: Product attempts to update a license for another product
    Given I am on the subdomain "test1"
    And the current account has 1 "product"
    And I am a product of account "test1"
    And I use my auth token
    And the current account has 1 "license"
    When I send a PATCH request to "/licenses/$0" with the following:
      """
      { "license": { "key": "c" } }
      """
    Then the response status should be "403"

  Scenario: User attempts to update a license for their account
    Given I am on the subdomain "test1"
    And the current account has 3 "licenses"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use my auth token
    When I send a PATCH request to "/licenses/$0" with the following:
      """
      { "license": { "key": "x" } }
      """
    Then the response status should be "403"

  Scenario: Anonymous user attempts to update a license for their account
    Given I am on the subdomain "test1"
    And the current account has 3 "licenses"
    When I send a PATCH request to "/licenses/$0" with the following:
      """
      { "license": { "key": "y" } }
      """
    Then the response status should be "401"

  Scenario: Admin attempts to update a license for another account
    Given I am an admin of account "test2"
    But I am on the subdomain "test1"
    And the current account has 3 "licenses"
    And I use my auth token
    When I send a PATCH request to "/licenses/$0" with the following:
      """
      { "license": { "key": "z" } }
      """
    Then the response status should be "401"
