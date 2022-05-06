@api/v1
Feature: Create artifact

  Background:
    Given the following "accounts" exist:
      | Name    | Slug  |
      | Test 1  | test1 |
      | Test 2  | test2 |
    And I send and accept JSON

  Scenario: Endpoint should be inaccessible when account is disabled
    Given the account "test1" is canceled
    And I am an admin of account "test1"
    And the current account is "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/artifacts"
    Then the response status should be "403"

  Scenario: Admin creates an artifact for a release
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 draft "release"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/artifacts" with the following:
      """
      {
        "data": {
          "type": "artifacts",
          "attributes": {
            "filename": "latest-mac.yml",
            "filetype": "yml",
            "filesize": 512,
            "platform": "darwin"
          },
          "relationships": {
            "release": {
              "data": {
                "type": "releases",
                "id": "$releases[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "307"
    And the response should contain a valid signature header for "test1"
    And the JSON response should be an "artifact" with the following attributes:
      """
      { "status": "WAITING" }
      """
    And the current account should have 1 "artifact"
    And the first "release" should have the following attributes:
      """
      { "status": "DRAFT" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job
