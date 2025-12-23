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
    And the response body should be an array with 3 "licenses"

  Scenario: Developer retrieves all licenses for their account
    Given the current account is "test1"
    And the current account has 1 "developer"
    And I am a developer of account "test1"
    And the current account has 2 "licenses"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses"
    Then the response status should be "200"
    And the response body should be an array with 2 "licenses"

  Scenario: Sales retrieves all licenses for their account
    Given the current account is "test1"
    And the current account has 1 "sales-agent"
    And I am a sales agent of account "test1"
    And the current account has 2 "licenses"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses"
    Then the response status should be "200"
    And the response body should be an array with 2 "licenses"

  Scenario: Support retrieves all licenses for their account
    Given the current account is "test1"
    And the current account has 1 "support-agent"
    And I am a support agent of account "test1"
    And the current account has 2 "licenses"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses"
    Then the response status should be "200"
    And the response body should be an array with 2 "licenses"

  Scenario: Read-only retrieves all licenses for their account
    Given the current account is "test1"
    And the current account has 1 "read-only"
    And I am a read only of account "test1"
    And the current account has 2 "licenses"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses"
    Then the response status should be "200"
    And the response body should be an array with 2 "licenses"

  Scenario: Admin retrieves a paginated list of licenses
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 20 "licenses"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses?page[number]=4&page[size]=5"
    Then the response status should be "200"
    And the response body should be an array with 5 "licenses"
    And the response body should contain the following links:
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
    And the response body should be an array with 10 "licenses"

  Scenario: Admin retrieves all licenses with a low limit for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 10 "licenses"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses?limit=5"
    Then the response status should be "200"
    And the response body should be an array with 5 "licenses"

  Scenario: Admin retrieves all licenses with a high limit for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 20 "licenses"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses?limit=20"
    Then the response status should be "200"
    And the response body should be an array with 20 "licenses"

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
    And the response body should be an array with 1 "license"

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
    And the response body should be an array with 9 "licenses"

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
    And the response body should be an array with 1 "license"

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
    And the response body should be an array with 9 "licenses"

  Scenario: Admin retrieves all unassigned licenses
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "users"
    And the current account has 7 "licenses"
    And the first "license" has the following attributes:
      """
      { "userId": "$users[1]" }
      """
    And the second "license" has the following attributes:
      """
      { "userId": null }
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
      { "userId": null }
      """
    And the current account has 1 "license-user" for the first "license" and the third "user"
    And the current account has 1 "license-user" for the fourth "license" and the second "user"
    And the current account has 1 "license-user" for the fifth "license" and the second "user"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses?unassigned=true"
    Then the response status should be "200"
    And the response body should be an array with 3 "licenses"
    And the first "license" should have the following relationships:
      """
      {
        "owner": {
          "links": { "related": "/v1/accounts/$account/licenses/$licenses[6]/owner" },
          "data": null
        }
      }
      """
    And the second "license" should have the following relationships:
      """
      {
        "owner": {
          "links": { "related": "/v1/accounts/$account/licenses/$licenses[5]/owner" },
          "data": null
        }
      }
      """
    And the third "license" should have the following relationships:
      """
      {
        "owner": {
          "links": { "related": "/v1/accounts/$account/licenses/$licenses[1]/owner" },
          "data": null
        }
      }
      """

  Scenario: Admin retrieves all unassigned licenses (v1.5)
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
    And I use API version "1.5"
    When I send a GET request to "/accounts/test1/licenses?unassigned=true"
    Then the response status should be "200"
    And the response body should be an array with 1 "license"
    And the first "license" should have the following relationships:
      """
      {
        "user": {
          "links": { "related": "/v1/accounts/$account/licenses/$licenses[1]/user" },
          "data": null
        }
      }
      """

  Scenario: Admin retrieves all assigned licenses
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "users"
    And the current account has 7 "licenses"
    And the first "license" has the following attributes:
      """
      { "userId": "$users[1]" }
      """
    And the second "license" has the following attributes:
      """
      { "userId": null }
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
      { "userId": null }
      """
    And the current account has 1 "license-user" for the first "license" and the third "user"
    And the current account has 1 "license-user" for the fourth "license" and the second "user"
    And the current account has 1 "license-user" for the fifth "license" and the second "user"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses?assigned=true"
    Then the response status should be "200"
    And the response body should be an array with 4 "licenses"
    And the first "license" should have the following relationships:
      """
      {
        "owner": {
          "links": { "related": "/v1/accounts/$account/licenses/$licenses[4]/owner" },
          "data": null
        }
      }
      """
    And the second "license" should have the following relationships:
      """
      {
        "owner": {
          "links": { "related": "/v1/accounts/$account/licenses/$licenses[3]/owner" },
          "data": null
        }
      }
      """
    And the third "license" should have the following relationships:
      """
      {
        "owner": {
          "links": { "related": "/v1/accounts/$account/licenses/$licenses[2]/owner" },
          "data": { "type": "users", "id": "$users[2]" }
        }
      }
      """
    And the fourth "license" should have the following relationships:
      """
      {
        "owner": {
          "links": { "related": "/v1/accounts/$account/licenses/$licenses[0]/owner" },
          "data": { "type": "users", "id": "$users[1]" }
        }
      }
      """

  Scenario: Admin retrieves all assigned licenses (v1.5)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "users"
    And the current account has 3 "licenses"
    And the first "license" has the following attributes:
      """
      { "userId": "$users[1]" }
      """
    And the second "license" has the following attributes:
      """
      { "userId": null }
      """
    And the third "license" has the following attributes:
      """
      { "userId": "$users[2]" }
      """
    And I use an authentication token
    And I use API version "1.5"
    When I send a GET request to "/accounts/test1/licenses?unassigned=false"
    Then the response status should be "200"
    And the response body should be an array with 2 "licenses"
    And the first "license" should have the following relationships:
      """
      {
        "user": {
          "links": { "related": "/v1/accounts/$account/licenses/$licenses[2]/user" },
          "data": { "type": "users", "id": "$users[2]" }
        }
      }
      """
    And the second "license" should have the following relationships:
      """
      {
        "user": {
          "links": { "related": "/v1/accounts/$account/licenses/$licenses[0]/user" },
          "data": { "type": "users", "id": "$users[1]" }
        }
      }
      """

  Scenario: Admin retrieves all activated licenses
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 3 "licenses"
    And the current account has 2 "machines" for the first "license"
    And the current account has 1 "machine" for the second "license"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses?activated=true"
    Then the response status should be "200"
    And the response body should be an array with 2 "licenses"

  Scenario: Admin retrieves all unactivated licenses
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 3 "licenses"
    And the current account has 2 "machines" for the first "license"
    And the current account has 1 "machine" for the second "license"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses?activated=false"
    Then the response status should be "200"
    And the response body should be an array with 1 "license"

  Scenario: Admin retrieves all licenses with 2 activations
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 10 "licenses"
    And the current account has 2 "machines" for the first "license"
    And the current account has 2 "machines" for the second "license"
    And the current account has 3 "machines" for the third "license"
    And the current account has 1 "machine" for the fourth "license"
    And the current account has 1 "machine" for the fifth "license"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses?activations[eq]=2"
    Then the response status should be "200"
    And the response body should be an array with 2 "licenses"

  Scenario: Admin retrieves all licenses with more than 2 activations
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 10 "licenses"
    And the current account has 2 "machines" for the first "license"
    And the current account has 2 "machines" for the second "license"
    And the current account has 3 "machines" for the third "license"
    And the current account has 1 "machine" for the fourth "license"
    And the current account has 1 "machine" for the fifth "license"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses?activations[gt]=2"
    Then the response status should be "200"
    And the response body should be an array with 1 "license"

  Scenario: Admin retrieves all licenses with at least 2 activations
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 10 "licenses"
    And the current account has 2 "machines" for the first "license"
    And the current account has 2 "machines" for the second "license"
    And the current account has 3 "machines" for the third "license"
    And the current account has 1 "machine" for the fourth "license"
    And the current account has 1 "machine" for the fifth "license"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses?activations[gte]=2"
    Then the response status should be "200"
    And the response body should be an array with 3 "licenses"

  Scenario: Admin retrieves all licenses with less than 2 activations
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 10 "licenses"
    And the current account has 2 "machines" for the first "license"
    And the current account has 2 "machines" for the second "license"
    And the current account has 3 "machines" for the third "license"
    And the current account has 1 "machine" for the fourth "license"
    And the current account has 1 "machine" for the fifth "license"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses?activations[lt]=2"
    Then the response status should be "200"
    And the response body should be an array with 7 "licenses"

  Scenario: Admin retrieves all licenses with at most 2 activations
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 10 "licenses"
    And the current account has 2 "machines" for the first "license"
    And the current account has 2 "machines" for the second "license"
    And the current account has 3 "machines" for the third "license"
    And the current account has 1 "machine" for the fourth "license"
    And the current account has 1 "machine" for the fifth "license"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses?activations[lte]=2"
    Then the response status should be "200"
    And the response body should be an array with 9 "licenses"

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
    And the response body should be an array with 3 "licenses"

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
    And the response body should be an array with 6 "licenses"

  Scenario: Admin retrieves all licenses expiring within the next 30 days (seconds)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 5 "licenses"
    And the first "license" has the following attributes:
      """
      { "expiry": "2022-06-10T12:00:00.000Z" }
      """
    And the second "license" has the following attributes:
      """
      { "expiry": null }
      """
    And the third "license" has the following attributes:
      """
      { "expiry": "2022-08-10T12:00:00.000Z" }
      """
    And the fourth "license" has the following attributes:
      """
      { "expiry": "2022-07-10T13:00:00.000Z" }
      """
    And the fifth "license" has the following attributes:
      """
      { "expiry": "2022-07-01T12:00:00.000Z" }
      """
    And time is frozen at "2022-06-10T13:00:00.000Z"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses?expires[within]=2629746"
    Then the response status should be "200"
    And the response body should be an array with 2 "licenses"
    And time is unfrozen

  Scenario: Admin retrieves all licenses expiring within the next 2 weeks (simple ISO)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 5 "licenses"
    And the first "license" has the following attributes:
      """
      { "expiry": "2022-06-10T10:00:00.000Z" }
      """
    And the second "license" has the following attributes:
      """
      { "expiry": null }
      """
    And the third "license" has the following attributes:
      """
      { "expiry": "2022-07-10T13:00:00.000Z" }
      """
    And the fourth "license" has the following attributes:
      """
      { "expiry": "2022-06-11T13:00:00.000Z" }
      """
    And the fifth "license" has the following attributes:
      """
      { "expiry": "2022-06-24T13:00:00.000Z" }
      """
    And time is frozen at "2022-06-10T13:00:00.000Z"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses?expires[within]=2w"
    Then the response status should be "200"
    And the response body should be an array with 2 "licenses"
    And time is unfrozen

  Scenario: Admin retrieves all licenses expiring within the next 13 days, 59 minutes and 59 seconds (complex ISO)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 5 "licenses"
    And the first "license" has the following attributes:
      """
      { "expiry": "2022-06-10T10:00:00.000Z" }
      """
    And the second "license" has the following attributes:
      """
      { "expiry": null }
      """
    And the third "license" has the following attributes:
      """
      { "expiry": "2022-07-10T13:00:00.000Z" }
      """
    And the fourth "license" has the following attributes:
      """
      { "expiry": "2022-06-11T13:00:00.000Z" }
      """
    And the fifth "license" has the following attributes:
      """
      { "expiry": "2022-06-24T13:00:00.000Z" }
      """
    And time is frozen at "2022-06-10T13:00:00.000Z"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses?expires[within]=P13DT59M59S"
    Then the response status should be "200"
    And the response body should be an array with 1 "license"
    And time is unfrozen

  Scenario: Admin retrieves all licenses expiring in the next 30 days (seconds)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 5 "licenses"
    And the first "license" has the following attributes:
      """
      { "expiry": "2022-06-10T12:00:00.000Z" }
      """
    And the second "license" has the following attributes:
      """
      { "expiry": null }
      """
    And the third "license" has the following attributes:
      """
      { "expiry": "2022-08-10T12:00:00.000Z" }
      """
    And the fourth "license" has the following attributes:
      """
      { "expiry": "2022-07-10T13:00:00.000Z" }
      """
    And the fifth "license" has the following attributes:
      """
      { "expiry": "2022-07-01T12:00:00.000Z" }
      """
    And time is frozen at "2022-06-10T13:00:00.000Z"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses?expires[in]=2629746"
    Then the response status should be "200"
    And the response body should be an array with 2 "licenses"
    And time is unfrozen

  Scenario: Admin retrieves all licenses expiring in the next 2 weeks (simple ISO)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 5 "licenses"
    And the first "license" has the following attributes:
      """
      { "expiry": "2022-06-10T10:00:00.000Z" }
      """
    And the second "license" has the following attributes:
      """
      { "expiry": null }
      """
    And the third "license" has the following attributes:
      """
      { "expiry": "2022-07-10T13:00:00.000Z" }
      """
    And the fourth "license" has the following attributes:
      """
      { "expiry": "2022-06-11T13:00:00.000Z" }
      """
    And the fifth "license" has the following attributes:
      """
      { "expiry": "2022-06-24T13:00:00.000Z" }
      """
    And time is frozen at "2022-06-10T13:00:00.000Z"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses?expires[in]=2w"
    Then the response status should be "200"
    And the response body should be an array with 2 "licenses"
    And time is unfrozen

  Scenario: Admin retrieves all licenses expiring in the next 13 days, 59 minutes and 59 seconds (complex ISO)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 5 "licenses"
    And the first "license" has the following attributes:
      """
      { "expiry": "2022-06-10T10:00:00.000Z" }
      """
    And the second "license" has the following attributes:
      """
      { "expiry": null }
      """
    And the third "license" has the following attributes:
      """
      { "expiry": "2022-07-10T13:00:00.000Z" }
      """
    And the fourth "license" has the following attributes:
      """
      { "expiry": "2022-06-11T13:00:00.000Z" }
      """
    And the fifth "license" has the following attributes:
      """
      { "expiry": "2022-06-24T13:00:00.000Z" }
      """
    And time is frozen at "2022-06-10T13:00:00.000Z"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses?expires[in]=P13DT59M59S"
    Then the response status should be "200"
    And the response body should be an array with 1 "license"
    And time is unfrozen

  Scenario: Admin retrieves all licenses expiring within some invalid duration
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 5 "licenses"
    And the first "license" has the following attributes:
      """
      { "expiry": "2022-06-10T10:00:00.000Z" }
      """
    And the second "license" has the following attributes:
      """
      { "expiry": null }
      """
    And the third "license" has the following attributes:
      """
      { "expiry": "2022-07-10T13:00:00.000Z" }
      """
    And the fourth "license" has the following attributes:
      """
      { "expiry": "2022-06-11T13:00:00.000Z" }
      """
    And the fifth "license" has the following attributes:
      """
      { "expiry": "2022-06-23T13:00:00.000Z" }
      """
    And time is frozen at "2022-06-10T13:00:00.000Z"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses?expires[within]=invalid"
    Then the response status should be "200"
    And the response body should be an array with 0 "licenses"
    And time is unfrozen

  Scenario: Admin retrieves all licenses expiring before a specific date (ISO)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 5 "licenses"
    And the first "license" has the following attributes:
      """
      { "expiry": "2022-06-10T10:00:00.000Z" }
      """
    And the second "license" has the following attributes:
      """
      { "expiry": null }
      """
    And the third "license" has the following attributes:
      """
      { "expiry": "2022-06-12T00:00:01.000Z" }
      """
    And the fourth "license" has the following attributes:
      """
      { "expiry": "2022-06-11T13:00:00.000Z" }
      """
    And the fifth "license" has the following attributes:
      """
      { "expiry": "2022-06-12T00:00:00.000Z" }
      """
    And time is frozen at "2022-06-10T13:00:00.000Z"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses?expires[before]=2022-06-12T00:00:00.000Z"
    Then the response status should be "200"
    And the response body should be an array with 2 "licenses"
    And time is unfrozen

  Scenario: Admin retrieves all licenses expiring before a specific date (unix)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 5 "licenses"
    And the first "license" has the following attributes:
      """
      { "expiry": "2022-06-10T10:00:00.000Z" }
      """
    And the second "license" has the following attributes:
      """
      { "expiry": null }
      """
    And the third "license" has the following attributes:
      """
      { "expiry": "2022-06-12T00:00:01.000Z" }
      """
    And the fourth "license" has the following attributes:
      """
      { "expiry": "2022-06-11T13:00:00.000Z" }
      """
    And the fifth "license" has the following attributes:
      """
      { "expiry": "2022-06-12T00:00:00.000Z" }
      """
    And time is frozen at "2022-06-10T13:00:00.000Z"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses?expires[before]=1654992000"
    Then the response status should be "200"
    And the response body should be an array with 2 "licenses"
    And time is unfrozen

  Scenario: Admin retrieves all licenses expiring before an invalid date
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 5 "licenses"
    And the first "license" has the following attributes:
      """
      { "expiry": "2022-06-10T10:00:00.000Z" }
      """
    And the second "license" has the following attributes:
      """
      { "expiry": null }
      """
    And the third "license" has the following attributes:
      """
      { "expiry": "2022-06-12T00:00:01.000Z" }
      """
    And the fourth "license" has the following attributes:
      """
      { "expiry": "2022-06-11T13:00:00.000Z" }
      """
    And the fifth "license" has the following attributes:
      """
      { "expiry": "2022-06-12T00:00:00.000Z" }
      """
    And time is frozen at "2022-06-10T13:00:00.000Z"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses?expires[before]=0"
    Then the response status should be "200"
    And the response body should be an array with 0 "licenses"
    And time is unfrozen

  Scenario: Admin retrieves all licenses expiring before a duration (unsupported)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 5 "licenses"
    And the first "license" has the following attributes:
      """
      { "expiry": "2022-06-10T10:00:00.000Z" }
      """
    And the second "license" has the following attributes:
      """
      { "expiry": null }
      """
    And the third "license" has the following attributes:
      """
      { "expiry": "2022-06-12T00:00:01.000Z" }
      """
    And the fourth "license" has the following attributes:
      """
      { "expiry": "2022-06-11T13:00:00.000Z" }
      """
    And the fifth "license" has the following attributes:
      """
      { "expiry": "2022-06-12T00:00:00.000Z" }
      """
    And time is frozen at "2022-06-10T13:00:00.000Z"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses?expires[before]=90d"
    Then the response status should be "200"
    And the response body should be an array with 0 "licenses"
    And time is unfrozen

  Scenario: Admin retrieves all licenses expiring after a specific date (ISO)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 5 "licenses"
    And the first "license" has the following attributes:
      """
      { "expiry": "2022-06-10T10:00:00.000Z" }
      """
    And the second "license" has the following attributes:
      """
      { "expiry": null }
      """
    And the third "license" has the following attributes:
      """
      { "expiry": "2022-06-12T00:00:01.000Z" }
      """
    And the fourth "license" has the following attributes:
      """
      { "expiry": "2022-06-11T13:00:00.000Z" }
      """
    And the fifth "license" has the following attributes:
      """
      { "expiry": "2022-06-12T00:00:00.000Z" }
      """
    And time is frozen at "2022-06-10T13:00:00.000Z"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses?expires[after]=2022-06-12T00:00:00.000Z"
    Then the response status should be "200"
    And the response body should be an array with 2 "licenses"
    And time is unfrozen

  Scenario: Admin retrieves all licenses expiring after a specific date (unix)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 5 "licenses"
    And the first "license" has the following attributes:
      """
      { "expiry": "2022-06-10T10:00:00.000Z" }
      """
    And the second "license" has the following attributes:
      """
      { "expiry": null }
      """
    And the third "license" has the following attributes:
      """
      { "expiry": "2022-06-12T00:00:01.000Z" }
      """
    And the fourth "license" has the following attributes:
      """
      { "expiry": "2022-06-11T13:00:00.000Z" }
      """
    And the fifth "license" has the following attributes:
      """
      { "expiry": "2022-06-12T00:00:00.000Z" }
      """
    And time is frozen at "2022-06-10T13:00:00.000Z"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses?expires[after]=1654992000"
    Then the response status should be "200"
    And the response body should be an array with 2 "licenses"
    And time is unfrozen

  Scenario: Admin retrieves all licenses expiring after an invalid date
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 5 "licenses"
    And the first "license" has the following attributes:
      """
      { "expiry": "2022-06-10T10:00:00.000Z" }
      """
    And the second "license" has the following attributes:
      """
      { "expiry": null }
      """
    And the third "license" has the following attributes:
      """
      { "expiry": "2022-06-12T00:00:01.000Z" }
      """
    And the fourth "license" has the following attributes:
      """
      { "expiry": "2022-06-11T13:00:00.000Z" }
      """
    And the fifth "license" has the following attributes:
      """
      { "expiry": "2022-06-12T00:00:00.000Z" }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses?expires[after]=invalid"
    Then the response status should be "200"
    And the response body should be an array with 0 "licenses"

  Scenario: Admin retrieves all licenses expiring after a duration (unsupported)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 5 "licenses"
    And the first "license" has the following attributes:
      """
      { "expiry": "2022-06-10T10:00:00.000Z" }
      """
    And the second "license" has the following attributes:
      """
      { "expiry": null }
      """
    And the third "license" has the following attributes:
      """
      { "expiry": "2022-06-12T00:00:01.000Z" }
      """
    And the fourth "license" has the following attributes:
      """
      { "expiry": "2022-06-11T13:00:00.000Z" }
      """
    And the fifth "license" has the following attributes:
      """
      { "expiry": "2022-06-12T00:00:00.000Z" }
      """
    And time is frozen at "2022-06-10T13:00:00.000Z"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses?expires[after]=30d"
    Then the response status should be "200"
    And the response body should be an array with 0 "licenses"
    And time is unfrozen

  Scenario: Admin retrieves all licenses expired within the last 31 days (duration)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 5 "licenses"
    And the first "license" has the following attributes:
      """
      { "expiry": "2022-06-10T12:00:00.000Z" }
      """
    And the second "license" has the following attributes:
      """
      { "expiry": null }
      """
    And the third "license" has the following attributes:
      """
      { "expiry": "2022-01-10T12:00:00.000Z" }
      """
    And the fourth "license" has the following attributes:
      """
      { "expiry": "2022-05-10T13:00:00.000Z" }
      """
    And the fifth "license" has the following attributes:
      """
      { "expiry": "2022-08-01T12:00:00.000Z" }
      """
    And time is frozen at "2022-06-10T13:00:00.000Z"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses?expired[within]=31d"
    Then the response status should be "200"
    And the response body should be an array with 2 "licenses"
    And time is unfrozen

  Scenario: Admin retrieves all licenses expired in the last 31 days (duration)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 5 "licenses"
    And the first "license" has the following attributes:
      """
      { "expiry": "2022-06-10T12:00:00.000Z" }
      """
    And the second "license" has the following attributes:
      """
      { "expiry": null }
      """
    And the third "license" has the following attributes:
      """
      { "expiry": "2022-01-10T12:00:00.000Z" }
      """
    And the fourth "license" has the following attributes:
      """
      { "expiry": "2022-05-10T13:00:00.000Z" }
      """
    And the fifth "license" has the following attributes:
      """
      { "expiry": "2022-08-01T12:00:00.000Z" }
      """
    And time is frozen at "2022-06-10T13:00:00.000Z"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses?expired[in]=31d"
    Then the response status should be "200"
    And the response body should be an array with 2 "licenses"
    And time is unfrozen

  Scenario: Admin retrieves all licenses expired before a timestamp (ISO)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 5 "licenses"
    And the first "license" has the following attributes:
      """
      { "expiry": "2022-06-10T12:00:00.000Z" }
      """
    And the second "license" has the following attributes:
      """
      { "expiry": null }
      """
    And the third "license" has the following attributes:
      """
      { "expiry": "2022-01-10T12:00:00.000Z" }
      """
    And the fourth "license" has the following attributes:
      """
      { "expiry": "2022-05-10T13:00:00.000Z" }
      """
    And the fifth "license" has the following attributes:
      """
      { "expiry": "2022-08-01T12:00:00.000Z" }
      """
    And time is frozen at "2022-06-10T13:00:00.000Z"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses?expired[before]=2022-05-10T13:00:01.000Z"
    Then the response status should be "200"
    And the response body should be an array with 2 "licenses"
    And time is unfrozen

  Scenario: Admin retrieves all licenses expired after a timestamp (unix)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 5 "licenses"
    And the first "license" has the following attributes:
      """
      { "expiry": "2022-06-10T12:00:00.000Z" }
      """
    And the second "license" has the following attributes:
      """
      { "expiry": null }
      """
    And the third "license" has the following attributes:
      """
      { "expiry": "2022-01-10T12:00:00.000Z" }
      """
    And the fourth "license" has the following attributes:
      """
      { "expiry": "2022-05-10T13:00:00.000Z" }
      """
    And the fifth "license" has the following attributes:
      """
      { "expiry": "2022-08-01T12:00:00.000Z" }
      """
    And time is frozen at "2022-06-10T13:00:00.000Z"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses?expired[after]=1652313600"
    Then the response status should be "200"
    And the response body should be an array with 1 "license"
    And time is unfrozen

  Scenario: Admin retrieves licenses with activity inside the last 30 days (simple ISO)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 5 "licenses"
    # New, active
    And the first "license" has the following attributes:
      """
      {
        "createdAt": "2024-10-22T23:59:00.000Z",
        "lastValidatedAt": null,
        "expiry": "2024-09-23T00:00:00.000Z",
        "suspended": false
      }
      """
    # Inactive, expiring
    And the second "license" has the following attributes:
      """
      {
        "createdAt": "2024-07-22T00:00:00.000Z",
        "lastValidatedAt": null,
        "expiry": "2024-10-22T00:00:00.000Z",
        "suspended": false
      }
      """
    # Old, active, expiring
    And the third "license" has the following attributes:
      """
      {
        "createdAt": "2024-7-22T00:00:00.000Z",
        "lastValidatedAt": "2024-10-22T00:00:00.000Z",
        "expiry": "2024-10-21T00:00:00.000Z",
        "suspended": false
      }
      """
    # Old, active, suspended
    And the fourth "license" has the following attributes:
      """
      {
        "createdAt": "2024-10-19T20:00:00.000Z",
        "lastCheckOutAt": "2024-10-21T00:00:00.000Z",
        "expiry": "2023-10-23T00:00:00.000Z",
        "suspended": true
      }
      """
    # Old, inactive
    And the fifth "license" has the following attributes:
      """
      {
        "createdAt": "2022-10-23T00:00:00.000Z",
        "lastValidatedAt": "2023-10-23T00:00:00.000Z",
        "expiry": null,
        "suspended": false
      }
      """
    And time is frozen at "2024-10-23T00:00:00.000Z"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses?activity[inside]=30d"
    Then the response status should be "200"
    And the response body should be an array with 3 "licenses"
    And time is unfrozen

  Scenario: Admin retrieves licenses with activity inside the last 1 day, 5 hours, 59 minutes, 59 seconds (complex ISO)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 5 "licenses"
    # New, active
    And the first "license" has the following attributes:
      """
      {
        "createdAt": "2024-10-22T23:59:00.000Z",
        "lastValidatedAt": null,
        "expiry": "2024-09-23T00:00:00.000Z",
        "suspended": false
      }
      """
    # Inactive, expiring
    And the second "license" has the following attributes:
      """
      {
        "createdAt": "2024-07-22T00:00:00.000Z",
        "lastValidatedAt": null,
        "expiry": "2024-10-22T00:00:00.000Z",
        "suspended": false
      }
      """
    # Old, active, expiring
    And the third "license" has the following attributes:
      """
      {
        "createdAt": "2024-7-22T00:00:00.000Z",
        "lastValidatedAt": "2024-10-22T00:00:00.000Z",
        "expiry": "2024-10-21T00:00:00.000Z",
        "suspended": false
      }
      """
    # Old, active, suspended
    And the fourth "license" has the following attributes:
      """
      {
        "createdAt": "2024-10-19T20:00:00.000Z",
        "lastCheckOutAt": "2024-10-21T00:00:00.000Z",
        "expiry": "2023-10-23T00:00:00.000Z",
        "suspended": true
      }
      """
    # Old, inactive
    And the fifth "license" has the following attributes:
      """
      {
        "createdAt": "2022-10-23T00:00:00.000Z",
        "lastValidatedAt": "2023-10-23T00:00:00.000Z",
        "expiry": null,
        "suspended": false
      }
      """
    And time is frozen at "2024-10-23T00:00:00.000Z"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses?activity[inside]=P1DT5H59M59S"
    Then the response status should be "200"
    And the response body should be an array with 2 "licenses"
    And time is unfrozen

  Scenario: Admin retrieves licenses with activity outside the last 30 days (simple ISO)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 5 "licenses"
    # New, active
    And the first "license" has the following attributes:
      """
      {
        "createdAt": "2024-10-22T23:59:00.000Z",
        "lastValidatedAt": null,
        "expiry": "2024-09-23T00:00:00.000Z",
        "suspended": false
      }
      """
    # Inactive, expiring
    And the second "license" has the following attributes:
      """
      {
        "createdAt": "2024-07-22T00:00:00.000Z",
        "lastValidatedAt": null,
        "expiry": "2024-10-22T00:00:00.000Z",
        "suspended": false
      }
      """
    # Old, active, expiring
    And the third "license" has the following attributes:
      """
      {
        "createdAt": "2024-7-22T00:00:00.000Z",
        "lastValidatedAt": "2024-10-22T00:00:00.000Z",
        "expiry": "2024-10-21T00:00:00.000Z",
        "suspended": false
      }
      """
    # Old, active, suspended
    And the fourth "license" has the following attributes:
      """
      {
        "createdAt": "2024-10-19T20:00:00.000Z",
        "lastCheckOutAt": "2024-10-21T00:00:00.000Z",
        "expiry": "2023-10-23T00:00:00.000Z",
        "suspended": true
      }
      """
    # Old, inactive
    And the fifth "license" has the following attributes:
      """
      {
        "createdAt": "2022-10-23T00:00:00.000Z",
        "lastValidatedAt": "2023-10-23T00:00:00.000Z",
        "expiry": null,
        "suspended": false
      }
      """
    And time is frozen at "2024-10-23T00:00:00.000Z"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses?activity[outside]=30d"
    Then the response status should be "200"
    And the response body should be an array with 2 "licenses"
    And time is unfrozen

  Scenario: Admin retrieves licenses with activity outside the last 1 day, 5 hours, 59 minutes, 59 seconds (complex ISO)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 5 "licenses"
    # New, active
    And the first "license" has the following attributes:
      """
      {
        "createdAt": "2024-10-22T23:59:00.000Z",
        "lastValidatedAt": null,
        "expiry": "2024-09-23T00:00:00.000Z",
        "suspended": false
      }
      """
    # Inactive, expiring
    And the second "license" has the following attributes:
      """
      {
        "createdAt": "2024-07-22T00:00:00.000Z",
        "lastValidatedAt": null,
        "expiry": "2024-10-22T00:00:00.000Z",
        "suspended": false
      }
      """
    # Old, active, expiring
    And the third "license" has the following attributes:
      """
      {
        "createdAt": "2024-7-22T00:00:00.000Z",
        "lastValidatedAt": "2024-10-22T00:00:00.000Z",
        "expiry": "2024-10-21T00:00:00.000Z",
        "suspended": false
      }
      """
    # Old, active, suspended
    And the fourth "license" has the following attributes:
      """
      {
        "createdAt": "2024-10-19T20:00:00.000Z",
        "lastCheckOutAt": "2024-10-21T00:00:00.000Z",
        "expiry": "2023-10-23T00:00:00.000Z",
        "suspended": true
      }
      """
    # Old, inactive
    And the fifth "license" has the following attributes:
      """
      {
        "createdAt": "2022-10-23T00:00:00.000Z",
        "lastValidatedAt": "2023-10-23T00:00:00.000Z",
        "expiry": null,
        "suspended": false
      }
      """
    And time is frozen at "2024-10-23T00:00:00.000Z"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses?activity[outside]=P1DT5H59M59S"
    Then the response status should be "200"
    And the response body should be an array with 3 "licenses"
    And time is unfrozen

  Scenario: Admin retrieves licenses with activity outside the last 30 days (simple ISO)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 5 "licenses"
    # New, active
    And the first "license" has the following attributes:
      """
      {
        "createdAt": "2024-10-22T23:59:00.000Z",
        "lastValidatedAt": null,
        "expiry": "2024-09-23T00:00:00.000Z",
        "suspended": false
      }
      """
    # Inactive, expiring
    And the second "license" has the following attributes:
      """
      {
        "createdAt": "2024-07-22T00:00:00.000Z",
        "lastValidatedAt": null,
        "expiry": "2024-10-22T00:00:00.000Z",
        "suspended": false
      }
      """
    # Old, active, expiring
    And the third "license" has the following attributes:
      """
      {
        "createdAt": "2024-7-22T00:00:00.000Z",
        "lastValidatedAt": "2024-10-22T00:00:00.000Z",
        "expiry": "2024-10-21T00:00:00.000Z",
        "suspended": false
      }
      """
    # Old, active, suspended
    And the fourth "license" has the following attributes:
      """
      {
        "createdAt": "2024-10-19T20:00:00.000Z",
        "lastCheckOutAt": "2024-10-21T00:00:00.000Z",
        "expiry": "2023-10-23T00:00:00.000Z",
        "suspended": true
      }
      """
    # Old, inactive
    And the fifth "license" has the following attributes:
      """
      {
        "createdAt": "2022-10-23T00:00:00.000Z",
        "lastValidatedAt": "2023-10-23T00:00:00.000Z",
        "expiry": null,
        "suspended": false
      }
      """
    And time is frozen at "2024-10-23T00:00:00.000Z"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses?activity[outside]=30d"
    Then the response status should be "200"
    And the response body should be an array with 2 "licenses"
    And time is unfrozen

  Scenario: Admin retrieves licenses with activity after a specific date (ISO)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 5 "licenses"
    # New, active
    And the first "license" has the following attributes:
      """
      {
        "createdAt": "2024-10-22T23:59:00.000Z",
        "lastValidatedAt": null,
        "expiry": "2024-09-23T00:00:00.000Z",
        "suspended": false
      }
      """
    # Inactive, expiring
    And the second "license" has the following attributes:
      """
      {
        "createdAt": "2024-07-22T00:00:00.000Z",
        "lastValidatedAt": null,
        "expiry": "2024-10-22T00:00:00.000Z",
        "suspended": false
      }
      """
    # Old, active, expiring
    And the third "license" has the following attributes:
      """
      {
        "createdAt": "2024-7-22T00:00:00.000Z",
        "lastValidatedAt": "2024-10-22T00:00:00.000Z",
        "expiry": "2024-10-21T00:00:00.000Z",
        "suspended": false
      }
      """
    # Old, active, suspended
    And the fourth "license" has the following attributes:
      """
      {
        "createdAt": "2024-10-19T20:00:00.000Z",
        "lastCheckOutAt": "2024-10-21T00:00:00.000Z",
        "expiry": "2023-10-23T00:00:00.000Z",
        "suspended": true
      }
      """
    # Old, inactive
    And the fifth "license" has the following attributes:
      """
      {
        "createdAt": "2022-10-23T00:00:00.000Z",
        "lastValidatedAt": "2023-10-23T00:00:00.000Z",
        "expiry": null,
        "suspended": false
      }
      """
    And time is frozen at "2024-10-23T00:00:00.000Z"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses?activity[after]=2024-04-21T00:00:00.000Z"
    Then the response status should be "200"
    And the response body should be an array with 4 "licenses"
    And time is unfrozen

  Scenario: Admin retrieves licenses with activity after a specific date (unix)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 5 "licenses"
    # New, active
    And the first "license" has the following attributes:
      """
      {
        "createdAt": "2024-10-22T23:59:00.000Z",
        "lastValidatedAt": null,
        "expiry": "2024-09-23T00:00:00.000Z",
        "suspended": false
      }
      """
    # Inactive, expiring
    And the second "license" has the following attributes:
      """
      {
        "createdAt": "2024-07-22T00:00:00.000Z",
        "lastValidatedAt": null,
        "expiry": "2024-10-22T00:00:00.000Z",
        "suspended": false
      }
      """
    # Old, active, expiring
    And the third "license" has the following attributes:
      """
      {
        "createdAt": "2024-7-22T00:00:00.000Z",
        "lastValidatedAt": "2024-10-22T00:00:00.000Z",
        "expiry": "2024-10-21T00:00:00.000Z",
        "suspended": false
      }
      """
    # Old, active, suspended
    And the fourth "license" has the following attributes:
      """
      {
        "createdAt": "2024-10-19T20:00:00.000Z",
        "lastCheckOutAt": "2024-10-21T00:00:00.000Z",
        "expiry": "2023-10-23T00:00:00.000Z",
        "suspended": true
      }
      """
    # Old, inactive
    And the fifth "license" has the following attributes:
      """
      {
        "createdAt": "2022-10-23T00:00:00.000Z",
        "lastValidatedAt": "2023-10-23T00:00:00.000Z",
        "expiry": null,
        "suspended": false
      }
      """
    And time is frozen at "2024-10-23T00:00:00.000Z"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses?activity[after]=1713657600"
    Then the response status should be "200"
    And the response body should be an array with 4 "licenses"
    And time is unfrozen

  Scenario: Admin retrieves licenses with activity before a specific date (ISO)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 5 "licenses"
    # New, active
    And the first "license" has the following attributes:
      """
      {
        "createdAt": "2024-10-22T23:59:00.000Z",
        "lastValidatedAt": null,
        "expiry": "2024-09-23T00:00:00.000Z",
        "suspended": false
      }
      """
    # Inactive, expiring
    And the second "license" has the following attributes:
      """
      {
        "createdAt": "2024-07-22T00:00:00.000Z",
        "lastValidatedAt": null,
        "expiry": "2024-10-22T00:00:00.000Z",
        "suspended": false
      }
      """
    # Old, active, expiring
    And the third "license" has the following attributes:
      """
      {
        "createdAt": "2024-7-22T00:00:00.000Z",
        "lastValidatedAt": "2024-10-22T00:00:00.000Z",
        "expiry": "2024-10-21T00:00:00.000Z",
        "suspended": false
      }
      """
    # Old, active, suspended
    And the fourth "license" has the following attributes:
      """
      {
        "createdAt": "2024-10-19T20:00:00.000Z",
        "lastCheckOutAt": "2024-10-21T00:00:00.000Z",
        "expiry": "2023-10-23T00:00:00.000Z",
        "suspended": true
      }
      """
    # Old, inactive
    And the fifth "license" has the following attributes:
      """
      {
        "createdAt": "2022-10-23T00:00:00.000Z",
        "lastValidatedAt": "2023-10-23T00:00:00.000Z",
        "expiry": null,
        "suspended": false
      }
      """
    And time is frozen at "2024-10-23T00:00:00.000Z"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses?activity[before]=2024-04-21T00:00:00.000Z"
    Then the response status should be "200"
    And the response body should be an array with 1 "license"
    And time is unfrozen

  Scenario: Admin retrieves licenses with activity before a specific date (unix)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 5 "licenses"
    # New, active
    And the first "license" has the following attributes:
      """
      {
        "createdAt": "2024-10-22T23:59:00.000Z",
        "lastValidatedAt": null,
        "expiry": "2024-09-23T00:00:00.000Z",
        "suspended": false
      }
      """
    # Inactive, expiring
    And the second "license" has the following attributes:
      """
      {
        "createdAt": "2024-07-22T00:00:00.000Z",
        "lastValidatedAt": null,
        "expiry": "2024-10-22T00:00:00.000Z",
        "suspended": false
      }
      """
    # Old, active, expiring
    And the third "license" has the following attributes:
      """
      {
        "createdAt": "2024-7-22T00:00:00.000Z",
        "lastValidatedAt": "2024-10-22T00:00:00.000Z",
        "expiry": "2024-10-21T00:00:00.000Z",
        "suspended": false
      }
      """
    # Old, active, suspended
    And the fourth "license" has the following attributes:
      """
      {
        "createdAt": "2024-10-19T20:00:00.000Z",
        "lastCheckOutAt": "2024-10-21T00:00:00.000Z",
        "expiry": "2023-10-23T00:00:00.000Z",
        "suspended": true
      }
      """
    # Old, inactive
    And the fifth "license" has the following attributes:
      """
      {
        "createdAt": "2022-10-23T00:00:00.000Z",
        "lastValidatedAt": "2023-10-23T00:00:00.000Z",
        "expiry": null,
        "suspended": false
      }
      """
    And time is frozen at "2024-10-23T00:00:00.000Z"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses?activity[before]=1713657600"
    Then the response status should be "200"
    And the response body should be an array with 1 "license"
    And time is unfrozen

  Scenario: Admin retrieves licenses with an invalid activity filter
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 5 "licenses"
    # New, active
    And the first "license" has the following attributes:
      """
      {
        "createdAt": "2024-10-22T23:59:00.000Z",
        "lastValidatedAt": null,
        "expiry": "2024-09-23T00:00:00.000Z",
        "suspended": false
      }
      """
    # Inactive, expiring
    And the second "license" has the following attributes:
      """
      {
        "createdAt": "2024-07-22T00:00:00.000Z",
        "lastValidatedAt": null,
        "expiry": "2024-10-22T00:00:00.000Z",
        "suspended": false
      }
      """
    # Old, active, expiring
    And the third "license" has the following attributes:
      """
      {
        "createdAt": "2024-7-22T00:00:00.000Z",
        "lastValidatedAt": "2024-10-22T00:00:00.000Z",
        "expiry": "2024-10-21T00:00:00.000Z",
        "suspended": false
      }
      """
    # Old, active, suspended
    And the fourth "license" has the following attributes:
      """
      {
        "createdAt": "2024-10-19T20:00:00.000Z",
        "lastCheckOutAt": "2024-10-21T00:00:00.000Z",
        "expiry": "2023-10-23T00:00:00.000Z",
        "suspended": true
      }
      """
    # Old, inactive
    And the fifth "license" has the following attributes:
      """
      {
        "createdAt": "2022-10-23T00:00:00.000Z",
        "lastValidatedAt": "2023-10-23T00:00:00.000Z",
        "expiry": null,
        "suspended": false
      }
      """
    And time is frozen at "2024-10-23T00:00:00.000Z"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses?activity[invalid]=1y"
    Then the response status should be "200"
    And the response body should be an array with 0 "licenses"
    And time is unfrozen

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
    And the response body should be an array with 2 "licenses"

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
    And the response body should be an array with 1 "license"

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
    And the response body should be an array with 1 "license"

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
    And the response body should be an array with 0 "licenses"

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
    And the response body should be an array with 3 "licenses"

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
    And the response body should be an array with 2 "licenses"

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
    And the response body should be an array with 1 "license"

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
    And the response body should be an array with 1 "license"

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
    And the response body should be an array with 2 "licenses"

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
    And the response body should be an array with 1 "license"

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
    And the response body should be an array with 0 "licenses"

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
    And the response body should be an array with 1 "license"

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
    And the response body should be an array with 0 "licenses"

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
    And the response body should be an array with 2 "licenses"

  Scenario: Admin retrieves licenses filtered by owner ID
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
    When I send a GET request to "/accounts/test1/licenses?owner=$users[1]"
    Then the response status should be "200"
    And the response body should be an array with 3 "licenses"

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
    And the response body should be an array with 3 "licenses"

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
    And the response body should be an array with 1 "license"

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
    And the response body should be an array with 3 "licenses"

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
    And the response body should be an array with 4 "licenses"

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
        "lastCheckOutAt": "$time.1.day.ago",
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
    And the response body should be an array with 3 "licenses"

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
    And the response body should be an array with 3 "licenses"

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
    And the response body should be an array with 2 "licenses"

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
    And the response body should be an array with 1 "license"

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
    And the response body should be an array with 1 "license"

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
    And the response body should be an array with 1 "license"

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
    And the response body should be an array with 1 "license"

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
    And the response body should be an array with 0 "licenses"

  Scenario: Product retrieves licenses filtered by status (active)
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "policy" for the last "product"
    And the current account has 5 "licenses" for the last "policy"
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
        "lastCheckInAt": "$time.1.day.ago",
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
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses?status=ACTIVE"
    Then the response status should be "200"
    And the response body should be an array with 3 "licenses"

  Scenario: Product retrieves licenses filtered by status (inactive)
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "policy" for the last "product"
    And the current account has 5 "licenses" for the last "policy"
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
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses?status=INACTIVE"
    Then the response status should be "200"
    And the response body should be an array with 2 "licenses"

  Scenario: Product retrieves all licenses for their product
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "license" for the last "policy"
    And the current account has 2 "licenses"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses"
    Then the response status should be "200"
    And the response body should be an array with 1 "license"

  Scenario: Admin attempts to retrieve all licenses for another account
    Given I am an admin of account "test2"
    But the current account is "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses"
    Then the response status should be "401"
    And the response body should be an array of 1 error

  Scenario: User retrieves all licenses for their account (license owner)
    Given the current account is "test1"
    And the current account has 1 "user"
    And the current account has 3 "licenses" for the last "user" as "owner"
    And the current account has 3 "licenses"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses"
    Then the response status should be "200"
    And the response body should be an array with 3 "licenses"

  Scenario: User retrieves all licenses for their account (license user)
    Given the current account is "test1"
    And the current account has 1 "user"
    And the current account has 3 "licenses"
    And the current account has 1 "license-user" for the first "license" and the last "user"
    And the current account has 1 "license-user" for the second "license" and the last "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses"
    Then the response status should be "200"
    And the response body should be an array with 2 "licenses"

  Scenario: User retrieves all licenses for their account (mixed)
    Given the current account is "test1"
    And the current account has 1 "user"
    And the current account has 3 "licenses" for the last "user" as "owner"
    And the current account has 3 "licenses"
    And the current account has 1 "license-user" for the fourth "license" and the last "user"
    And the current account has 1 "license-user" for the fifth "license" and the last "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses"
    Then the response status should be "200"
    And the response body should be an array with 5 "license"

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
    And the response body should be an array with 1 "license"

  Scenario: User retrieves all licenses for their account filtered by metadata ID
    Given the current account is "test1"
    And the current account has 1 "user"
    And the current account has 1 "license" for the last "user" as "owner"
    And the current account has 2 "licenses"
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
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses?metadata[id]=9cd5a11f-7649-4770-8744-74bd794ddc08"
    Then the response status should be "200"
    And the response body should be an array with 1 "license"

  Scenario: User attempts an SQL injection attack for all licenses
    Given the current account is "test1"
    And the current account has 1 "user"
    And the current account has 1 "license" for the last "user" as "owner"
    And the current account has 2 "licenses"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses?user=ef8e7a71-6b54-4a9b-8717-778516c9ad25%27%20or%201=1"
    Then the response status should be "200"
    And the response body should be an array with 1 "license"

  @ee
  Scenario: Environment retrieves all isolated licenses
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And the current account has 3 isolated "licenses"
    And the current account has 3 shared "licenses"
    And the current account has 3 global "licenses"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    When I send a GET request to "/accounts/test1/licenses"
    Then the response status should be "200"
    And the response body should be an array with 3 "licenses"
    And the response body should be an array of 3 "licenses" with the following relationships:
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
  Scenario: Environment retrieves all shared licenses
    Given the current account is "test1"
    And the current account has 1 shared "environment"
    And the current account has 3 isolated "licenses"
    And the current account has 3 shared "licenses"
    And the current account has 3 global "licenses"
    And I am an environment of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses?environment=shared"
    Then the response status should be "200"
    And the response body should be an array with 6 "licenses"
    And the response body should be an array of 3 "licenses" with the following relationships:
      """
      {
        "environment": {
          "links": { "related": "/v1/accounts/$account/environments/$environments[0]" },
          "data": { "type": "environments", "id": "$environments[0]" }
        }
      }
      """
    And the response body should be an array of 3 "licenses" with the following relationships:
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
