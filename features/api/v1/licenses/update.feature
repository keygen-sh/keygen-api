@api/v1
Feature: Update license

  Background:
    Given the following "accounts" exist:
      | Name    | Slug  |
      | Test 1  | test1 |
      | Test 2  | test2 |
    And I send and accept JSON

  Scenario: Endpoint should be inaccessible when account is disabled
    Given the account "test1" is canceled
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "license"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/licenses/$0"
    Then the response status should be "403"

  Scenario: Admin updates a license expiry (ISO8103 format)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "license"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/licenses/$0" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "id": "$licenses[0].id",
          "attributes": {
            "expiry": "2016-09-05T22:53:37.000Z",
            "name": "Some Name"
          }
        }
      }
      """
    Then the response status should be "200"
    And the response body should be a "license" with the expiry "2016-09-05T22:53:37.000Z"
    And the response body should be a "license" with the name "Some Name"
    And the response should contain a valid signature header for "test1"
    And sidekiq should have 2 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin updates a license expiry (UNIX string)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "license"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/licenses/$0" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "id": "$licenses[0].id",
          "attributes": {
            "expiry": "1645630138"
          }
        }
      }
      """
    Then the response status should be "200"
    And the response body should be a "license" with the expiry "2022-02-23T15:28:58.000Z"
    And the response should contain a valid signature header for "test1"
    And sidekiq should have 2 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin updates a license expiry (UNIX number)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "license"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/licenses/$0" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "id": "$licenses[0].id",
          "attributes": {
            "expiry": 1645630138
          }
        }
      }
      """
    Then the response status should be "200"
    And the response body should be a "license" with the expiry "2022-02-23T15:28:58.000Z"
    And the response should contain a valid signature header for "test1"
    And sidekiq should have 2 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin updates a license by key
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "license" with the following:
      """
      { "key": "163E70-7F0AC7-E72D3D-8A977E-4A7AFA-V3" }
      """
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/licenses/163E70-7F0AC7-E72D3D-8A977E-4A7AFA-V3" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "id": "163E70-7F0AC7-E72D3D-8A977E-4A7AFA-V3",
          "attributes": {
            "expiry": "2016-09-05T22:53:37.000Z",
            "name": "Some Name"
          }
        }
      }
      """
    Then the response status should be "200"
    And the response body should be a "license" with the following attributes:
      """
      {
        "key": "163E70-7F0AC7-E72D3D-8A977E-4A7AFA-V3",
        "expiry": "2016-09-05T22:53:37.000Z",
        "name": "Some Name"
      }
      """
    And the response should contain a valid signature header for "test1"
    And sidekiq should have 2 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin overrides a floating license's max machines
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoints"
    And the current account has 1 "policy"
    And the first "policy" has the following attributes:
      """
      { "floating": true }
      """
    And the current account has 1 "license" for an existing "policy"
    And the first "license" has the following attributes:
      """
      { "maxMachines": 1 }
      """
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/licenses/$0" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "id": "$licenses[0].id",
          "attributes": {
            "maxMachines": 10
          }
        }
      }
      """
    Then the response status should be "200"
    And the response body should be a "license" with the maxMachines "10"
    And the response should contain a valid signature header for "test1"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin removes a floating license's max machine override
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoints"
    And the current account has 1 "policy"
    And the first "policy" has the following attributes:
      """
      {
        "maxMachines": 5,
        "floating": true
      }
      """
    And the current account has 1 "license" for an existing "policy"
    And the first "license" has the following attributes:
      """
      { "maxMachines": 1 }
      """
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/licenses/$0" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "id": "$licenses[0].id",
          "attributes": {
            "maxMachines": null
          }
        }
      }
      """
    Then the response status should be "200"
    And the response body should be a "license" with the maxMachines "5"
    And the response should contain a valid signature header for "test1"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin overrides a floating license's max machines
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoints"
    And the current account has 1 "policy"
    And the first "policy" has the following attributes:
      """
      { "floating": true }
      """
    And the current account has 1 "license" for an existing "policy"
    And the first "license" has the following attributes:
      """
      { "maxMachines": null }
      """
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/licenses/$0" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "id": "$licenses[0].id",
          "attributes": {
            "maxMachines": 5
          }
        }
      }
      """
    Then the response status should be "200"
    And the response body should be a "license" with the maxMachines "5"
    And the response should contain a valid signature header for "test1"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin overrides a floating license's max cores
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoints"
    And the current account has 1 "policy"
    And the first "policy" has the following attributes:
      """
      { "floating": true }
      """
    And the current account has 1 "license" for an existing "policy"
    And the first "license" has the following attributes:
      """
      { "maxCores": 8 }
      """
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/licenses/$0" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "id": "$licenses[0].id",
          "attributes": {
            "maxCores": 32
          }
        }
      }
      """
    Then the response status should be "200"
    And the response body should be a "license" with the maxCores "32"
    And the response should contain a valid signature header for "test1"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin removes a floating license's max cores override
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoints"
    And the current account has 1 "policy"
    And the first "policy" has the following attributes:
      """
      {
        "maxCores": 4,
        "floating": true
      }
      """
    And the current account has 1 "license" for an existing "policy"
    And the first "license" has the following attributes:
      """
      { "maxCores": 8 }
      """
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/licenses/$0" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "id": "$licenses[0].id",
          "attributes": {
            "maxCores": null
          }
        }
      }
      """
    Then the response status should be "200"
    And the response body should be a "license" with the maxCores "4"
    And the response should contain a valid signature header for "test1"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin overrides a floating license's max uses
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoints"
    And the current account has 1 "policy"
    And the first "policy" has the following attributes:
      """
      { "floating": true }
      """
    And the current account has 1 "license" for an existing "policy"
    And the first "license" has the following attributes:
      """
      { "maxUses": 100 }
      """
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/licenses/$0" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "id": "$licenses[0].id",
          "attributes": {
            "maxUses": 500
          }
        }
      }
      """
    Then the response status should be "200"
    And the response body should be a "license" with the maxUses "500"
    And the response should contain a valid signature header for "test1"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin removes a floating license's max uses override
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoints"
    And the current account has 1 "policy"
    And the first "policy" has the following attributes:
      """
      {
        "maxUses": 100,
        "floating": true
      }
      """
    And the current account has 1 "license" for an existing "policy"
    And the first "license" has the following attributes:
      """
      { "maxUses": 250 }
      """
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/licenses/$0" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "id": "$licenses[0].id",
          "attributes": {
            "maxUses": null
          }
        }
      }
      """
    Then the response status should be "200"
    And the response body should be a "license" with the maxUses "100"
    And the response should contain a valid signature header for "test1"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin overrides a floating license's max processes
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoints"
    And the current account has 1 "policy"
    And the first "policy" has the following attributes:
      """
      { "maxProcesses": 1 }
      """
    And the current account has 1 "license" for an existing "policy"
    And the first "license" has the following attributes:
      """
      { "maxProcesses": 2 }
      """
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/licenses/$0" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "attributes": {
            "maxProcesses": 10
          }
        }
      }
      """
    Then the response status should be "200"
    And the response body should be a "license" with the following attributes:
      """
      { "maxProcesses": 10 }
      """
    And the response should contain a valid signature header for "test1"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin removes a floating license's max machine override
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoints"
    And the current account has 1 "policy"
    And the first "policy" has the following attributes:
      """
      {
        "maxProcesses": 5,
        "floating": true
      }
      """
    And the current account has 1 "license" for an existing "policy"
    And the first "license" has the following attributes:
      """
      { "maxProcesses": 1 }
      """
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/licenses/$0" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "attributes": {
            "maxProcesses": null
          }
        }
      }
      """
    Then the response status should be "200"
    And the response body should be a "license" with the following attributes:
      """
      { "maxProcesses": 5 }
      """
    And the response should contain a valid signature header for "test1"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Developer updates a license expiry
    Given the current account is "test1"
    And the current account has 1 "developer"
    And I am a developer of account "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "license"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/licenses/$0" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "id": "$licenses[0].id",
          "attributes": {
            "expiry": "2016-09-05T22:53:37.000Z",
            "name": "Some Name"
          }
        }
      }
      """
    Then the response status should be "200"

  Scenario: Sales updates a license expiry
    Given the current account is "test1"
    And the current account has 1 "sales-agent"
    And I am a sales agent of account "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "license"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/licenses/$0" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "id": "$licenses[0].id",
          "attributes": {
            "expiry": "2016-09-05T22:53:37.000Z",
            "name": "Some Name"
          }
        }
      }
      """
    Then the response status should be "200"

  Scenario: Support updates a license expiry
    Given the current account is "test1"
    And the current account has 1 "support-agent"
    And I am a support agent of account "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "license"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/licenses/$0" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "id": "$licenses[0].id",
          "attributes": {
            "expiry": "2016-09-05T22:53:37.000Z",
            "name": "Some Name"
          }
        }
      }
      """
    Then the response status should be "200"

  Scenario: Read-only updates a license expiry
    Given the current account is "test1"
    And the current account has 1 "read-only"
    And I am a read only of account "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "license"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/licenses/$0" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "id": "$licenses[0].id",
          "attributes": {
            "expiry": "2016-09-05T22:53:37.000Z",
            "name": "Some Name"
          }
        }
      }
      """
    Then the response status should be "403"

  Scenario: Admin updates a license name
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "license"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/licenses/$0" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "id": "$licenses[0].id",
          "attributes": {
            "name": null
          }
        }
      }
      """
    Then the response status should be "200"
    And the response body should be a "license" with a nil name
    And the response should contain a valid signature header for "test1"
    And sidekiq should have 2 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin updates a license to protected
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "license"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/licenses/$0" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "id": "$licenses[0].id",
          "attributes": {
            "protected": true
          }
        }
      }
      """
    Then the response status should be "200"
    And the response body should be a "license" that is protected
    And the response should contain a valid signature header for "test1"
    And sidekiq should have 2 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin updates a license to protected
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "license"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/licenses/$0" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "id": "$licenses[0].id",
          "attributes": {
            "protected": false
          }
        }
      }
      """
    Then the response status should be "200"
    And the response body should be a "license" that is not protected
    And the response should contain a valid signature header for "test1"
    And sidekiq should have 2 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin removes a license's name
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "license"
    And the first "license" has the following attributes:
      """
      { "name": "Test License" }
      """
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/licenses/$0" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "id": "$licenses[0].id",
          "attributes": {
            "name": null
          }
        }
      }
      """
    Then the response status should be "200"
    And the response body should be a "license" with a nil name
    And the response should contain a valid signature header for "test1"
    And sidekiq should have 2 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  # Making sure schemed licenses do not re-encrypt/sign their key on update
  Scenario: Admin updates a license using scheme RSA_2048_PKCS1_PSS_SIGN to protected
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 1 "license" using "RSA_2048_PKCS1_PSS_SIGN"
    And the first "license" has the following attributes:
      """
      { "key": "test" }
      """
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/licenses/$0" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "id": "$licenses[0].id",
          "attributes": {
            "protected": false
          }
        }
      }
      """
    Then the response status should be "200"
    And the response body should be a "license" that is not protected
    And the response body should be a "license" with the key "test"
    And the response should contain a valid signature header for "test1"
    And sidekiq should have 2 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin updates a license policy
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "webhook-endpoints"
    And the current account has 2 "policies"
    And the current account has 1 "license"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/licenses/$0" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "relationships": {
            "policy": {
              "data": {
                "type": "policies",
                "id": "$policies[1]"
              }
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

  Scenario: Admin updates a license key
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "license"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/licenses/$0" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "attributes": {
            "key": "a"
          }
        }
      }
      """
    Then the response status should be "400"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Environment updates an isolated license
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And the current account has 1 isolated "webhook-endpoint"
    And the current account has 1 isolated "license"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    When I send a PATCH request to "/accounts/test1/licenses/$0" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "attributes": {
            "name": "Isolated License"
          }
        }
      }
      """
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should be a "license" with the following attributes:
      """
      { "name": "Isolated License" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Environment updates a shared license
    Given the current account is "test1"
    And the current account has 1 shared "environment"
    And the current account has 1 shared "webhook-endpoint"
    And the current account has 1 shared "license"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
    When I send a PATCH request to "/accounts/test1/licenses/$0" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "attributes": {
            "name": "Shared License"
          }
        }
      }
      """
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should be a "license" with the following attributes:
      """
      { "name": "Shared License" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Environment updates a global license
    Given the current account is "test1"
    And the current account has 1 shared "environment"
    And the current account has 1 shared "webhook-endpoint"
    And the current account has 1 global "license"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
    When I send a PATCH request to "/accounts/test1/licenses/$0" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "attributes": {
            "name": "Global License"
          }
        }
      }
      """
    Then the response status should be "403"

  Scenario: Product updates a license for their product
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "license" for the last "policy"
    And I am a product of account "test1"
    And I use an authentication token
    And the current account has 1 "license"
    When I send a PATCH request to "/accounts/test1/licenses/$0" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "attributes": {
            "key": "b"
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
          "pointer": "/data/attributes/key"
        }
      }
      """
    And sidekiq should have 0 "webhook" job
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Product attempts to update a license for another product
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And I am a product of account "test1"
    And I use an authentication token
    And the current account has 1 "license"
    When I send a PATCH request to "/accounts/test1/licenses/$0" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "attributes": {
            "key": "c"
          }
        }
      }
      """
    Then the response status should be "404"
    And the response should contain a valid signature header for "test1"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: License attempts to update themself
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 3 "licenses"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/licenses/$0" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "attributes": {
            "key": "x"
          }
        }
      }
      """
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: License attempts to update another license
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 3 "licenses"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/licenses/$1" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "attributes": {
            "key": "x"
          }
        }
      }
      """
    Then the response status should be "404"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: User attempts to update their license
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 3 "licenses"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And the current user has 3 "licenses"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/licenses/$0" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "attributes": {
            "key": "x"
          }
        }
      }
      """
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: User attempts to update a license
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 3 "licenses"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/licenses/$0" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "attributes": {
            "key": "x"
          }
        }
      }
      """
    Then the response status should be "404"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Anonymous user attempts to update a license for their account
    Given the current account is "test1"
    And the current account has 5 "webhook-endpoints"
    And the current account has 3 "licenses"
    When I send a PATCH request to "/accounts/test1/licenses/$0" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "attributes": {
            "key": "y"
          }
        }
      }
      """
    Then the response status should be "401"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin attempts to update a license for another account
    Given I am an admin of account "test2"
    But the current account is "test1"
    And the current account has 3 "webhook-endpoints"
    And the current account has 3 "licenses"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/licenses/$0" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "attributes": {
            "key": "z"
          }
        }
      }
      """
    Then the response status should be "401"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin updates a license key
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "license"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/licenses/$0" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "attributes": {
            "key": "xyz"
          }
        }
      }
      """
    Then the response status should be "400"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin updates a license expiry
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the first "webhook-endpoint" has the following attributes:
      """
      {
        "subscriptions": ["user.created", "license.created"]
      }
      """
    And the current account has 1 "license"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/licenses/$0" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "attributes": {
            "expiry": "2016-10-05T22:53:37.000Z",
            "suspended": true
          }
        }
      }
      """
    Then the response status should be "200"
    And the response body should be a "license" with the expiry "2016-10-05T22:53:37.000Z"
    And the response body should be a "license" that is suspended
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin updates a license expiry to a nil value
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "license"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/licenses/$0" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "attributes": {
            "expiry": null
          }
        }
      }
      """
    Then the response status should be "200"
    And the response body should be a "license" with a nil expiry
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin updates a license that has exceeded it's usage limit
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "policy"
    And the first "policy" has the following attributes:
      """
      { "maxUses": 10 }
      """
    And the current account has 1 "license"
    And the first "license" has the following attributes:
      """
      {
        "policyId": "$policies[0]",
        "uses": 11
      }
      """
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/licenses/$0" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "attributes": {
            "name": "Jackie's License"
          }
        }
      }
      """
    Then the response status should be "200"
    And the response body should be a "license" with the name "Jackie's License"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Product updates a license expiry for their product
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "license" for the last "policy"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/licenses/$0" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "attributes": {
            "expiry": "2016-10-05T22:53:37.000Z"
          }
        }
      }
      """
    Then the response status should be "200"
    And the response body should be a "license" with the expiry "2016-10-05T22:53:37.000Z"
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Product attempts to update the expiry of a license for another product
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And I am a product of account "test1"
    And I use an authentication token
    And the current account has 1 "license"
    When I send a PATCH request to "/accounts/test1/licenses/$0" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "attributes": {
            "expiry": "2016-10-05T22:53:37.000Z"
          }
        }
      }
      """
    Then the response status should be "404"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: User attempts to update a license expiry for their account
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 3 "licenses"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And the current user has 3 "licenses"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/licenses/$0" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "attributes": {
            "expiry": "2016-10-05T22:53:37.000Z"
          }
        }
      }
      """
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: User attempts to update a license name for their account
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 3 "licenses"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And the current user has 3 "licenses"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/licenses/$0" with the following:
      """
      {
        "data": {
          "type": "licenses",
          "attributes": {
            "name": "Test Name"
          }
        }
      }
      """
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job
