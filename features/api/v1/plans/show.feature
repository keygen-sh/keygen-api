@api/v1
Feature: Show plan

  Background:
    Given I send and accept JSON

  Scenario: Anonymous retrieves a plan
    Given there exists 3 "plans"
    When I send a GET request to "/plans/$0"
    Then the response status should be "200"
    And the JSON response should be a "plan"
    And sidekiq should have 0 "request-log" jobs

  Scenario: Anonymous retrieves a private plan
    Given there exists 3 "plans"
    And the first "plan" has the following attributes:
      """
      { "private": true }
      """
    When I send a GET request to "/plans/$0"
    Then the response status should be "200"
    And the JSON response should be a "plan" that is private
    And sidekiq should have 0 "request-log" jobs

  Scenario: Anonymous retrieves an invalid plan
    When I send a GET request to "/plans/invalid"
    Then the response status should be "404"
    And the first error should have the following properties:
      """
      {
        "title": "Not found",
        "detail": "The requested plan 'invalid' was not found"
      }
      """
    And sidekiq should have 0 "request-log" jobs
