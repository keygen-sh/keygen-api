@api
Feature: List users

  Scenario: Retreive all users as JSON
    Given I am an admin of account "cucumber"
    And I am on the subdomain "cucumber"
    And I send and accept JSON
    And I use my auth token
    And I have 3 "users"
    When I send a GET request to "/v1/users"
    Then the response should be "200"
    And the JSON response should be an array with 3 "users"
