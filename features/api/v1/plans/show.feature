@api/v1
Feature: Show plan

  Background:
    Given I send and accept JSON

  Scenario: Anonymous retrieves a plan
    Given there exists 3 "plans"
    When I send a GET request to "/plans/$0"
    Then the response status should be "200"
    And the JSON response should be a "plan"

  Scenario: Anonymous retrieves an invalid plan
    When I send a GET request to "/plans/invalid"
    Then the response status should be "404"
