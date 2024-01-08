@api/v1
Feature: Update release
  Background:
    Given the following "accounts" exist:
      | name    | slug  |
      | Test 1  | test1 |
      | Test 2  | test2 |
    And I send and accept JSON

  Scenario: Endpoint should be inaccessible when account is disabled
    Given the account "test1" is canceled
    And I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "release"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/releases/$0"
    Then the response status should be "403"

  Scenario: Admin updates a release for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "release"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/releases/$0" with the following:
      """
      {
        "data": {
          "type": "releases",
          "attributes": {
            "name": "Fixed Release",
            "description": "a note",
            "metadata": {
              "shasums": ["01ba4719c80b6fe911b091a7c05124b64eeece964e09c058ef8f9805daca546b"]
            }
          }
        }
      }
      """
    Then the response status should be "200"
    And the response body should be a "release" with the following attributes:
      """
      {
        "name": "Fixed Release",
        "description": "a note",
        "metadata": {
          "shasums": ["01ba4719c80b6fe911b091a7c05124b64eeece964e09c058ef8f9805daca546b"]
        }
      }
      """
    And the response body should be a "release" with the following relationships:
      """
      {
        "artifacts": {
          "links": { "related": "/v1/accounts/$account/releases/$releases[0]/artifacts" }
        }
      }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin updates the name of release
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "release"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/releases/$0" with the following:
      """
      {
        "data": {
          "type": "releases",
          "attributes": {
            "name": "Renamed Release"
          }
        }
      }
      """
    Then the response status should be "200"
    And the response body should be a "release" with the following attributes:
      """
      {
        "name": "Renamed Release"
      }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin removes the name of release
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "release"
    And the first "release" has the following attributes:
      """
      { "description": "a-name" }
      """
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/releases/$0" with the following:
      """
      {
        "data": {
          "type": "releases",
          "attributes": {
            "name": null
          }
        }
      }
      """
    Then the response status should be "200"
    And the response body should be a "release" with the following attributes:
      """
      {
        "name": null
      }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin updates the description of a release
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "release"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/releases/$0" with the following:
      """
      {
        "data": {
          "type": "releases",
          "attributes": {
            "description": "a note"
          }
        }
      }
      """
    Then the response status should be "200"
    And the response body should be a "release" with the following attributes:
      """
      {
        "description": "a note"
      }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin removes the description of a release
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "release"
    And the first "release" has the following attributes:
      """
      { "description": "a-desc" }
      """
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/releases/$0" with the following:
      """
      {
        "data": {
          "type": "releases",
          "attributes": {
            "description": null
          }
        }
      }
      """
    Then the response status should be "200"
    And the response body should be a "release" with the following attributes:
      """
      {
        "description": null
      }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin updates the tag of a release
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "release"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/releases/$0" with the following:
      """
      {
        "data": {
          "type": "releases",
          "attributes": {
            "tag": "some-tag"
          }
        }
      }
      """
    Then the response status should be "200"
    And the response body should be a "release" with the following attributes:
      """
      {
        "tag": "some-tag"
      }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin removes the tag of a release
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "release"
    And the first "release" has the following attributes:
      """
      { "tag": "a-tag" }
      """
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/releases/$0" with the following:
      """
      {
        "data": {
          "type": "releases",
          "attributes": {
            "tag": null
          }
        }
      }
      """
    Then the response status should be "200"
    And the response body should be a "release" with the following attributes:
      """
      {
        "tag": null
      }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin updates the tag of a release with an existing tag
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 2 "releases"
    And the last "release" has the following attributes:
      """
      { "tag": "taken-tag" }
      """
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/releases/$0" with the following:
      """
      {
        "data": {
          "type": "releases",
          "attributes": {
            "tag": "taken-tag"
          }
        }
      }
      """
    Then the response status should be "422"
    And the response body should be an array of 1 error
    And the first error should have the following properties:
      """
      {
        "title": "Unprocessable resource",
        "detail": "tag already exists",
        "code": "TAG_TAKEN",
        "source": {
          "pointer": "/data/attributes/tag"
        }
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin attempts to change the version of a release
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 3 "webhook-endpoints"
    And the current account has 1 "release"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/releases/$0" with the following:
      """
      {
        "data": {
          "type": "releases",
          "attributes": {
            "version": "1.0.0"
          }
        }
      }
      """
    Then the response status should be "400"
    And the response body should be an array of 1 error
    And the first error should have the following properties:
      """
      {
        "title": "Bad request",
        "detail": "unpermitted parameter",
        "source": {
          "pointer": "/data/attributes/version"
        }
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" job
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Environment updates one of their isolated releases
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And the current account has 3 isolated "webhook-endpoints"
    And the current account has 1 isolated "release"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    When I send a PATCH request to "/accounts/test1/releases/$0" with the following:
      """
      {
        "data": {
          "type": "releases",
          "attributes": {
            "name": "Isolated Release"
          }
        }
      }
      """
    Then the response status should be "200"
    And the response body should be a "release" with the following attributes:
      """
      { "name": "Isolated Release" }
      """
    And sidekiq should have 3 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Product updates one of their releases
    Given the current account is "test1"
    And the current account has 3 "webhook-endpoints"
    And the current account has 1 "product"
    And the current account has 1 "release" for the first "product"
    Given I am a product of account "test1"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/releases/$0" with the following:
      """
      {
        "data": {
          "type": "releases",
          "attributes": {
            "name": "P1 Release"
          }
        }
      }
      """
    Then the response status should be "200"
    And the response body should be a "release" with the following attributes:
      """
      {
        "name": "P1 Release"
      }
      """
    And sidekiq should have 3 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Product attempts to update a release for another product
    Given the current account is "test1"
    And the current account has 3 "webhook-endpoints"
    And the current account has 2 "products"
    And the current account has 1 "release" for the second "product"
    Given I am a product of account "test1"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/releases/$0" with the following:
      """
      {
        "data": {
          "type": "releases",
          "attributes": {
            "name": "P2 Release"
          }
        }
      }
      """
    Then the response status should be "404"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: License attempts to update a release for their product
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "release" for an existing "product"
    And the current account has 1 "policy" for an existing "product"
    And the current account has 1 "license" for an existing "policy"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/releases/$0" with the following:
      """
      {
        "data": {
          "type": "releases",
          "attributes": {
            "name": "Not My Release"
          }
        }
      }
      """
    Then the response status should be "403"

  Scenario: User attempts to update a release for their product
    Given the current account is "test1"
    And the current account has 1 "user"
    And the current account has 1 "product"
    And the current account has 1 "release" for the last "product"
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "license" for the last "policy"
    And the last "license" has the following attributes:
      """
      { "userId": "$users[1]" }
      """
    And I am a user of account "test1"
    And I use an authentication token
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/releases/$0" with the following:
      """
      {
        "data": {
          "type": "releases",
          "attributes": {
            "name": "Not My Release"
          }
        }
      }
      """
    Then the response status should be "403"

  Scenario: Anonymous attempts to update a release
    Given the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 3 "releases"
    When I send a PATCH request to "/accounts/test1/releases/$0" with the following:
      """
      {
        "data": {
          "type": "releases",
          "attributes": {
            "name": "Not My Release"
          }
        }
      }
      """
    Then the response status should be "401"
