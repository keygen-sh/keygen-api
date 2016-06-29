@api/v1
Feature: Show plan

  Scenario: Anonymous retrieves a plan
    Given there exists 3 "plans"
    And I send and accept JSON
    When I send a GET request to "/plans/ElZw7Zko"
    Then the response status should be "200"
    And the JSON response should be a "plan"
