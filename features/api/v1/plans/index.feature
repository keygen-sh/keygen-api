@api/v1
Feature: List plans

  Background:
    Given I send and accept JSON

  Scenario: Anonymous retrieves all plans
    Given there exists 3 "plans"
    When I send a GET request to "/plans"
    Then the response status should be "200"
    And the JSON response should be an array with 3 "plans"
