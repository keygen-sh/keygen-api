@api/v1
Feature: Update plan

  Scenario: Anonymous attempts to update a plan
    Given I send and accept JSON
    When I send a PATCH request to "/plans/ElZw7Zko" with the following:
      """
      { "plan": {} }
      """
    Then the response status should be "401"
