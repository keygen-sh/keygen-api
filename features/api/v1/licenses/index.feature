@api/v1
Feature: List license

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
    And the current account has 2 "licenses"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses"
    Then the response status should be "403"

  Scenario: Admin retrieves all licenses for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 3 "licenses"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses"
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the JSON response should be an array with 3 "licenses"

  Scenario: Developer retrieves all licenses for their account
    Given the current account is "test1"
    And the current account has 1 "developer"
    And I am a developer of account "test1"
    And the current account has 2 "licenses"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses"
    Then the response status should be "200"
    And the JSON response should be an array with 2 "licenses"

  Scenario: Sales retrieves all licenses for their account
    Given the current account is "test1"
    And the current account has 1 "sales-agent"
    And I am a sales agent of account "test1"
    And the current account has 2 "licenses"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses"
    Then the response status should be "200"
    And the JSON response should be an array with 2 "licenses"

  Scenario: Support retrieves all licenses for their account
    Given the current account is "test1"
    And the current account has 1 "support-agent"
    And I am a support agent of account "test1"
    And the current account has 2 "licenses"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses"
    Then the response status should be "200"
    And the JSON response should be an array with 2 "licenses"

  Scenario: Admin retrieves a paginated list of licenses
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 20 "licenses"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses?page[number]=4&page[size]=5"
    Then the response status should be "200"
    And the JSON response should be an array with 5 "licenses"
    And the JSON response should contain the following links:
      """
      {
        "self": "/v1/accounts/test1/licenses?page[number]=4&page[size]=5",
        "prev": "/v1/accounts/test1/licenses?page[number]=3&page[size]=5",
        "first": "/v1/accounts/test1/licenses?page[number]=1&page[size]=5",
        "meta": {
          "pages": 4,
          "count": 20
        }
      }
      """
    And the response should contain a valid signature header for "test1"

  Scenario: Admin retrieves a paginated list of licenses with a page size that is too high
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 20 "licenses"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses?page[number]=1&page[size]=250"
    Then the response status should be "400"

  Scenario: Admin retrieves a paginated list of licenses with a page size that is too low
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 20 "licenses"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses?page[number]=1&page[size]=-250"
    Then the response status should be "400"

  Scenario: Admin retrieves a paginated list of licenses with an invalid page number (negative)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 20 "licenses"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses?page[number]=-1&page[size]=10"
    Then the response status should be "400"

  Scenario: Admin retrieves a paginated list of licenses with an invalid page number (type)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 20 "licenses"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses?page%5Bnumber%5D%3D=0"
    Then the response status should be "400"

  Scenario: Admin retrieves all licenses without a limit for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 20 "licenses"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses"
    Then the response status should be "200"
    And the JSON response should be an array with 10 "licenses"

  Scenario: Admin retrieves all licenses with a low limit for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 10 "licenses"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses?limit=5"
    Then the response status should be "200"
    And the JSON response should be an array with 5 "licenses"

  Scenario: Admin retrieves all licenses with a high limit for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 20 "licenses"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses?limit=20"
    Then the response status should be "200"
    And the JSON response should be an array with 20 "licenses"

  Scenario: Admin retrieves all licenses with a limit that is too high
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "licenses"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses?limit=900"
    Then the response status should be "400"

  Scenario: Admin retrieves all licenses with a limit that is too low
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "licenses"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses?limit=-900"
    Then the response status should be "400"

  Scenario: Admin retrieves all suspended licenses
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 10 "licenses"
    And the first "license" has the following attributes:
      """
      { "suspended": true }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses?suspended=true"
    Then the response status should be "200"
    And the JSON response should be an array with 1 "license"

  Scenario: Admin retrieves all non-suspended licenses
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 10 "licenses"
    And the first "license" has the following attributes:
      """
      { "suspended": true }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses?suspended=false"
    Then the response status should be "200"
    And the JSON response should be an array with 9 "licenses"

  Scenario: Admin retrieves all expired licenses
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 10 "licenses"
    And the first "license" has the following attributes:
      """
      { "expiry": "$time.1.hour.ago" }
      """
    And the second "license" has the following attributes:
      """
      { "expiry": null }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses?expired=true"
    Then the response status should be "200"
    And the JSON response should be an array with 1 "license"

  Scenario: Admin retrieves all non-expired licenses
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 10 "licenses"
    And the first "license" has the following attributes:
      """
      { "expiry": "$time.1.hour.ago" }
      """
    And the second "license" has the following attributes:
      """
      { "expiry": null }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses?expired=false"
    Then the response status should be "200"
    And the JSON response should be an array with 9 "licenses"

  Scenario: Admin retrieves all unassigned licenses
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 3 "licenses"
    And the first "license" has the following attributes:
      """
      { "userId": "$users[0]" }
      """
    And the second "license" has the following attributes:
      """
      { "userId": null }
      """
    And the third "license" has the following attributes:
      """
      { "userId": "$users[0]" }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses?unassigned=true"
    Then the response status should be "200"
    And the JSON response should be an array with 1 "license"

  Scenario: Admin retrieves all expiring licenses
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 6 "licenses"
    And the first "license" has the following attributes:
      """
      { "expiry": "$time.1.hour.ago" }
      """
    And the second "license" has the following attributes:
      """
      { "expiry": "$time.4.days.from_now" }
      """
    And the third "license" has the following attributes:
      """
      { "expiry": "$time.1.hour.from_now" }
      """
    And the fourth "license" has the following attributes:
      """
      { "expiry": "$time.1.day.from_now" }
      """
    And the fifth "license" has the following attributes:
      """
      { "expiry": "$time.10.minutes.from_now" }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses?expiring=1"
    Then the response status should be "200"
    And the JSON response should be an array with 3 "licenses"

  Scenario: Admin retrieves all non-expiring licenses
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 8 "licenses"
    And the first "license" has the following attributes:
      """
      { "expiry": "$time.1.hour.ago" }
      """
    And the second "license" has the following attributes:
      """
      { "expiry": null }
      """
    And the third "license" has the following attributes:
      """
      { "expiry": "$time.4.days.from_now" }
      """
    And the fourth "license" has the following attributes:
      """
      { "expiry": "$time.1.day.from_now" }
      """
    And the fifth "license" has the following attributes:
      """
      { "expiry": "$time.10.minutes.from_now" }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses?expiring=0"
    Then the response status should be "200"
    And the JSON response should be an array with 6 "licenses"

  Scenario: Admin retrieves all unassigned licenses
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 3 "licenses"
    And the first "license" has the following attributes:
      """
      { "userId": "$users[0]" }
      """
    And the second "license" has the following attributes:
      """
      { "userId": null }
      """
    And the third "license" has the following attributes:
      """
      { "userId": "$users[0]" }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses?unassigned=false"
    Then the response status should be "200"
    And the JSON response should be an array with 2 "licenses"

  Scenario: Admin retrieves 1 license filtered by metadata ID
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 3 "licenses"
    And the first "license" has the following attributes:
      """
      { "metadata": { "id": "e029e80d-7649-4770-8744-74bd794ddc08" } }
      """
    And the second "license" has the following attributes:
      """
      { "metadata": { "id": "6f79fb2e-f072-44f6-b014-7e304bcf5fcd" } }
      """
    And the third "license" has the following attributes:
      """
      { "metadata": { "id": "9cd5a11f-01be-4dc3-a8d4-c44ff2068a04" } }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses?metadata[id]=e029e80d-7649-4770-8744-74bd794ddc08"
    Then the response status should be "200"
    And the JSON response should be an array with 1 "license"

  Scenario: Admin retrieves 1 license filtered by metadata ID and user email
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 3 "licenses"
    And the first "license" has the following attributes:
      """
      { "metadata": { "id": "9cd5a11f-7649-4770-8744-74bd794ddc08", "user": "foo-1@example.com" } }
      """
    And the second "license" has the following attributes:
      """
      { "metadata": { "id": "9cd5a11f-7649-4770-8744-74bd794ddc08", "user": "foo-2@example.com" } }
      """
    And the third "license" has the following attributes:
      """
      { "metadata": { "id": "9cd5a11f-7649-4770-8744-74bd794ddc08", "user": "foo-3@example.com" } }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses?metadata[id]=9cd5a11f-7649-4770-8744-74bd794ddc08&metadata[user]=foo-1@example.com"
    Then the response status should be "200"
    And the JSON response should be an array with 1 "license"

  Scenario: Admin retrieves 3 licenses filtered by metadata ID (prefix)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 6 "licenses"
    And the first "license" has the following attributes:
      """
      { "metadata": { "id": "9cd5a11f-7649-4770-8744-74bd794ddc08", "user": "foo-1@example.com" } }
      """
    And the second "license" has the following attributes:
      """
      { "metadata": { "id": "9cd5a11f-f072-44f6-b014-7e304bcf5fcd", "user": "foo-2@example.com" } }
      """
    And the third "license" has the following attributes:
      """
      { "metadata": { "id": "9cd5a11f-01be-4dc3-a8d4-c44ff2068a04", "user": "foo-3@example.com" } }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses?metadata[id]=9cd5a11f"
    Then the response status should be "200"
    And the JSON response should be an array with 0 "licenses"

  Scenario: Admin retrieves 3 licenses filtered by metadata ID (full)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 6 "licenses"
    And the first "license" has the following attributes:
      """
      { "metadata": { "id": "9cd5a11f-7649-4770-8744-74bd794ddc08", "user": "foo-1@example.com" } }
      """
    And the second "license" has the following attributes:
      """
      { "metadata": { "id": "9cd5a11f-7649-4770-8744-74bd794ddc08", "user": "foo-2@example.com" } }
      """
    And the third "license" has the following attributes:
      """
      { "metadata": { "id": "9cd5a11f-7649-4770-8744-74bd794ddc08", "user": "foo-3@example.com" } }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses?metadata[id]=9cd5a11f-7649-4770-8744-74bd794ddc08"
    Then the response status should be "200"
    And the JSON response should be an array with 3 "licenses"

  Scenario: Admin retrieves licenses filtered by a boolean metadata value
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 3 "licenses"
    And the first "license" has the following attributes:
      """
      { "metadata": { "deleted": false } }
      """
    And the second "license" has the following attributes:
      """
      { "metadata": { "deleted": false } }
      """
    And the third "license" has the following attributes:
      """
      { "metadata": { "deleted": true } }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses?metadata[deleted]=false"
    Then the response status should be "200"
    And the JSON response should be an array with 2 "licenses"

  Scenario: Admin retrieves licenses filtered by an integer metadata value
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 3 "licenses"
    And the first "license" has the following attributes:
      """
      { "metadata": { "tos": 1 } }
      """
    And the second "license" has the following attributes:
      """
      { "metadata": { "tos": 0 } }
      """
    And the third "license" has the following attributes:
      """
      { "metadata": { "tos": 0 } }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses?metadata[tos]=1"
    Then the response status should be "200"
    And the JSON response should be an array with 1 "license"

  Scenario: Admin retrieves licenses filtered by an float metadata value
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 3 "licenses"
    And the first "license" has the following attributes:
      """
      { "metadata": { "score": 1.0 } }
      """
    And the second "license" has the following attributes:
      """
      { "metadata": { "score": 0.4 } }
      """
    And the third "license" has the following attributes:
      """
      { "metadata": { "score": 0.9 } }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses?metadata[score]=0.9"
    Then the response status should be "200"
    And the JSON response should be an array with 1 "license"

  Scenario: Admin retrieves licenses filtered by a null metadata value
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 3 "licenses"
    And the first "license" has the following attributes:
      """
      { "metadata": { "deleted_at": null } }
      """
    And the second "license" has the following attributes:
      """
      { "metadata": { "deleted_at": null } }
      """
    And the third "license" has the following attributes:
      """
      { "metadata": { "deleted_at": "1624214637" } }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses?metadata[deletedAt]=null"
    Then the response status should be "200"
    And the JSON response should be an array with 2 "licenses"

  Scenario: Admin retrieves licenses filtered by a numeric string metadata value
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 3 "licenses"
    And the first "license" has the following attributes:
      """
      { "metadata": { "internalId": "1624214637", "tenantId": 1 } }
      """
    And the second "license" has the following attributes:
      """
      { "metadata": { "internalId": "1624214637", "tenantId": 2 } }
      """
    And the third "license" has the following attributes:
      """
      { "metadata": { "internalId": "1624214637", "tenantId": 3 } }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses?metadata[internalId]=1624214637&metadata[tenantId]=2"
    Then the response status should be "200"
    And the JSON response should be an array with 1 "license"

  Scenario: Admin retrieves licenses filtered by an object metadata value (integers)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 3 "licenses"
    And the first "license" has the following attributes:
      """
      { "metadata": { "hardware": { "cpu": "ryzen-3700x", "cores": 16 } } }
      """
    And the second "license" has the following attributes:
      """
      { "metadata": { "hardware": { "cpu": "intel-i9", "cores": 16 } } }
      """
    And the third "license" has the following attributes:
      """
      { "metadata": { "hardware": { "cpu": "ryzen-threadripper", "cores": 64 } } }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses?metadata[hardware][cores]=64"
    Then the response status should be "200"
    And the JSON response should be an array with 0 "licenses"

  Scenario: Admin retrieves licenses filtered by an object metadata value (strings)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 3 "licenses"
    And the first "license" has the following attributes:
      """
      { "metadata": { "hardware": { "cpu": "ryzen-3700x", "cores": 16 } } }
      """
    And the second "license" has the following attributes:
      """
      { "metadata": { "hardware": { "cpu": "intel-i9", "cores": 16 } } }
      """
    And the third "license" has the following attributes:
      """
      { "metadata": { "hardware": { "cpu": "ryzen-threadripper", "cores": 64 } } }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses?metadata[hardware][cpu]=ryzen-threadripper"
    Then the response status should be "200"
    And the JSON response should be an array with 1 "license"

  Scenario: Admin retrieves licenses filtered by an array metadata value (integers)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 3 "licenses"
    And the first "license" has the following attributes:
      """
      { "metadata": { "ids": [1, 2, 3] } }
      """
    And the second "license" has the following attributes:
      """
      { "metadata": { "ids": [4, 5, 6] } }
      """
    And the third "license" has the following attributes:
      """
      { "metadata": { "ids": [2] } }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses?metadata[ids][]=2"
    Then the response status should be "200"
    And the JSON response should be an array with 0 "licenses"

  Scenario: Admin retrieves licenses filtered by an array metadata value (strings)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 3 "licenses"
    And the first "license" has the following attributes:
      """
      { "metadata": { "ids": ["1", "2", "3"] } }
      """
    And the second "license" has the following attributes:
      """
      { "metadata": { "ids": ["4", "5", "6"] } }
      """
    And the third "license" has the following attributes:
      """
      { "metadata": { "ids": ["2"] } }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses?metadata[ids][]=2"
    Then the response status should be "200"
    And the JSON response should be an array with 2 "licenses"

  Scenario: Admin retrieves licenses filtered by user ID
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 3 "users"
    And the current account has 6 "licenses"
    And the first "license" has the following attributes:
      """
      { "userId": "$users[1]" }
      """
    And the second "license" has the following attributes:
      """
      { "userId": "$users[1]" }
      """
    And the third "license" has the following attributes:
      """
      { "userId": "$users[2]" }
      """
    And the fourth "license" has the following attributes:
      """
      { "userId": "$users[3]" }
      """
    And the fifth "license" has the following attributes:
      """
      { "userId": "$users[1]" }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses?user=$users[1]"
    Then the response status should be "200"
    And the JSON response should be an array with 3 "licenses"

  Scenario: Admin retrieves licenses filtered by user email
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "users"
    And the second "user" has the following attributes:
      """
      { "email": "zeke@keygen.example" }
      """
    And the third "user" has the following attributes:
      """
      { "email": "luca@keygen.example" }
      """
    And the current account has 6 "licenses"
    And the first "license" has the following attributes:
      """
      { "userId": "$users[1]" }
      """
    And the second "license" has the following attributes:
      """
      { "userId": "$users[1]" }
      """
    And the third "license" has the following attributes:
      """
      { "userId": "$users[2]" }
      """
    And the fourth "license" has the following attributes:
      """
      { "userId": null }
      """
    And the fifth "license" has the following attributes:
      """
      { "userId": "$users[1]" }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses?user=luca@keygen.example"
    Then the response status should be "200"
    And the JSON response should be an array with 1 "license"

  Scenario: Admin retrieves licenses filtered by policy ID
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 3 "policies"
    And the current account has 6 "licenses"
    And the first "license" has the following attributes:
      """
      { "policyId": "$policies[0]" }
      """
    And the second "license" has the following attributes:
      """
      { "policyId": "$policies[1]" }
      """
    And the third "license" has the following attributes:
      """
      { "policyId": "$policies[2]" }
      """
    And the fourth "license" has the following attributes:
      """
      { "policyId": "$policies[1]" }
      """
    And the fifth "license" has the following attributes:
      """
      { "policyId": "$policies[1]" }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses?policy=$policies[1]"
    Then the response status should be "200"
    And the JSON response should be an array with 3 "licenses"

  Scenario: Admin retrieves licenses filtered by product ID
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "products"
    And the current account has 2 "policies"
    And the first "policies" has the following attributes:
      """
      { "productId": "$products[0]" }
      """
    And the second "policies" has the following attributes:
      """
      { "productId": "$products[1]" }
      """
    And the current account has 6 "licenses"
    And the first "license" has the following attributes:
      """
      { "policyId": "$policies[0]" }
      """
    And the second "license" has the following attributes:
      """
      { "policyId": "$policies[1]" }
      """
    And the third "license" has the following attributes:
      """
      { "policyId": "$policies[1]" }
      """
    And the fourth "license" has the following attributes:
      """
      { "policyId": "$policies[1]" }
      """
    And the fifth "license" has the following attributes:
      """
      { "policyId": "$policies[1]" }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses?product=$products[1]"
    Then the response status should be "200"
    And the JSON response should be an array with 4 "licenses"

  Scenario: Admin retrieves licenses filtered by status (active)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 5 "licenses"
    # New, active
    And the first "license" has the following attributes:
      """
      {
        "createdAt": "$time.1.minute.ago",
        "lastValidatedAt": null,
        "expiry": "$time.1.month.from_now",
        "suspended": false
      }
      """
    # Inactive, expiring
    And the second "license" has the following attributes:
      """
      {
        "createdAt": "$time.91.days.ago",
        "lastValidatedAt": null,
        "expiry": "$time.1.day.from_now",
        "suspended": false
      }
      """
    # Old, active, expiring
    And the third "license" has the following attributes:
      """
      {
        "createdAt": "$time.91.days.ago",
        "lastValidatedAt": "$time.1.day.ago",
        "expiry": "$time.2.days.ago",
        "suspended": false
      }
      """
    # Old, active, suspended
    And the fourth "license" has the following attributes:
      """
      {
        "createdAt": "$time.4.days.ago",
        "lastValidatedAt": "$time.1.day.ago",
        "expiry": "$time.1.year.from_now",
        "suspended": true
      }
      """
    # Old, inactive
    And the fifth "license" has the following attributes:
      """
      {
        "createdAt": "$time.2.years.ago",
        "lastValidatedAt": "$time.1.year.ago",
        "expiry": null,
        "suspended": false
      }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses?status=ACTIVE"
    Then the response status should be "200"
    And the JSON response should be an array with 3 "licenses"

  Scenario: Admin retrieves licenses filtered by status (active, lowercase)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 5 "licenses"
    And the first "license" has the following attributes:
      """
      {
        "createdAt": "$time.1.minute.ago",
        "lastValidatedAt": null,
        "expiry": "$time.1.month.from_now",
        "suspended": false
      }
      """
    And the second "license" has the following attributes:
      """
      {
        "createdAt": "$time.91.days.ago",
        "lastValidatedAt": null,
        "expiry": "$time.1.day.from_now",
        "suspended": false
      }
      """
    And the third "license" has the following attributes:
      """
      {
        "createdAt": "$time.91.days.ago",
        "lastValidatedAt": "$time.1.day.ago",
        "expiry": "$time.2.days.ago",
        "suspended": false
      }
      """
    And the fourth "license" has the following attributes:
      """
      {
        "createdAt": "$time.4.days.ago",
        "lastValidatedAt": "$time.1.day.ago",
        "expiry": "$time.1.year.from_now",
        "suspended": true
      }
      """
    And the fifth "license" has the following attributes:
      """
      {
        "createdAt": "$time.2.years.ago",
        "lastValidatedAt": "$time.1.year.ago",
        "expiry": null,
        "suspended": false
      }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses?status=active"
    Then the response status should be "200"
    And the JSON response should be an array with 3 "licenses"

  Scenario: Admin retrieves licenses filtered by status (inactive)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 5 "licenses"
    And the first "license" has the following attributes:
      """
      {
        "createdAt": "$time.1.minute.ago",
        "lastValidatedAt": null,
        "expiry": "$time.1.month.from_now",
        "suspended": false
      }
      """
    And the second "license" has the following attributes:
      """
      {
        "createdAt": "$time.91.days.ago",
        "lastValidatedAt": null,
        "expiry": "$time.1.day.from_now",
        "suspended": false
      }
      """
    And the third "license" has the following attributes:
      """
      {
        "createdAt": "$time.91.days.ago",
        "lastValidatedAt": "$time.1.day.ago",
        "expiry": "$time.2.days.ago",
        "suspended": false
      }
      """
    And the fourth "license" has the following attributes:
      """
      {
        "createdAt": "$time.4.days.ago",
        "lastValidatedAt": "$time.1.day.ago",
        "expiry": "$time.1.year.from_now",
        "suspended": true
      }
      """
    And the fifth "license" has the following attributes:
      """
      {
        "createdAt": "$time.2.years.ago",
        "lastValidatedAt": "$time.1.year.ago",
        "expiry": null,
        "suspended": false
      }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses?status=INACTIVE"
    Then the response status should be "200"
    And the JSON response should be an array with 2 "licenses"

  Scenario: Admin retrieves licenses filtered by status (expiring)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 5 "licenses"
    And the first "license" has the following attributes:
      """
      {
        "createdAt": "$time.1.minute.ago",
        "lastValidatedAt": null,
        "expiry": "$time.1.month.from_now",
        "suspended": false
      }
      """
    And the second "license" has the following attributes:
      """
      {
        "createdAt": "$time.91.days.ago",
        "lastValidatedAt": null,
        "expiry": "$time.1.day.from_now",
        "suspended": false
      }
      """
    And the third "license" has the following attributes:
      """
      {
        "createdAt": "$time.91.days.ago",
        "lastValidatedAt": "$time.1.day.ago",
        "expiry": "$time.2.days.ago",
        "suspended": false
      }
      """
    And the fourth "license" has the following attributes:
      """
      {
        "createdAt": "$time.4.days.ago",
        "lastValidatedAt": "$time.1.day.ago",
        "expiry": "$time.1.year.from_now",
        "suspended": true
      }
      """
    And the fifth "license" has the following attributes:
      """
      {
        "createdAt": "$time.2.years.ago",
        "lastValidatedAt": "$time.1.year.ago",
        "expiry": null,
        "suspended": false
      }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses?status=EXPIRING"
    Then the response status should be "200"
    And the JSON response should be an array with 1 "license"

  Scenario: Admin retrieves licenses filtered by status (expired)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 5 "licenses"
    And the first "license" has the following attributes:
      """
      {
        "createdAt": "$time.1.minute.ago",
        "lastValidatedAt": null,
        "expiry": "$time.1.month.from_now",
        "suspended": false
      }
      """
    And the second "license" has the following attributes:
      """
      {
        "createdAt": "$time.91.days.ago",
        "lastValidatedAt": null,
        "expiry": "$time.1.day.from_now",
        "suspended": false
      }
      """
    And the third "license" has the following attributes:
      """
      {
        "createdAt": "$time.91.days.ago",
        "lastValidatedAt": "$time.1.day.ago",
        "expiry": "$time.2.days.ago",
        "suspended": false
      }
      """
    And the fourth "license" has the following attributes:
      """
      {
        "createdAt": "$time.4.days.ago",
        "lastValidatedAt": "$time.1.day.ago",
        "expiry": "$time.1.year.from_now",
        "suspended": true
      }
      """
    And the fifth "license" has the following attributes:
      """
      {
        "createdAt": "$time.2.years.ago",
        "lastValidatedAt": "$time.1.year.ago",
        "expiry": null,
        "suspended": false
      }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses?status=EXPIRED"
    Then the response status should be "200"
    And the JSON response should be an array with 1 "license"

  Scenario: Admin retrieves licenses filtered by status (suspended)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 5 "licenses"
    And the first "license" has the following attributes:
      """
      {
        "createdAt": "$time.1.minute.ago",
        "lastValidatedAt": null,
        "expiry": "$time.1.month.from_now",
        "suspended": false
      }
      """
    And the second "license" has the following attributes:
      """
      {
        "createdAt": "$time.91.days.ago",
        "lastValidatedAt": null,
        "expiry": "$time.1.day.from_now",
        "suspended": false
      }
      """
    And the third "license" has the following attributes:
      """
      {
        "createdAt": "$time.91.days.ago",
        "lastValidatedAt": "$time.1.day.ago",
        "expiry": "$time.2.days.ago",
        "suspended": false
      }
      """
    And the fourth "license" has the following attributes:
      """
      {
        "createdAt": "$time.4.days.ago",
        "lastValidatedAt": "$time.1.day.ago",
        "expiry": "$time.1.year.from_now",
        "suspended": true
      }
      """
    And the fifth "license" has the following attributes:
      """
      {
        "createdAt": "$time.2.years.ago",
        "lastValidatedAt": "$time.1.year.ago",
        "expiry": null,
        "suspended": false
      }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses?status=SUSPENDED"
    Then the response status should be "200"
    And the JSON response should be an array with 1 "license"

  Scenario: Admin retrieves licenses filtered by status (banned)
    Given the current account is "test1"
    And the current account has 3 "users"
    And the last "user" has the following attributes:
      """
      { "bannedAt": "$time.now" }
      """
    And the current account has 3 "licenses"
    And the first "license" has the following attributes:
      """
      { "userId": "$users[1]" }
      """
    And the second "license" has the following attributes:
      """
      { "userId": "$users[2]" }
      """
    And the third "license" has the following attributes:
      """
      { "userId": "$users[3]" }
      """
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses?status=BANNED"
    Then the response status should be "200"
    And the JSON response should be an array with 1 "license"

  Scenario: Admin retrieves licenses filtered by status (invalid)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 5 "licenses"
    And the first "license" has the following attributes:
      """
      {
        "createdAt": "$time.1.minute.ago",
        "lastValidatedAt": null,
        "expiry": "$time.1.month.from_now",
        "suspended": false
      }
      """
    And the second "license" has the following attributes:
      """
      {
        "createdAt": "$time.91.days.ago",
        "lastValidatedAt": null,
        "expiry": "$time.1.day.from_now",
        "suspended": false
      }
      """
    And the third "license" has the following attributes:
      """
      {
        "createdAt": "$time.91.days.ago",
        "lastValidatedAt": "$time.1.day.ago",
        "expiry": "$time.2.days.ago",
        "suspended": false
      }
      """
    And the fourth "license" has the following attributes:
      """
      {
        "createdAt": "$time.4.days.ago",
        "lastValidatedAt": "$time.1.day.ago",
        "expiry": "$time.1.year.from_now",
        "suspended": true
      }
      """
    And the fifth "license" has the following attributes:
      """
      {
        "createdAt": "$time.2.years.ago",
        "lastValidatedAt": "$time.1.year.ago",
        "expiry": null,
        "suspended": false
      }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses?status=INVALID"
    Then the response status should be "200"
    And the JSON response should be an array with 0 "licenses"

  Scenario: Product retrieves all licenses for their product
    Given the current account is "test1"
    And the current account has 1 "product"
    And I am a product of account "test1"
    And I use an authentication token
    And the current account has 3 "licenses"
    And the current product has 1 "license"
    When I send a GET request to "/accounts/test1/licenses"
    Then the response status should be "200"
    And the JSON response should be an array with 1 "license"

  Scenario: Admin attempts to retrieve all licenses for another account
    Given I am an admin of account "test2"
    But the current account is "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses"
    Then the response status should be "401"
    And the JSON response should be an array of 1 error

  Scenario: User retrieves all licenses for their account
    Given the current account is "test1"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    And the current account has 3 "licenses"
    And the current user has 1 "license"
    When I send a GET request to "/accounts/test1/licenses"
    Then the response status should be "200"
    And the JSON response should be an array with 1 "license"

  Scenario: User retrieves all licenses for their group
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
    And the current account has 7 "licenses"
    And the first "license" has the following attributes:
      """
      { "groupId": "$groups[0]" }
      """
    And the second "license" has the following attributes:
      """
      { "groupId": "$groups[0]" }
      """
    And the third "license" has the following attributes:
      """
      { "groupId": "$groups[0]" }
      """
    And the fourth "license" has the following attributes:
      """
      { "groupId": "$groups[1]" }
      """
    And the fifth "license" has the following attributes:
      """
      { "userId": "$users[1]" }
      """
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses"
    Then the response status should be "200"
    And the JSON response should be an array with 4 "licenses"

  Scenario: User retrieves all licenses for their account filtered by metadata ID
    Given the current account is "test1"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    And the current account has 3 "licenses"
    And the first "license" has the following attributes:
      """
      { "metadata": { "id": "9cd5a11f-7649-4770-8744-74bd794ddc08", "user": "foo-1@example.com" } }
      """
    And the second "license" has the following attributes:
      """
      { "metadata": { "id": "9cd5a11f-7649-4770-8744-74bd794ddc08", "user": "foo-2@example.com" } }
      """
    And the third "license" has the following attributes:
      """
      { "metadata": { "id": "9cd5a11f-7649-4770-8744-74bd794ddc08", "user": "foo-3@example.com" } }
      """
    And the current user has 1 "license"
    When I send a GET request to "/accounts/test1/licenses?metadata[id]=9cd5a11f-7649-4770-8744-74bd794ddc08"
    Then the response status should be "200"
    And the JSON response should be an array with 1 "license"
