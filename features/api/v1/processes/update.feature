@api/v1
Feature: Update machine process

  Background:
    Given the following "accounts" exist:
      | Name    | Slug  |
      | Test 1  | test1 |
      | Test 2  | test2 |
    And I send and accept JSON

  Scenario: Endpoint should be inaccessible when account is disabled
    Given the account "test1" is canceled
    And the current account is "test1"
    And the current account has 1 "process"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/processes/$0"
    Then the response status should be "403"

  Scenario: Admin updates a process
    Given the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "process"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/processes/$0" with the following:
      """
      {
        "data": {
          "type": "processes",
          "id": "$processes[0].id",
          "attributes": {
            "metadata": {
              "serverId": "0000"
            }
          }
        }
      }
      """
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should be a "process" with the following attributes:
      """
      {
        "metadata": {
          "serverId": "0000"
        }
      }
      """
    And sidekiq should have 2 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Developer updates a process
    Given the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "process"
    And the current account has 1 "developer"
    And I am a developer of account "test1"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/processes/$0" with the following:
      """
      {
        "data": {
          "type": "processes",
          "id": "$processes[0].id",
          "attributes": {
            "metadata": {
              "serverId": "0000"
            }
          }
        }
      }
      """
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And sidekiq should have 2 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Sales updates a process
    Given the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "process"
    And the current account has 1 "sales-agent"
    And I am a sales agent of account "test1"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/processes/$0" with the following:
      """
      {
        "data": {
          "type": "processes",
          "id": "$processes[0].id",
          "attributes": {
            "metadata": {
              "serverId": "0000"
            }
          }
        }
      }
      """
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And sidekiq should have 2 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Support updates a process
    Given the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "process"
    And the current account has 1 "support-agent"
    And I am a support agent of account "test1"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/processes/$0" with the following:
      """
      {
        "data": {
          "type": "processes",
          "id": "$processes[0].id",
          "attributes": {
            "metadata": {
              "serverId": "0000"
            }
          }
        }
      }
      """
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And sidekiq should have 2 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Read only updates a process
    Given the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "process"
    And the current account has 1 "read-only"
    And I am a read only of account "test1"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/processes/$0" with the following:
      """
      {
        "data": {
          "type": "processes",
          "id": "$processes[0].id",
          "attributes": {
            "metadata": {
              "serverId": "0000"
            }
          }
        }
      }
      """
    Then the response status should be "403"
    And the response should contain a valid signature header for "test1"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Environment updates an isolated process
    Given the current account is "test1"
    And the current account has 1 isolated "webhook-endpoint"
    And the current account has 1 isolated "environment"
    And the current account has 1 isolated "process"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "keygen-environment": "isolated" }
      """
    When I send a PATCH request to "/accounts/test1/processes/$0" with the following:
      """
      {
        "data": {
          "type": "processes",
          "attributes": {
            "metadata": { "name": "Isolated Process" }
          }
        }
      }
      """
    Then the response status should be "200"
    And the response body should be a "process" with the following attributes:
      """
      { "metadata": { "name": "Isolated Process" } }
      """
    And the response should contain a valid signature header for "test1"
    And the response should contain the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Environment updates a shared process
    Given the current account is "test1"
    And the current account has 1 shared "webhook-endpoint"
    And the current account has 1 shared "environment"
    And the current account has 1 shared "process"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "keygen-environment": "shared" }
      """
    When I send a PATCH request to "/accounts/test1/processes/$0" with the following:
      """
      {
        "data": {
          "type": "processes",
          "attributes": {
            "metadata": { "name": "Shared Process" }
          }
        }
      }
      """
    Then the response status should be "200"
    And the response body should be a "process" with the following attributes:
      """
      { "metadata": { "name": "Shared Process" } }
      """
    And the response should contain a valid signature header for "test1"
    And the response should contain the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Environment updates a global process
    Given the current account is "test1"
    And the current account has 1 shared "webhook-endpoint"
    And the current account has 1 shared "environment"
    And the current account has 1 global "process"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "keygen-environment": "shared" }
      """
    When I send a PATCH request to "/accounts/test1/processes/$0" with the following:
      """
      {
        "data": {
          "type": "processes",
          "attributes": {
            "metadata": { "name": "Global Process" }
          }
        }
      }
      """
    Then the response status should be "403"
    And the response should contain a valid signature header for "test1"
    And the response should contain the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Product updates a process
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "license" for the last "policy"
    And the current account has 1 "machine" for the last "license"
    And the current account has 1 "process" for the last "machine"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/processes/$0" with the following:
      """
      {
        "data": {
          "type": "processes",
          "id": "$processes[0].id",
          "attributes": {
            "metadata": {
              "serverId": "0000"
            }
          }
        }
      }
      """
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Product updates a process for a different product
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And the current account has 1 "process"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/processes/$0" with the following:
      """
      {
        "data": {
          "type": "processes",
          "id": "$processes[0].id",
          "attributes": {
            "metadata": {
              "serverId": "0000"
            }
          }
        }
      }
      """
    Then the response status should be "404"
    And the response should contain a valid signature header for "test1"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: License updates a process's metadata
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "license"
    And the current account has 1 "machine" for the last "license"
    And the current account has 1 "process" for the last "machine"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/processes/$0" with the following:
      """
      {
        "data": {
          "type": "processes",
          "id": "$processes[0].id",
          "attributes": {
            "metadata": {
              "serverId": "0000"
            }
          }
        }
      }
      """
    Then the response status should be "400"
    And the response should contain a valid signature header for "test1"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: License updates a process for a different license
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "license"
    And the current account has 1 "process"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/processes/$0" with the following:
      """
      {
        "data": {
          "type": "processes",
          "id": "$processes[0].id",
          "attributes": {
            "metadata": {
              "serverId": "0000"
            }
          }
        }
      }
      """
    Then the response status should be "404"
    And the response should contain a valid signature header for "test1"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: User updates a process's metadata
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "user"
    And the current account has 1 "license" for the last "user"
    And the current account has 1 "machine" for the last "license"
    And the current account has 1 "process" for the last "machine"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/processes/$0" with the following:
      """
      {
        "data": {
          "type": "processes",
          "id": "$processes[0].id",
          "attributes": {
            "metadata": {
              "serverId": "0000"
            }
          }
        }
      }
      """
    Then the response status should be "400"
    And the response should contain a valid signature header for "test1"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: User updates a process for a different user
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "user"
    And the current account has 1 "process"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/processes/$0" with the following:
      """
      {
        "data": {
          "type": "processes",
          "id": "$processes[0].id",
          "attributes": {
            "metadata": {
              "serverId": "0000"
            }
          }
        }
      }
      """
    Then the response status should be "404"
    And the response should contain a valid signature header for "test1"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Anonymous updates a process
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "process"
    When I send a PATCH request to "/accounts/test1/processes/$0" with the following:
      """
      {
        "data": {
          "type": "processes",
          "id": "$processes[0].id",
          "attributes": {
            "metadata": {
              "serverId": "0000"
            }
          }
        }
      }
      """
    Then the response status should be "401"
    And the response should contain a valid signature header for "test1"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job
