@api/v1
Feature: Show plan

  Background:
    Given I send and accept JSON

  Scenario: Anonymous retrieves a plan
    Given there exists 3 "plans"
    When I send a GET request to "/plans/$0"
    Then the response status should be "200"
    And the JSON response should be a "plan"

  Scenario: Anonymous retrieves a private plan
    Given there exists 3 "plans"
    And the first "plan" has the following attributes:
      """
      { "private": true }
      """
    When I send a GET request to "/plans/$0"
    Then the response status should be "200"
    And the JSON response should be a "plan" that is private

  Scenario: Anonymous retrieves an invalid plan
    When I send a GET request to "/plans/invalid"
    Then the response status should be "404"
