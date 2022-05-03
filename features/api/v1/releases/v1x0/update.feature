@api/v1.1 @deprecated
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
    And I use API version "1.0"
    When I send a PATCH request to "/accounts/test1/releases/$0"
    Then the response status should be "403"

  Scenario: Admin updates a release for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "release"
    And I use an authentication token
    And I use API version "1.0"
    When I send a PATCH request to "/accounts/test1/releases/$0" with the following:
      """
      {
        "data": {
          "type": "releases",
          "attributes": {
            "name": "Fixed Release",
            "description": "a note",
            "signature": "NTeMGMRIT5PxqVNiYujUygX2nX+qXeDvVPjccT+5lFF2IFS6i08PNCnZ03XZD7on9bg7VGCx4KM3JuSfC6sUCA==",
            "checksum": null,
            "filesize": 209715200,
            "metadata": {
              "sha256": "01ba4719c80b6fe911b091a7c05124b64eeece964e09c058ef8f9805daca546b"
            }
          }
        }
      }
      """
    Then the response status should be "200"
    And the JSON response should be a "release" with the following attributes:
      """
      {
        "name": "Fixed Release",
        "description": "a note",
        "signature": "NTeMGMRIT5PxqVNiYujUygX2nX+qXeDvVPjccT+5lFF2IFS6i08PNCnZ03XZD7on9bg7VGCx4KM3JuSfC6sUCA==",
        "checksum": null,
        "filesize": 209715200,
        "metadata": {
          "sha256": "01ba4719c80b6fe911b091a7c05124b64eeece964e09c058ef8f9805daca546b"
        }
      }
      """
    And the JSON response should be a "release" with the following relationships:
      """
      {
        "artifact": {
          "links": { "related": "/v1/accounts/$account/releases/$releases[0]/artifact" },
          "data": null
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
    And I use API version "1.0"
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
    And the JSON response should be a "release" with the following attributes:
      """
      {
        "name": "Renamed Release"
      }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin removes the filesize of release
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "release"
    And I use an authentication token
    And I use API version "1.0"
    When I send a PATCH request to "/accounts/test1/releases/$0" with the following:
      """
      {
        "data": {
          "type": "releases",
          "attributes": {
            "filesize": null
          }
        }
      }
      """
    Then the response status should be "200"
    And the JSON response should be a "release" with the following attributes:
      """
      {
        "filesize": null
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
    And I use API version "1.0"
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
    And the JSON response should be a "release" with the following attributes:
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
    And I use an authentication token
    And I use API version "1.0"
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
    And the JSON response should be a "release" with the following attributes:
      """
      {
        "description": null
      }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin updates the signature of a release
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "release"
    And I use an authentication token
    And I use API version "1.0"
    When I send a PATCH request to "/accounts/test1/releases/$0" with the following:
      """
      {
        "data": {
          "type": "releases",
          "attributes": {
            "signature": "NTeMGMRIT5PxqVNiYujUygX2nX+qXeDvVPjccT+5lFF2IFS6i08PNCnZ03XZD7on9bg7VGCx4KM3JuSfC6sUCA=="
          }
        }
      }
      """
    Then the response status should be "200"
    And the JSON response should be a "release" with the following attributes:
      """
      {
        "signature": "NTeMGMRIT5PxqVNiYujUygX2nX+qXeDvVPjccT+5lFF2IFS6i08PNCnZ03XZD7on9bg7VGCx4KM3JuSfC6sUCA=="
      }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin removes the signature of a release
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "release"
    And I use an authentication token
    And I use API version "1.0"
    When I send a PATCH request to "/accounts/test1/releases/$0" with the following:
      """
      {
        "data": {
          "type": "releases",
          "attributes": {
            "signature": null
          }
        }
      }
      """
    Then the response status should be "200"
    And the JSON response should be a "release" with the following attributes:
      """
      {
        "signature": null
      }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin updates the checksum of a release
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "release"
    And I use an authentication token
    And I use API version "1.0"
    When I send a PATCH request to "/accounts/test1/releases/$0" with the following:
      """
      {
        "data": {
          "type": "releases",
          "attributes": {
            "checksum": "01ba4719c80b6fe911b091a7c05124b64eeece964e09c058ef8f9805daca546b"
          }
        }
      }
      """
    Then the response status should be "200"
    And the JSON response should be a "release" with the following attributes:
      """
      {
        "checksum": "01ba4719c80b6fe911b091a7c05124b64eeece964e09c058ef8f9805daca546b"
      }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin removes the checksum of a release
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "release"
    And I use an authentication token
    And I use API version "1.0"
    When I send a PATCH request to "/accounts/test1/releases/$0" with the following:
      """
      {
        "data": {
          "type": "releases",
          "attributes": {
            "checksum": null
          }
        }
      }
      """
    Then the response status should be "200"
    And the JSON response should be a "release" with the following attributes:
      """
      {
        "checksum": null
      }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin attempts to change the version of a release
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 3 "webhook-endpoints"
    And the current account has 1 "release"
    And I use an authentication token
    And I use API version "1.0"
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
    And the JSON response should be an array of 1 error
    And the first error should have the following properties:
      """
      {
        "title": "Bad request",
        "detail": "Unpermitted parameters: /data/attributes/version"
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin attempts to change the filename of a release
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 3 "webhook-endpoints"
    And the current account has 1 "release"
    And I use an authentication token
    And I use API version "1.0"
    When I send a PATCH request to "/accounts/test1/releases/$0" with the following:
      """
      {
        "data": {
          "type": "releases",
          "attributes": {
            "filename": "App-1.0.0.exe"
          }
        }
      }
      """
    Then the response status should be "400"
    And the JSON response should be an array of 1 error
    And the first error should have the following properties:
      """
      {
        "title": "Bad request",
        "detail": "Unpermitted parameters: /data/attributes/filename"
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin attempts to change the filetype of a release
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 3 "webhook-endpoints"
    And the current account has 1 "release"
    And I use an authentication token
    And I use API version "1.0"
    When I send a PATCH request to "/accounts/test1/releases/$0" with the following:
      """
      {
        "data": {
          "type": "releases",
          "attributes": {
            "filetype": "exe"
          }
        }
      }
      """
    Then the response status should be "400"
    And the JSON response should be an array of 1 error
    And the first error should have the following properties:
      """
      {
        "title": "Bad request",
        "detail": "Unpermitted parameters: /data/attributes/filetype"
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin attempts to change the platform of a release
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 3 "webhook-endpoints"
    And the current account has 1 "release"
    And I use an authentication token
    And I use API version "1.0"
    When I send a PATCH request to "/accounts/test1/releases/$0" with the following:
      """
      {
        "data": {
          "type": "releases",
          "attributes": {
            "platform": "win32"
          }
        }
      }
      """
    Then the response status should be "400"
    And the JSON response should be an array of 1 error
    And the first error should have the following properties:
      """
      {
        "title": "Bad request",
        "detail": "Unpermitted parameters: /data/attributes/platform"
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin attempts to change the channel of a release
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 3 "webhook-endpoints"
    And the current account has 1 "release"
    And I use an authentication token
    And I use API version "1.0"
    When I send a PATCH request to "/accounts/test1/releases/$0" with the following:
      """
      {
        "data": {
          "type": "releases",
          "attributes": {
            "channel": "dev"
          }
        }
      }
      """
    Then the response status should be "400"
    And the JSON response should be an array of 1 error
    And the first error should have the following properties:
      """
      {
        "title": "Bad request",
        "detail": "Unpermitted parameters: /data/attributes/channel"
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" job
    And sidekiq should have 1 "request-log" job
