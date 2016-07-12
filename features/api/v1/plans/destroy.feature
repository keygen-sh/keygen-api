@api/v1
Feature: Delete plan

  Background:
    Given I send and accept JSON

  Scenario: Anonymous attempts to delete a plan
    Given there exists 1 "plan"
    When I send a DELETE request to "/plans/$0"
    Then the response status should be "401"
