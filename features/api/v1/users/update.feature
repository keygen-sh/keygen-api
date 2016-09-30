@api/v1
Feature: Update user

  Background:
    Given the following accounts exist:
      | Name  | Subdomain |
      | Test1 | test1     |
      | Test2 | test2     |
    And I send and accept JSON

  Scenario: Admin updates themself
    Given I am an admin of account "test1"
    And I am on the subdomain "test1"
    And I use my auth token
    When I send a PATCH request to "/users/$current" with the following:
      """
      { "user": { "name": "Mr. Robot" } }
      """
    Then the response status should be "200"
    And the JSON response should be a "user" with the name "Mr. Robot"

  Scenario: Admin updates a user for their account
    Given I am an admin of account "test1"
    And I am on the subdomain "test1"
    And the current account has 1 "user"
    And I use my auth token
    When I send a PATCH request to "/users/$1" with the following:
      """
      { "user": { "name": "Mr. Robot" } }
      """
    Then the response status should be "200"
    And the JSON response should be a "user" with the name "Mr. Robot"

  Scenario: Admin attempts to update a user for another account
    Given I am an admin of account "test2"
    But I am on the subdomain "test1"
    And I use my auth token
    When I send a PATCH request to "/users/$0" with the following:
      """
      { "user": { "name": "Updated name" } }
      """
    Then the response status should be "401"

  Scenario: Admin promotes a user to admin for their account
    Given I am an admin of account "test1"
    And I am on the subdomain "test1"
    And the current account has 2 "users"
    And I use my auth token
    When I send a PATCH request to "/users/$2" with the following:
      """
      {
        "user": {
          "roles": [{
            "name": "admin"
          }]
        }
      }
      """
    Then the response status should be "200"
    And the JSON response should be a "user"

  Scenario: Admin promotes a user with an invalid role name for their account
    Given I am an admin of account "test1"
    And I am on the subdomain "test1"
    And the current account has 2 "users"
    And I use my auth token
    When I send a PATCH request to "/users/$2" with the following:
      """
      {
        "user": {
          "roles": [{
            "name": "moderator"
          }]
        }
      }
      """
    Then the response status should be "422"

  Scenario: User updates attempts to promote themself to admin
    Given I am an admin of account "test1"
    And I am on the subdomain "test1"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use my auth token
    When I send a PATCH request to "/users/$1" with the following:
      """
      {
        "user": {
          "roles": [{
            "name": "admin"
          }]
        }
      }
      """
    Then the response status should be "400"

  Scenario: Admin updates a users meta data
    Given I am an admin of account "test1"
    And I am on the subdomain "test1"
    And the current account has 1 "user"
    And I use my auth token
    When I send a PATCH request to "/users/$1" with the following:
      """
      { "user": { "meta": { "customerId": "cust_gV4dW9jrc" } } }
      """
    Then the response status should be "200"
    And the JSON response should be a "user" with the following meta:
      """
      { "customerId": "cust_gV4dW9jrc" }
      """

  Scenario: Product updates a user for their product
    Given I am on the subdomain "test1"
    And the current account has 1 "product"
    And I am a product of account "test1"
    And I use my auth token
    And the current account has 1 "user"
    And the current product has 1 "user"
    When I send a PATCH request to "/users/$1" with the following:
      """
      { "user": { "name": "Mr. Robot" } }
      """
    Then the response status should be "200"
    And the JSON response should be a "user" with the name "Mr. Robot"

  Scenario: Product attempts to update a user for another product
    Given I am on the subdomain "test1"
    And the current account has 1 "product"
    And I am a product of account "test1"
    And I use my auth token
    And the current account has 1 "user"
    When I send a PATCH request to "/users/$1" with the following:
      """
      { "user": { "name": "Mr. Robot" } }
      """
    Then the response status should be "403"

  Scenario: User attempts to update their password
   Given I am on the subdomain "test1"
   And the current account has 3 "users"
   And I am a user of account "test1"
   And I use my auth token
   When I send a PATCH request to "/users/$current" with the following:
     """
     { "user": { "password": "newPassword" } }
     """
   Then the response status should be "400"

  Scenario: Admin attempts to update a users password
    Given I am an admin of account "test1"
    And I am on the subdomain "test1"
    And the current account has 3 "users"
    And I use my auth token
    When I send a PATCH request to "/users/$2" with the following:
      """
      { "user": { "password": "h4ck3d!" } }
      """
    Then the response status should be "400"
