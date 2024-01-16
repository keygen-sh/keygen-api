@api/v1
Feature: List machines
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
    And the current account has 2 "machines"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/machines"
    Then the response status should be "403"

  Scenario: Admin retrieves all machines for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 3 "machines"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/machines"
    Then the response status should be "200"
    And the response body should be an array with 3 "machines"
    And the response should contain a valid signature header for "test1"

  Scenario: Developer retrieves all machines for their account
    Given the current account is "test1"
    And the current account has 1 "developer"
    And I am a developer of account "test1"
    And the current account has 3 "machines"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/machines"
    Then the response status should be "200"

  Scenario: Sales retrieves all machines for their account
    Given the current account is "test1"
    And the current account has 1 "sales-agent"
    And I am a sales agent of account "test1"
    And the current account has 3 "machines"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/machines"
    Then the response status should be "200"

  Scenario: Support retrieves all machines for their account
    Given the current account is "test1"
    And the current account has 1 "support-agent"
    And I am a support agent of account "test1"
    And the current account has 3 "machines"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/machines"
    Then the response status should be "200"

  Scenario: Read-only retrieves all machines for their account
    Given the current account is "test1"
    And the current account has 1 "read-only"
    And I am a read only of account "test1"
    And the current account has 3 "machines"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/machines"
    Then the response status should be "200"

  Scenario: Admin retrieves a paginated list of machines
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 20 "machines"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/machines?page[number]=2&page[size]=5"
    Then the response status should be "200"
    And the response body should be an array with 5 "machines"

  Scenario: Admin retrieves a paginated list of machines scoped to policy
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "policy"
    And the current account has 1 "license"
    And the first "license" has the following attributes:
      """
      { "policyId": "$policies[0]" }
      """
    And the current account has 20 "machines"
    And the first "machine" has the following attributes:
      """
      { "licenseId": "$licenses[0]" }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/machines?page[number]=1&page[size]=100&policy=$policies[0]"
    Then the response status should be "200"
    And the response body should be an array with 1 "machine"
    And the response body should contain the following links:
      """
      {
        "self": "/v1/accounts/test1/machines?page[number]=1&page[size]=100&policy=$policies[0]",
        "prev": null,
        "next": null,
        "first": "/v1/accounts/test1/machines?page[number]=1&page[size]=100&policy=$policies[0]",
        "last": "/v1/accounts/test1/machines?page[number]=1&page[size]=100&policy=$policies[0]",
        "meta": {
          "pages": 1,
          "count": 1
        }
      }
      """

  Scenario: Admin retrieves a paginated list of machines scoped to user
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "policy"
    And the current account has 1 "user"
    And the current account has 1 "license"
    And the first "license" has the following attributes:
      """
      {
        "policyId": "$policies[0]",
        "userId": "$users[1]"
      }
      """
    And the current account has 20 "machines"
    And the first "machine" has the following attributes:
      """
      { "licenseId": "$licenses[0]" }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/machines?page[number]=1&page[size]=100&user=$users[1]"
    Then the response status should be "200"
    And the response body should be an array with 1 "machine"
    And the response body should contain the following links:
      """
      {
        "self": "/v1/accounts/test1/machines?page[number]=1&page[size]=100&user=$users[1]",
        "prev": null,
        "next": null,
        "first": "/v1/accounts/test1/machines?page[number]=1&page[size]=100&user=$users[1]",
        "last": "/v1/accounts/test1/machines?page[number]=1&page[size]=100&user=$users[1]",
        "meta": {
          "pages": 1,
          "count": 1
        }
      }
      """

  Scenario: Admin retrieves a paginated list of machines with a page size that is too high
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 20 "machines"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/machines?page[number]=1&page[size]=250"
    Then the response status should be "400"

  Scenario: Admin retrieves a paginated list of machines with a page size that is too low
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 20 "machines"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/machines?page[number]=1&page[size]=0"
    Then the response status should be "400"

  Scenario: Admin retrieves a paginated list of machines with an invalid page number
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 20 "machines"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/machines?page[number]=-1&page[size]=10"
    Then the response status should be "400"

  Scenario: Admin retrieves a paginated list of machines with an invalid page param
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 20 "machines"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/machines?page=1&size=100"
    Then the response status should be "400"

  Scenario: Admin retrieves all machines without a limit for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 20 "machines"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/machines"
    Then the response status should be "200"
    And the response body should be an array with 10 "machines"

  Scenario: Admin retrieves all machines with a low limit for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 10 "machines"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/machines?limit=5"
    Then the response status should be "200"
    And the response body should be an array with 5 "machines"

  Scenario: Admin retrieves all machines with a high limit for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 20 "machines"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/machines?limit=20"
    Then the response status should be "200"
    And the response body should be an array with 20 "machines"

  Scenario: Admin retrieves all machines with a limit that is too high
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "machines"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/machines?limit=900"
    Then the response status should be "400"

  Scenario: Admin retrieves all machines with a limit that is too low
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "machines"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/machines?limit=0"
    Then the response status should be "400"

  Scenario: Admin retrieves all machines filtered by fingerprint
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 20 "machines"
    And the first "machine" has the following attributes:
      """
      { "fingerprint": "foo:bar:baz:qux" }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/machines?fingerprint=foo:bar:baz:qux"
    Then the response status should be "200"
    And the response body should be an array with 1 "machine"

  Scenario: Admin retrieves all machines filtered by IP
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 20 "machines"
    And the first "machine" has the following attributes:
      """
      { "ip": "127.0.1.1" }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/machines?ip=127.0.1.1"
    Then the response status should be "200"
    And the response body should be an array with 1 "machine"

  Scenario: Admin retrieves all machines filtered by hostname
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 20 "machines"
    And the first "machine" has the following attributes:
      """
      { "hostname": "SomeHostname" }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/machines?hostname=SomeHostname"
    Then the response status should be "200"
    And the response body should be an array with 1 "machine"

  Scenario: Admin retrieves all machines filtered by metadata node ID (camelcase)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 11 "machines"
    And the first "machine" has the following attributes:
      """
      {
        "metadata": {
          "nodeId": "68666bf8b"
        }
      }
      """
    And the second "machine" has the following attributes:
      """
      {
        "metadata": {
          "nodeId": "68666bf80"
        }
      }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/machines?metadata[nodeId]=68666bf8b"
    Then the response status should be "200"
    And the response body should be an array with 1 "machine"

  Scenario: Admin retrieves all machines filtered by metadata node ID (snakecase)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 11 "machines"
    And the first "machine" has the following attributes:
      """
      {
        "metadata": {
          "node_id": "68666bf8b"
        }
      }
      """
    And the second "machine" has the following attributes:
      """
      {
        "metadata": {
          "node_id": "68666bf80"
        }
      }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/machines?metadata[node_id]=68666bf8b"
    Then the response status should be "200"
    And the response body should be an array with 1 "machine"

  Scenario: Admin retrieves all alive machines
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "policies"
    And the first "policy" has the following attributes:
      """
      { "heartbeatDuration": $time.30.minutes.to_i }
      """
    And the second "policy" has the following attributes:
      """
      { "heartbeatDuration": null }
      """
    And the current account has 2 "licenses"
    And the first "license" has the following attributes:
      """
      { "policyId": "$policies[0]" }
      """
    And the second "license" has the following attributes:
      """
      { "policyId": "$policies[1]" }
      """
    And the current account has 5 "machines"
    And the first "machine" has the following attributes:
      """
      {
        "lastHeartbeatAt": "$time.1.minutes.ago",
        "licenseId": "$licenses[0]"
      }
      """
    And the second "machine" has the following attributes:
      """
      {
        "lastHeartbeatAt": "$time.32.minutes.ago",
        "licenseId": "$licenses[0]"
      }
      """
    And the third "machine" has the following attributes:
      """
      {
        "lastHeartbeatAt": "$time.11.minutes.ago",
        "licenseId": "$licenses[0]"
      }
      """
    And the fourth "machine" has the following attributes:
      """
      {
        "lastHeartbeatAt": null,
        "licenseId": "$licenses[1]"
      }
      """
    And the fifth "machine" has the following attributes:
      """
      {
        "lastHeartbeatAt": "$time.11.minutes.ago",
        "licenseId": "$licenses[1]"
      }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/machines?status=alive"
    Then the response status should be "200"
    And the response body should be an array with 3 "machines"

  Scenario: Admin retrieves all dead machines
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "policies"
    And the first "policy" has the following attributes:
      """
      { "heartbeatDuration": $time.30.minutes.to_i }
      """
    And the second "policy" has the following attributes:
      """
      { "heartbeatDuration": null }
      """
    And the current account has 2 "licenses"
    And the first "license" has the following attributes:
      """
      { "policyId": "$policies[0]" }
      """
    And the second "license" has the following attributes:
      """
      { "policyId": "$policies[1]" }
      """
    And the current account has 5 "machines"
    And the first "machine" has the following attributes:
      """
      {
        "lastHeartbeatAt": "$time.1.minutes.ago",
        "licenseId": "$licenses[0]"
      }
      """
    And the second "machine" has the following attributes:
      """
      {
        "lastHeartbeatAt": "$time.31.minutes.ago",
        "licenseId": "$licenses[0]"
      }
      """
    And the third "machine" has the following attributes:
      """
      {
        "lastHeartbeatAt": "$time.11.minutes.ago",
        "licenseId": "$licenses[0]"
      }
      """
    And the fourth "machine" has the following attributes:
      """
      {
        "lastHeartbeatAt": null,
        "licenseId": "$licenses[1]"
      }
      """
    And the fifth "machine" has the following attributes:
      """
      {
        "lastHeartbeatAt": "$time.1.day.ago",
        "licenseId": "$licenses[1]"
      }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/machines?status=dead"
    Then the response status should be "200"
    And the response body should be an array with 2 "machines"

  Scenario: Product retrieves all machines for their product
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "license" for the last "policy"
    And the current account has 2 "machines" for the last "license"
    And the current account has 2 "machines"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/machines"
    Then the response status should be "200"
    And the response body should be an array with 2 "machines"

  Scenario: Admin attempts to retrieve all machines for another account
    Given I am an admin of account "test2"
    But the current account is "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/machines"
    Then the response status should be "401"
    And the response body should be an array of 1 error

  Scenario: User attempts to retrieve all machines for their group
    Given the current account is "test1"
    And the current account has 2 "groups"
    And the current account has 1 "user"
    And the current account has 1 "group-owner"
    And the last "group-owner" has the following attributes:
      """
      {
        "groupId": "$groups[0]",
        "userId": "$users[1]"
      }
      """
    And the current account has 1 "license"
    And the last "license" has the following attributes:
      """
      { "userId": "$users[1]" }
      """
    And the current account has 7 "machines"
    And the first "machine" has the following attributes:
      """
      { "groupId": "$groups[0]" }
      """
    And the second "machines" has the following attributes:
      """
      { "groupId": "$groups[0]" }
      """
    And the third "machines" has the following attributes:
      """
      { "groupId": "$groups[0]" }
      """
    And the fourth "machines" has the following attributes:
      """
      { "groupId": "$groups[1]" }
      """
    And the fifth "machines" has the following attributes:
      """
      { "licenseId": "$licenses[0]" }
      """
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/machines"
    Then the response status should be "200"
    And the response body should be an array with 1 "machine"

  Scenario: User attempts to retrieve all machines for their account (license owner)
    Given the current account is "test1"
    And the current account has 1 "user"
    And the current account has 1 "license"
    And the first "license" has the following attributes:
      """
      { "userId": "$users[1]" }
      """
    And I am a user of account "test1"
    And the current account has 5 "machines"
    And 3 "machines" have the following attributes:
      """
      { "licenseId": "$licenses[0]" }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/machines"
    Then the response status should be "200"
    And the response body should be an array with 3 "machines"

  Scenario: User attempts to retrieve all machines for their account (license user)
    Given the current account is "test1"
    And the current account has 1 "user"
    And the current account has 1 "license"
    And the current account has 1 "license-user" for the last "license" and the last "user"
    And the current account has 3 "machines" for the last "license"
    And the current account has 2 "machines"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/machines"
    Then the response status should be "200"
    And the response body should be an array with 3 "machines"

  Scenario: User attempts to retrieve machines for their account scoped by a fingerprint that exists
    Given the current account is "test1"
    And the current account has 1 "user"
    And the current account has 1 "license"
    And the first "license" has the following attributes:
      """
      { "userId": "$users[1]" }
      """
    And I am a user of account "test1"
    And the current account has 5 "machines"
    And 5 "machines" have the following attributes:
      """
      { "licenseId": "$licenses[0]" }
      """
    And the third "machine" has the following attributes:
      """
      { "fingerprint": "test" }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/machines?fingerprint=test"
    Then the response status should be "200"
    And the response body should be an array with 1 "machine"

  Scenario: User attempts to retrieve machines for their account scoped by a fingerprint that doesn't exist
    Given the current account is "test1"
    And the current account has 1 "user"
    And the current account has 1 "license"
    And the first "license" has the following attributes:
      """
      { "userId": "$users[1]" }
      """
    And I am a user of account "test1"
    And the current account has 5 "machines"
    And 5 "machines" have the following attributes:
      """
      { "licenseId": "$licenses[0]" }
      """
    And the third "machine" has the following attributes:
      """
      { "fingerprint": "test" }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/machines?fingerprint=invalid"
    Then the response status should be "200"
    And the response body should be an array with 0 "machines"

  Scenario: User attempts to retrieve machines for their account scoped by a license key that exists
    Given the current account is "test1"
    And the current account has 1 "user"
    And the current account has 1 "license"
    And the first "license" has the following attributes:
      """
      { "userId": "$users[1]", "key": "a-license-key" }
      """
    And I am a user of account "test1"
    And the current account has 5 "machines"
    And 3 "machines" have the following attributes:
      """
      { "licenseId": "$licenses[0]" }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/machines?key=a-license-key"
    Then the response status should be "200"
    And the response body should be an array with 3 "machines"

Scenario: User attempts to retrieve machines for their account scoped by a license key that doesn't exist
    Given the current account is "test1"
    And the current account has 1 "user"
    And the current account has 1 "license"
    And the first "license" has the following attributes:
      """
      { "userId": "$users[1]", "key": "a-license-key" }
      """
    And I am a user of account "test1"
    And the current account has 5 "machines"
    And 5 "machines" have the following attributes:
      """
      { "licenseId": "$licenses[0]" }
      """
    And the third "machine" has the following attributes:
      """
      { "fingerprint": "test" }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/machines?key=invalid"
    Then the response status should be "200"
    And the response body should be an array with 0 "machines"

  Scenario: License retrieves all machines for their license with matches
    Given the current account is "test1"
    And the current account has 1 "license"
    And the current account has 5 "machines"
    And the first "machine" has the following attributes:
      """
      { "licenseId": "$licenses[0]" }
      """
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/machines"
    Then the response status should be "200"
    And the response body should be an array with 1 "machine"

  Scenario: License retrieves all machines for their license with no matches
    Given the current account is "test1"
    And the current account has 1 "license"
    And the current account has 5 "machines"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/machines"
    Then the response status should be "200"
    And the response body should be an array with 0 "machines"

  @ee
  Scenario: Admin retrieves all machines for an isolated environment
    And the current account is "ent1"
    And the current account has 1 isolated "environment"
    And the current environment is "isolated"
    And the current account has 3 isolated "machines"
    And the current account has 3 shared "machines"
    And the current account has 3 global "machines"
    And the current account has 1 "admin"
    And I am the last admin of account "ent1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    When I send a GET request to "/accounts/ent1/machines"
    Then the response status should be "200"
    And the response body should be an array with 3 "machines"
    And the response body should be an array of 3 "machines" with the following relationships:
      """
      {
        "environment": {
          "links": { "related": "/v1/accounts/$account/environments/$environments[0]" },
          "data": { "type": "environments", "id": "$environments[0]" }
        }
      }
      """

  @ee
  Scenario: Admin retrieves all machines for a shared environment
    And the current account is "ent1"
    And the current account has 1 shared "environment"
    And the current environment is "shared"
    And the current account has 3 isolated "machines"
    And the current account has 3 shared "machines"
    And the current account has 3 global "machines"
    And the current account has 1 "admin"
    And I am the last admin of account "ent1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
    When I send a GET request to "/accounts/ent1/machines"
    Then the response status should be "200"
    And the response body should be an array with 6 "machines"
    And the response body should be an array of 3 "machines" with the following relationships:
      """
      {
        "environment": {
          "links": { "related": "/v1/accounts/$account/environments/$environments[0]" },
          "data": { "type": "environments", "id": "$environments[0]" }
        }
      }
      """
    And the response body should be an array of 3 "machines" with the following relationships:
      """
      {
        "environment": {
          "links": { "related": null },
          "data": null
        }
      }
      """

  @ee
  Scenario: Admin retrieves all machines in the global environment
    Given I am an admin of account "ent1"
    And the current account is "ent1"
    And the current account has 3 isolated "machines"
    And the current account has 3 shared "machines"
    And the current account has 3 global "machines"
    And I use an authentication token
    When I send a GET request to "/accounts/ent1/machines"
    Then the response status should be "200"
    And the response body should be an array with 3 "machines"
    And the response body should be an array of 3 "machines" with the following relationships:
      """
      {
        "environment": {
          "links": { "related": null },
          "data": null
        }
      }
      """

    @ee
  Scenario: Environment retrieves all isolated machines
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And the current account has 3 isolated "machines"
    And the current account has 3 shared "machines"
    And the current account has 3 global "machines"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    When I send a GET request to "/accounts/test1/machines"
    Then the response status should be "200"
    And the response body should be an array with 3 "machines"
    And the response body should be an array of 3 "machines" with the following relationships:
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
  Scenario: Environment retrieves all shared machines
    Given the current account is "test1"
    And the current account has 1 shared "environment"
    And the current account has 3 isolated "machines"
    And the current account has 3 shared "machines"
    And the current account has 3 global "machines"
    And I am an environment of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/machines?environment=shared"
    Then the response status should be "200"
    And the response body should be an array with 6 "machines"
    And the response body should be an array of 3 "machines" with the following relationships:
      """
      {
        "environment": {
          "links": { "related": "/v1/accounts/$account/environments/$environments[0]" },
          "data": { "type": "environments", "id": "$environments[0]" }
        }
      }
      """
    And the response body should be an array of 3 "machines" with the following relationships:
      """
      {
        "environment": {
          "links": { "related": null },
          "data": null
        }
      }
      """
    And the response should contain the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
