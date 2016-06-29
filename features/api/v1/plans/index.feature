@api/v1
Feature: List plans

  Scenario: Anonymous retrieves all plans
    Given there exists 3 "plans"
    And I send and accept JSON
    When I send a GET request to "/plans"
    Then the response status should be "200"
    And the JSON response should be an array with 3 "plans"
