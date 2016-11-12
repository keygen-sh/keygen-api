@api/v1
Feature: List plans

  Background:
    Given I send and accept JSON

  Scenario: Anonymous retrieves all plans
    Given there exists 3 "plans"
    When I send a GET request to "/plans"
    Then the response status should be "200"
    And the JSON response should be an array with 3 "plans"

  Scenario: Anonymous retrieves all plans without a limit for their account
    Given there exists 20 "plans"
    When I send a GET request to "/plans"
    Then the response status should be "200"
    And the JSON response should be an array with 10 "plans"

  Scenario: Anonymous retrieves all plans with a low limit for their account
    Given there exists 10 "plans"
    When I send a GET request to "/plans?limit=5"
    Then the response status should be "200"
    And the JSON response should be an array with 5 "plans"

  Scenario: Anonymous retrieves all plans with a high limit for their account
    Given there exists 20 "plans"
    When I send a GET request to "/plans?limit=20"
    Then the response status should be "200"
    And the JSON response should be an array with 20 "plans"

  Scenario: Anonymous retrieves all plans with a limit that is too high
    Given there exists 2 "plans"
    When I send a GET request to "/plans?limit=900"
    Then the response status should be "400"
