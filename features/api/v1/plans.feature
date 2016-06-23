@api
Feature: List plans

  Scenario: Retreive all plans as JSON
    Given I send and accept JSON
    And I have 3 "plans"
    When I send a GET request to "/v1/plans"
    Then the response should be "200"
    And the JSON response should be an array with 3 "plans"
