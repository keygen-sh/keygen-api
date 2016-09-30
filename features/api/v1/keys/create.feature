@api/v1
Feature: Create key

  Background:
    Given the following accounts exist:
      | Name  | Subdomain |
      | Test1 | test1     |
      | Test2 | test2     |
    And I send and accept JSON

  Scenario: Admin creates a key for their account
    Given I am an admin of account "test1"
    And I am on the subdomain "test1"
    And the current account has 1 "policies"
    And I use my auth token
    When I send a POST request to "/keys" with the following:
      """
      { "key": { "policy": "$policies[0]", "key": "rNxgJ2niG2eQkiJLWwmvHDimWVpm4L" } }
      """
    Then the response status should be "201"
    And the JSON response should be a "key" with the key "rNxgJ2niG2eQkiJLWwmvHDimWVpm4L"

  Scenario: Admin creates a key with missing key value
    Given I am an admin of account "test1"
    And I am on the subdomain "test1"
    And the current account has 1 "policies"
    And I use my auth token
    When I send a POST request to "/keys" with the following:
      """
      { "key": { "policy": "$policies[0]" } }
      """
    Then the response status should be "422"

  Scenario: Admin creates a key with missing policy
    Given I am an admin of account "test1"
    And I am on the subdomain "test1"
    And I use my auth token
    When I send a POST request to "/keys" with the following:
      """
      { "key": { "key": "b" } }
      """
    Then the response status should be "422"

  Scenario: User attempts to create a key
    Given I am on the subdomain "test1"
    And the current account has 1 "policies"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use my auth token
    When I send a POST request to "/keys" with the following:
      """
      { "key": { "policy": "$policies[0]", "key": "sVbmZKq4not2mCEvjEuMVE4cViCWLi" } }
      """
    Then the response status should be "403"

  Scenario: Unauthenticated user attempts to create a key
    Given I am on the subdomain "test1"
    And the current account has 1 "policies"
    When I send a POST request to "/keys" with the following:
      """
      { "key": { "policy": "$policies[0]", "key": "fw8vuUbmWtZfrLe7Xgmg8xNVhTEjjK" } }
      """
    Then the response status should be "401"

  Scenario: Admin of another account attempts to create a key
    Given I am an admin of account "test2"
    And I am on the subdomain "test1"
    And the current account has 1 "policies"
    And I use my auth token
    When I send a POST request to "/keys" with the following:
      """
      { "key": { "policy": "$policies[0]", "key": "PmL2UPti9ZeJTs4kZvGnLJcvsndWhw" } }
      """
    Then the response status should be "401"
