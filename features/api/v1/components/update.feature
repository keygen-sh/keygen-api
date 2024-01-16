@api/v1
Feature: Update machine component
  Background:
    Given the following "accounts" exist:
      | Name    | Slug  |
      | Test 1  | test1 |
      | Test 2  | test2 |
    And I send and accept JSON

  Scenario: Endpoint should be inaccessible when account is disabled
    Given the account "test1" is canceled
    And the current account is "test1"
    And the current account has 1 "component"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/components/$0"
    Then the response status should be "403"

  Scenario: Admin updates a component's fingerprint
    Given the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "component"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/components/$0" with the following:
      """
      {
        "data": {
          "type": "components",
          "id": "$components[0].id",
          "attributes": {
            "fingerprint": "1bac629c32f688919eb8f81d2232a04b"
          }
        }
      }
      """
    Then the response status should be "400"
    And the response should contain a valid signature header for "test1"
    And the first error should have the following properties:
      """
      {
        "title": "Bad request",
        "detail": "unpermitted parameter",
        "source": {
          "pointer": "/data/attributes/fingerprint"
        }
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin updates a component's name
    Given the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "component"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/components/$0" with the following:
      """
      {
        "data": {
          "type": "components",
          "id": "$components[0].id",
          "attributes": {
            "name": "MAC address"
          }
        }
      }
      """
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should be a "component" with the following attributes:
      """
      { "name": "MAC address" }
      """
    And sidekiq should have 2 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin updates a component's metadata
    Given the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "component"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/components/$0" with the following:
      """
      {
        "data": {
          "type": "components",
          "id": "$components[0].id",
          "attributes": {
            "metadata": {
              "addit": { "mfg": "Ryzen" }
            }
          }
        }
      }
      """
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should be a "component" with the following attributes:
      """
      {
        "metadata": {
          "addit": { "mfg": "Ryzen" }
        }
      }
      """
    And sidekiq should have 2 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Developer updates a component
    Given the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "component"
    And the current account has 1 "developer"
    And I am a developer of account "test1"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/components/$0" with the following:
      """
      {
        "data": {
          "type": "components",
          "id": "$components[0].id",
          "attributes": {
            "metadata": {
              "addit": { "mfg": "Ryzen" }
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

  Scenario: Sales updates a component
    Given the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "component"
    And the current account has 1 "sales-agent"
    And I am a sales agent of account "test1"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/components/$0" with the following:
      """
      {
        "data": {
          "type": "components",
          "id": "$components[0].id",
          "attributes": {
            "metadata": {
              "addit": { "mfg": "Ryzen" }
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

  Scenario: Support updates a component
    Given the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "component"
    And the current account has 1 "support-agent"
    And I am a support agent of account "test1"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/components/$0" with the following:
      """
      {
        "data": {
          "type": "components",
          "id": "$components[0].id",
          "attributes": {
            "metadata": {
              "addit": { "mfg": "Ryzen" }
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

  Scenario: Read only updates a component
    Given the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "component"
    And the current account has 1 "read-only"
    And I am a read only of account "test1"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/components/$0" with the following:
      """
      {
        "data": {
          "type": "components",
          "id": "$components[0].id",
          "attributes": {
            "metadata": {
              "addit": { "mfg": "Ryzen" }
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
  Scenario: Environment updates an isolated component
    Given the current account is "test1"
    And the current account has 1 isolated "webhook-endpoint"
    And the current account has 1 isolated "environment"
    And the current account has 1 isolated "component"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "keygen-environment": "isolated" }
      """
    When I send a PATCH request to "/accounts/test1/components/$0" with the following:
      """
      {
        "data": {
          "type": "components",
          "attributes": {
            "metadata": { "name": "Isolated Process" }
          }
        }
      }
      """
    Then the response status should be "200"
    And the response body should be a "component" with the following attributes:
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
  Scenario: Environment updates a shared component
    Given the current account is "test1"
    And the current account has 1 shared "webhook-endpoint"
    And the current account has 1 shared "environment"
    And the current account has 1 shared "component"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "keygen-environment": "shared" }
      """
    When I send a PATCH request to "/accounts/test1/components/$0" with the following:
      """
      {
        "data": {
          "type": "components",
          "attributes": {
            "metadata": { "name": "Shared Process" }
          }
        }
      }
      """
    Then the response status should be "200"
    And the response body should be a "component" with the following attributes:
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
  Scenario: Environment updates a global component
    Given the current account is "test1"
    And the current account has 1 shared "webhook-endpoint"
    And the current account has 1 shared "environment"
    And the current account has 1 global "component"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "keygen-environment": "shared" }
      """
    When I send a PATCH request to "/accounts/test1/components/$0" with the following:
      """
      {
        "data": {
          "type": "components",
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

  Scenario: Product updates a component
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "license" for the last "policy"
    And the current account has 1 "machine" for the last "license"
    And the current account has 1 "component" for the last "machine"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/components/$0" with the following:
      """
      {
        "data": {
          "type": "components",
          "id": "$components[0].id",
          "attributes": {
            "metadata": {
              "addit": { "mfg": "Ryzen" }
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

  Scenario: Product updates a component for a different product
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And the current account has 1 "component"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/components/$0" with the following:
      """
      {
        "data": {
          "type": "components",
          "id": "$components[0].id",
          "attributes": {
            "metadata": {
              "addit": { "mfg": "Ryzen" }
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

  Scenario: License updates a component's metadata
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "license"
    And the current account has 1 "machine" for the last "license"
    And the current account has 1 "component" for the last "machine"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/components/$0" with the following:
      """
      {
        "data": {
          "type": "components",
          "id": "$components[0].id",
          "attributes": {
            "metadata": {
              "addit": { "mfg": "Ryzen" }
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

  Scenario: License updates a component for a different license
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "license"
    And the current account has 1 "component"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/components/$0" with the following:
      """
      {
        "data": {
          "type": "components",
          "id": "$components[0].id",
          "attributes": {
            "metadata": {
              "addit": { "mfg": "Ryzen" }
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

  Scenario: User updates a component's name (license owner)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "user"
    And the current account has 1 "license" for the last "user" as "owner"
    And the current account has 1 "machine" for the last "license"
    And the current account has 1 "component" for the last "machine"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/components/$0" with the following:
      """
      {
        "data": {
          "type": "components",
          "id": "$components[0].id",
          "attributes": {
            "name": "GPU"
          }
        }
      }
      """
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should be a "component" with the following attributes:
      """
      { "name": "GPU" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: User updates a component's name (license user, as owner)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "user"
    And the current account has 1 "license"
    And the current account has 1 "license-user" for the last "license" and the last "user"
    And the current account has 1 "machine" for the last "license" and the last "user" as "owner"
    And the current account has 1 "component" for the last "machine"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/components/$0" with the following:
      """
      {
        "data": {
          "type": "components",
          "id": "$components[0].id",
          "attributes": {
            "name": "GPU"
          }
        }
      }
      """
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should be a "component" with the following attributes:
      """
      { "name": "GPU" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: User updates a component's name (license user, no owner)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "user"
    And the current account has 1 "license"
    And the current account has 1 "license-user" for the last "license" and the last "user"
    And the current account has 1 "machine" for the last "license"
    And the current account has 1 "component" for the last "machine"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/components/$0" with the following:
      """
      {
        "data": {
          "type": "components",
          "id": "$components[0].id",
          "attributes": {
            "name": "GPU"
          }
        }
      }
      """
    Then the response status should be "403"
    And the response should contain a valid signature header for "test1"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: User updates a component's metadata
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "user"
    And the current account has 1 "license" for the last "user" as "owner"
    And the current account has 1 "machine" for the last "license"
    And the current account has 1 "component" for the last "machine"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/components/$0" with the following:
      """
      {
        "data": {
          "type": "components",
          "id": "$components[0].id",
          "attributes": {
            "metadata": {
              "addit": { "mfg": "Ryzen" }
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

  Scenario: User updates a component for a different user
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "user"
    And the current account has 1 "component"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/components/$0" with the following:
      """
      {
        "data": {
          "type": "components",
          "id": "$components[0].id",
          "attributes": {
            "metadata": {
              "addit": { "mfg": "Ryzen" }
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

  Scenario: Anonymous updates a component
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "component"
    When I send a PATCH request to "/accounts/test1/components/$0" with the following:
      """
      {
        "data": {
          "type": "components",
          "id": "$components[0].id",
          "attributes": {
            "metadata": {
              "addit": { "mfg": "Ryzen" }
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
