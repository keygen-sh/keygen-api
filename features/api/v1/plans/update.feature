@api/v1
Feature: Update plan

  Background:
    Given I send and accept JSON

  Scenario: Anonymous attempts to update a plan
    Given there exists 1 "plan"
    When I send a PATCH request to "/plans/$0" with the following:
      """
      { "plan": {} }
      """
    Then the response status should be "401"
