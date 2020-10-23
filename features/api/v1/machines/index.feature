@api/v1
Feature: List machines

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
    And the JSON response should be an array with 3 "machines"
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

  Scenario: Admin retrieves a paginated list of machines
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 20 "machines"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/machines?page[number]=2&page[size]=5"
    Then the response status should be "200"
    And the JSON response should be an array with 5 "machines"

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
    And the JSON response should be an array with 1 "machine"

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

  Scenario: Admin retrieves all machines without a limit for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 20 "machines"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/machines"
    Then the response status should be "200"
    And the JSON response should be an array with 10 "machines"

  Scenario: Admin retrieves all machines with a low limit for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 10 "machines"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/machines?limit=5"
    Then the response status should be "200"
    And the JSON response should be an array with 5 "machines"

  Scenario: Admin retrieves all machines with a high limit for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 20 "machines"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/machines?limit=20"
    Then the response status should be "200"
    And the JSON response should be an array with 20 "machines"

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
    And the JSON response should be an array with 1 "machine"

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
    And the JSON response should be an array with 1 "machine"

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
    And the JSON response should be an array with 1 "machine"

  Scenario: Admin retrieves all machines filtered by metadata node ID
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
    And the JSON response should be an array with 1 "machine"

  Scenario: Product retrieves all machines for their product
    Given the current account is "test1"
    And the current account has 1 "product"
    And I am a product of account "test1"
    And I use an authentication token
    And the current account has 3 "machines"
    And the current product has 1 "machine"
    When I send a GET request to "/accounts/test1/machines"
    Then the response status should be "200"
    And the JSON response should be an array with 1 "machine"

  Scenario: Admin attempts to retrieve all machines for another account
    Given I am an admin of account "test2"
    But the current account is "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/machines"
    Then the response status should be "401"
    And the JSON response should be an array of 1 error

  Scenario: User attempts to retrieve all machines for their account
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
    And the JSON response should be an array with 3 "machines"

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
    And the JSON response should be an array with 1 "machine"

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
    And the JSON response should be an array with 0 "machines"

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
    And the JSON response should be an array with 3 "machines"

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
    And the JSON response should be an array with 0 "machines"

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
    And the JSON response should be an array with 1 "machine"

  Scenario: License retrieves all machines for their license with no matches
    Given the current account is "test1"
    And the current account has 1 "license"
    And the current account has 5 "machines"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/machines"
    Then the response status should be "200"
    And the JSON response should be an array with 0 "machines"
