@api/v1
Feature: Show machine
  Background:
    Given the following "plan" rows exist:
      | id                                   | name       |
      | 9b96c003-85fa-40e8-a9ed-580491cd5d79 | Standard 1 |
      | 44c7918c-80ab-4a13-a831-a2c46cda85c6 | Ent 1      |
    Given the following "account" rows exist:
      | name   | slug  | plan_id                              |
      | Test 1 | test1 | 9b96c003-85fa-40e8-a9ed-580491cd5d79 |
      | Test 2 | test2 | 9b96c003-85fa-40e8-a9ed-580491cd5d79 |
      | Ent 1  | ent1  | 44c7918c-80ab-4a13-a831-a2c46cda85c6 |
    And I send and accept JSON

  Scenario: Endpoint should be inaccessible when account is disabled
    Given the account "test1" is canceled
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "machine"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/machines/$0"
    Then the response status should be "403"

  Scenario: Admin retrieves a machine for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 3 "machines"
    And the first "machine" has the following attributes:
      """
      { "fingerprint": "4d:Eq:UV:D3:XZ:tL:WN:Bz:mA:Eg:E6:Mk:YX:dK:NC" }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/machines/$0"
    And the response body should be a "machine" with the fingerprint "4d:Eq:UV:D3:XZ:tL:WN:Bz:mA:Eg:E6:Mk:YX:dK:NC"
    Then the response status should be "200"
    And the response body should be a "machine"
    And the response should contain a valid signature header for "test1"

  Scenario: Developer retrieves a machine for their account
    Given the current account is "test1"
    And the current account has 1 "developer"
    And I am a developer of account "test1"
    And the current account has 3 "machines"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/machines/$0"
    Then the response status should be "200"

  Scenario: Sales retrieves a machine for their account
    Given the current account is "test1"
    And the current account has 1 "sales-agent"
    And I am a sales agent of account "test1"
    And the current account has 3 "machines"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/machines/$0"
    Then the response status should be "200"

  Scenario: Support retrieves a machine for their account
    Given the current account is "test1"
    And the current account has 1 "support-agent"
    And I am a support agent of account "test1"
    And the current account has 3 "machines"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/machines/$0"
    Then the response status should be "200"

  Scenario: Read-only retrieves a machine for their account
    Given the current account is "test1"
    And the current account has 1 "read-only"
    And I am a read only of account "test1"
    And the current account has 3 "machines"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/machines/$0"
    Then the response status should be "200"

  Scenario: Admin retrieves a machine for their account by fingerprint
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 3 "machines"
    And the first "machine" has the following attributes:
      """
      { "fingerprint": "4d:Eq:UV:D3:XZ:tL:WN:Bz:mA:Eg:E6:Mk:YX:dK:NC" }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/machines/4d:Eq:UV:D3:XZ:tL:WN:Bz:mA:Eg:E6:Mk:YX:dK:NC"
    And the response body should be a "machine" with the fingerprint "4d:Eq:UV:D3:XZ:tL:WN:Bz:mA:Eg:E6:Mk:YX:dK:NC"
    Then the response status should be "200"
    And the response body should be a "machine"
    And the response should contain a valid signature header for "test1"

  Scenario: Admin retrieves a machine for their account by UUID fingerprint
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 3 "machines"
    And the first "machine" has the following attributes:
      """
      { "fingerprint": "a06b4343-d2cf-45e7-b9a2-b11c618993f3" }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/machines/a06b4343-d2cf-45e7-b9a2-b11c618993f3"
    And the response body should be a "machine" with the fingerprint "a06b4343-d2cf-45e7-b9a2-b11c618993f3"
    Then the response status should be "200"
    And the response body should be a "machine"
    And the response should contain a valid signature header for "test1"

  Scenario: Admin retrieves a license for their account that has a user
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "user"
    And the current account has 1 "license"
    And the first "license" has the following attributes:
      """
      { "userId": "$users[1]" }
      """
    And the current account has 3 "machines"
    And all "machines" have the following attributes:
      """
      { "licenseId": "$licenses[0]" }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/machines/$0"
    Then the response status should be "200"
    And the response body should be a "machine"
    And the response should contain a valid signature header for "test1"
    And the response body should be a "machine" with the following relationships:
      """
      {
        "user": {
          "links": { "related": "/v1/accounts/$account/machines/$machines[0]/user" },
          "data": { "type": "users", "id": "$users[1]" }
        }
      }
      """

  Scenario: Admin retrieves a license for their account that doesn't have a user
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "license"
    And the first "license" has the following attributes:
      """
      { "userId": null }
      """
    And the current account has 1 "machine"
    And the first "machine" has the following attributes:
      """
      { "licenseId": "$licenses[0]" }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/machines/$0"
    Then the response status should be "200"
    And the response body should be a "machine"
    And the response should contain a valid signature header for "test1"
    And the response body should be a "machine" with the following relationships:
      """
      {
        "user": {
          "links": { "related": "/v1/accounts/$account/machines/$machines[0]/user" },
          "data": null
        }
      }
      """

  Scenario: Admin retrieves an invalid machine for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/machines/invalid"
    Then the response status should be "404"
    And the first error should have the following properties:
      """
      {
        "title": "Not found",
        "detail": "The requested machine 'invalid' was not found",
        "code": "NOT_FOUND"
      }
      """

  Scenario: Admin retrieves a machine for their account with a newline character in the ID (ID without newline exists)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "machine"
    And the first "machine" has the following attributes:
      """
      { "id": "95a4a5dc-fd79-4108-ba73-c3610ccfcab1" }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/machines/95a4a5dc-fd79-4108-ba73-c3610ccfcab1%0A"
    Then the response status should be "404"
    And the first error should have the following properties:
      """
      {
        "title": "Not found",
        "detail": "The requested machine '95a4a5dc-fd79-4108-ba73-c3610ccfcab1\n' was not found",
        "code": "NOT_FOUND"
      }
      """

  Scenario: Admin retrieves a machine for their account with a newline character in the ID (ID does not exist)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/machines/95a4a5dc-fd79-4108-ba73-c3610ccfcab1%0A"
    Then the response status should be "404"
    And the first error should have the following properties:
      """
      {
        "title": "Not found",
        "detail": "The requested machine '95a4a5dc-fd79-4108-ba73-c3610ccfcab1\n' was not found",
        "code": "NOT_FOUND"
      }
      """

  Scenario: Product retrieves a machine for their product
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "license" for the last "policy"
    And the current account has 1 "machine" for the last "license"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/machines/$0"
    Then the response status should be "200"
    And the response body should be a "machine"

  Scenario: User retrieves a machine for their license
    Given the current account is "test1"
    And the current account has 1 "user"
    And the current account has 1 "license" for the last "user"
    And the current account has 1 "machine" for the last "license"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/machines/$0"
    Then the response status should be "200"
    And the response body should be a "machine"

  Scenario: License retrieves a machine for their license
    Given the current account is "test1"
    And the current account has 1 "license"
    And the current account has 1 "machine"
    And all "machines" have the following attributes:
      """
      { "licenseId": "$licenses[0]" }
      """
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/machines/$0"
    Then the response status should be "200"
    And the response body should be a "machine"

  Scenario: License retrieves a machine for another license
    Given the current account is "test1"
    And the current account has 2 "licenses"
    And the current account has 1 "machine"
    And all "machines" have the following attributes:
      """
      { "licenseId": "$licenses[1]" }
      """
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/machines/$0"
    Then the response status should be "404"

  Scenario: License retrieves a machine by fingerprint that matches the machine of another license
    Given the current account is "test1"
    And the current account has 2 "licenses"
    And the current account has 2 "machines"
    And the first "machine" has the following attributes:
      """
      {
        "licenseId": "$licenses[1]",
        "fingerprint": "xxx"
      }
      """
    And the second "machine" has the following attributes:
      """
      {
        "licenseId": "$licenses[0]",
        "fingerprint": "xxx"
      }
      """
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/machines/xxx"
    Then the response status should be "200"
    And the response body should be a "machine"

  Scenario: Product attempts to retrieve a machine for another product
    Given the current account is "test1"
    And the current account has 1 "product"
    And I am a product of account "test1"
    And I use an authentication token
    And the current account has 1 "machine"
    When I send a GET request to "/accounts/test1/machines/$0"
    Then the response status should be "404"

  Scenario: Admin attempts to retrieve a machine for another account
    Given I am an admin of account "test2"
    But the current account is "test1"
    And the account "test1" has 3 "machines"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/machines/$0"
    Then the response status should be "401"
    And the response body should be an array of 1 error

  @ee
  Scenario: Admin retrieves an isolated machine for their account (global environment)
    Given the current account is "ent1"
    And the current account has 1 isolated "machine"
    And the current account has 1 shared "machine"
    And the current account has 1 global "machine"
    And the current account has 1 "admin"
    And I am the last admin of account "ent1"
    And I use an authentication token
    When I send a GET request to "/accounts/ent1/machines/$0"
    Then the response status should be "404"

  @ee
  Scenario: Admin retrieves a shared machine for their account (global environment)
    Given the current account is "ent1"
    And the current account has 1 isolated "machine"
    And the current account has 1 shared "machine"
    And the current account has 1 global "machine"
    And the current account has 1 "admin"
    And I am the last admin of account "ent1"
    And I use an authentication token
    When I send a GET request to "/accounts/ent1/machines/$1"
    Then the response status should be "404"

  @ee
  Scenario: Admin retrieves a global machine for their account (global environment)
    Given the current account is "ent1"
    And the current account has 1 isolated "machine"
    And the current account has 1 shared "machine"
    And the current account has 1 global "machine"
    And the current account has 1 "admin"
    And I am the last admin of account "ent1"
    And I use an authentication token
    When I send a GET request to "/accounts/ent1/machines/$2"
    Then the response status should be "200"
    And the response body should be a "machine" with the following relationships:
      """
      {
        "environment": {
          "links": { "related": null },
          "data": null
        }
      }
      """

  @ee
  Scenario: Admin retrieves an isolated machine for their account (isolated environment)
    Given the current account is "ent1"
    And the current account has 1 isolated "environment"
    And the current account has 1 shared "environment"
    And the current environment is "isolated"
    And the current account has 1 isolated "machine"
    And the current account has 1 shared "machine"
    And the current account has 1 global "machine"
    And the current account has 1 "admin"
    And I am the last admin of account "ent1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    When I send a GET request to "/accounts/ent1/machines/$0"
    Then the response status should be "200"
    And the response body should be a "machine" with the following relationships:
      """
      {
        "environment": {
          "links": { "related": "/v1/accounts/$account/environments/$environments[0]" },
          "data": { "type": "environments", "id": "$environments[0]" }
        }
      }
      """
    And the response should contain the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """

  @ee
  Scenario: Admin retrieves an isolated machine for their account (shared environment)
    Given the current account is "ent1"
    And the current account has 1 isolated "environment"
    And the current account has 1 shared "environment"
    And the current environment is "shared"
    And the current account has 1 isolated "machine"
    And the current account has 1 shared "machine"
    And the current account has 1 global "machine"
    And the current account has 1 "admin"
    And I am the last admin of account "ent1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
    When I send a GET request to "/accounts/ent1/machines/$0"
    Then the response status should be "404"
    And the response should contain the following headers:
      """
      { "Keygen-Environment": "shared" }
      """

  @ee
  Scenario: Admin retrieves a shared machine for their account (isolated environment)
    Given the current account is "ent1"
    And the current account has 1 isolated "environment"
    And the current account has 1 shared "environment"
    And the current environment is "isolated"
    And the current account has 1 isolated "machine"
    And the current account has 1 shared "machine"
    And the current account has 1 global "machine"
    And the current account has 1 "admin"
    And I am the last admin of account "ent1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    When I send a GET request to "/accounts/ent1/machines/$1"
    Then the response status should be "404"
    And the response should contain the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """

  @ee
  Scenario: Admin retrieves a shared machine for their account (shared environment)
    Given the current account is "ent1"
    And the current account has 1 isolated "environment"
    And the current account has 1 shared "environment"
    And the current environment is "shared"
    And the current account has 1 isolated "machine"
    And the current account has 1 shared "machine"
    And the current account has 1 global "machine"
    And the current account has 1 "admin"
    And I am the last admin of account "ent1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
    When I send a GET request to "/accounts/ent1/machines/$1"
    Then the response status should be "200"
    And the response body should be a "machine" with the following relationships:
      """
      {
        "environment": {
          "links": { "related": "/v1/accounts/$account/environments/$environments[1]" },
          "data": { "type": "environments", "id": "$environments[1]" }
        }
      }
      """
    And the response should contain the following headers:
      """
      { "Keygen-Environment": "shared" }
      """

  @ce
  Scenario: Environment retrieves a machine (isolated)
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And the current account has 1 isolated "machine"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    When I send a GET request to "/accounts/test1/machines/$0"
    Then the response status should be "400"

  @ee
  Scenario: Environment retrieves a machine (isolated)
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And the current account has 1 isolated "machine"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    When I send a GET request to "/accounts/test1/machines/$0"
    Then the response status should be "200"
    And the response body should be a "machine"

  @ee
  Scenario: Environment retrieves a machine (shared)
    Given the current account is "test1"
    And the current account has 1 shared "environment"
    And the current account has 1 shared "machine"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
    When I send a GET request to "/accounts/test1/machines/$0"
    Then the response status should be "200"
    And the response body should be a "machine"

  @ee
  Scenario: Environment retrieves a machine (global)
    Given the current account is "test1"
    And the current account has 1 shared "environment"
    And the current account has 1 global "machine"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
    When I send a GET request to "/accounts/test1/machines/$0"
    Then the response status should be "200"
    And the response body should be a "machine"

  Scenario: License retrieves a machine by fingerprint with a newline (no newline)
    Given the current account is "test1"
    And the current account has 1 "license"
    And the current account has 1 "machine" for the last "license"
    And the last "machine" has the following attributes:
      """
      { "fingerprint": "foo\n" }
      """
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/machines/foo"
    Then the response status should be "404"

  Scenario: License retrieves a machine by fingerprint with a newline (newline)
    Given the current account is "test1"
    And the current account has 1 "license"
    And the current account has 1 "machine" for the last "license"
    And the last "machine" has the following attributes:
      """
      { "fingerprint": "foo\n" }
      """
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/machines/foo%0A"
    Then the response status should be "200"
    And the response body should be a "machine"
