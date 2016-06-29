@api/v1
Feature: Create plan

  Scenario: Anonymous attempts to create a plan
    Given I send and accept JSON
    When I send a POST request to "/plans" with the following:
      """
      { "plan": {} }
      """
    Then the response status should be "401"
