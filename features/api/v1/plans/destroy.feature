@api/v1
Feature: Delete plan

  Scenario: Anonymous attempts to delete a plan
    Given I send and accept JSON
    When I send a DELETE request to "/plans/ElZw7Zko"
    Then the response status should be "401"
