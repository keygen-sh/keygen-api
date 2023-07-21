@api/v1
@mp
Feature: List plans
  Background:
    Given I send and accept JSON

  Scenario: Anonymous retrieves all plans
    Given there exists 3 "plans"
    When I send a GET request to "/plans"
    Then the response status should be "200"
    And the response body should be an array with 3 "plans"

  Scenario: Admin retrieves all plans
    Given there exists 1 "account"
    And there exists 5 "plans"
    And I am an admin of the first "account"
    And I use an authentication token
    When I send a GET request to "/plans"
    Then the response status should be "200"
    And the response body should be an array with 6 "plans"
    And the response should contain the following headers:
      """
      { "Content-Type": "application/vnd.api+json; charset=utf-8" }
      """
    And sidekiq should have 0 "request-log" jobs

  Scenario: Anonymous should not be able to see private plans
    Given there exists 3 "plans"
    And the first "plan" has the following attributes:
      """
      { "private": true }
      """
    When I send a GET request to "/plans"
    Then the response status should be "200"
    And the response body should be an array with 2 "plans"

  Scenario: Anonymous retrieves a paginated list of plans
    Given there exists 20 "plans"
    When I send a GET request to "/plans?page[number]=2&page[size]=5"
    Then the response status should be "200"
    And the response body should be an array with 5 "plans"
    And sidekiq should have 0 "request-log" jobs

  Scenario: Anonymous retrieves a paginated list of plans with a page size that is too high
    Given there exists 20 "plans"
    When I send a GET request to "/plans?page[number]=1&page[size]=250"
    Then the response status should be "400"
    And sidekiq should have 0 "request-log" jobs

  Scenario: Anonymous retrieves a paginated list of plans with a page size that is too low
    Given there exists 20 "plans"
    When I send a GET request to "/plans?page[number]=1&page[size]=-10"
    Then the response status should be "400"
    And sidekiq should have 0 "request-log" jobs

  Scenario: Anonymous retrieves a paginated list of plans with an invalid page number
    Given there exists 20 "plans"
    When I send a GET request to "/plans?page[number]=-1&page[size]=10"
    Then the response status should be "400"
    And sidekiq should have 0 "request-log" jobs

  Scenario: Anonymous retrieves all plans without a limit for their account
    Given there exists 20 "plans"
    When I send a GET request to "/plans"
    Then the response status should be "200"
    And the response body should be an array with 10 "plans"
    And sidekiq should have 0 "request-log" jobs

  Scenario: Anonymous retrieves all plans with a low limit for their account
    Given there exists 10 "plans"
    When I send a GET request to "/plans?limit=5"
    Then the response status should be "200"
    And the response body should be an array with 5 "plans"
    And sidekiq should have 0 "request-log" jobs

  Scenario: Anonymous retrieves all plans with a high limit for their account
    Given there exists 20 "plans"
    When I send a GET request to "/plans?limit=20"
    Then the response status should be "200"
    And the response body should be an array with 20 "plans"
    And sidekiq should have 0 "request-log" jobs

  Scenario: Anonymous retrieves all plans with a limit that is too high
    Given there exists 2 "plans"
    When I send a GET request to "/plans?limit=900"
    Then the response status should be "400"
    And sidekiq should have 0 "request-log" jobs

  Scenario: Anonymous retrieves all plans with a limit that is too low
    Given there exists 2 "plans"
    When I send a GET request to "/plans?limit=0"
    Then the response status should be "400"
    And sidekiq should have 0 "request-log" jobs
