@api/v1
Feature: Create plan

  Background:
    Given I send and accept JSON

  Scenario: Anonymous attempts to create a plan
    When I send a POST request to "/plans" with the following:
      """
      { "plan": {} }
      """
    Then the response status should be "401"
