@api/v1
Feature: Update user

  Scenario: Admin updates a user for their account
    Given there exists an account "bungie"
    And I am an admin of account "bungie"
    And I am on the subdomain "bungie"
    And the current account has 1 "user"
    And I send and accept JSON
    And I use my auth token
    When I send a PATCH request to "/users/dgKGxar7" with the following:
      """
      { "user": { "name": "Mr. Robot" } }
      """
    Then the response status should be "200"
    And the JSON response should be a "user" with the name "Mr. Robot"

  Scenario: Admin attempts to update a user for another account
    Given there exists an account "bungie"
    And there exists another account "blizzard"
    And I am an admin of account "blizzard"
    But I am on the subdomain "bungie"
    And I send and accept JSON
    And I use my auth token
    When I send a PATCH request to "/users/dgKGxar7" with the following:
      """
      { "user": { "name": "Updated name" } }
      """
    Then the response status should be "401"

  Scenario: Admin promotes a user to admin for their account
    Given there exists an account "bungie"
    And I am an admin of account "bungie"
    And I am on the subdomain "bungie"
    And the current account has 2 "users"
    And I send and accept JSON
    And I use my auth token
    When I send a PATCH request to "/users/dgKGxar7" with the following:
      """
      { "user": { "role": "admin" } }
      """
    Then the response status should be "200"
    And the JSON response should be a "user" with the role "admin"
    And the current account should have 1 "user"

  Scenario: Admin updates a users meta data
    Given there exists an account "bungie"
    And I am an admin of account "bungie"
    And I am on the subdomain "bungie"
    And the current account has 1 "user"
    And I send and accept JSON
    And I use my auth token
    When I send a PATCH request to "/users/dgKGxar7" with the following:
      """
      { "user": { "meta": { "customerId": "cust_gV4dW9jrc" } } }
      """
    Then the response status should be "200"
    And the JSON response should be a "user" with the following meta:
      """
      { "customerId": "cust_gV4dW9jrc" }
      """

  Scenario: User attempts to update their password
   Given there exists an account "bungie"
   And I am on the subdomain "bungie"
   And the current account has 3 "users"
   And I am a user of account "bungie"
   And I send and accept JSON
   And I use my auth token
   When I send a PATCH request to "/users/dgKGxar7" with the following:
     """
     { "user": { "password": "newPassword" } }
     """
   Then the response status should be "400"

  Scenario: Admin attempts to update a users password
    Given there exists an account "bungie"
    And I am an admin of account "bungie"
    And I am on the subdomain "bungie"
    And the current account has 3 "users"
    And I send and accept JSON
    And I use my auth token
    When I send a PATCH request to "/users/dgKGxar7" with the following:
      """
      { "user": { "password": "h4ck3d!" } }
      """
    Then the response status should be "400"
