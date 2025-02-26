@api/v1
Feature: Token sessions
  Background:
    Given the following "accounts" exist:
      | Name    | Slug  |
      | Test 1  | test1 |
      | Test 2  | test2 |
    And I send and accept JSON

  # generate
  Scenario: Admin generates a new session token via basic authentication
    Given the current account is "test1"
    And I am an admin of account "test1"
    And I send the following headers:
      """
      { "Authorization": "Basic \"$users[0].email:password\"" }
      """
    When I send a POST request to "/accounts/test1/tokens"
    Then the response status should be "201"
    And the response body should be a "token"
    And the response headers should contain "Set-Cookie" with an encrypted "session_id" cookie:
      """
      $sessions[0]
      """
    And the first "session" should have the following attributes:
      """
      {
        "bearerType": "User",
        "bearerId": "$users[0]",
        "tokenId": "$tokens[0]"
      }
      """

  Scenario: Admin generates a new session token via token authentication
    Given the current account is "test1"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/tokens"
    Then the response status should be "201"
    And the response body should be a "token"
    And the response headers should contain "Set-Cookie" with an encrypted "session_id" cookie:
      """
      $sessions[0]
      """
    And the first "session" should have the following attributes:
      """
      {
        "bearerType": "User",
        "bearerId": "$users[0]",
        "tokenId": "$tokens[1]"
      }
      """

  Scenario: Admin generates a new session token for an environment
    Given the current account is "test1"
    And the current account has 1 shared "environment"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/tokens" with the following:
      """
      {
        "data": {
          "type": "token",
          "relationships": {
            "bearer": {
              "data": { "type": "environment", "id": "$environments[0]" }
            }
          }
        }
      }
      """
    Then the response status should be "403"

  Scenario: Admin generates a new session token for a product
    Given the current account is "test1"
    And the current account has 1 "product"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/tokens" with the following:
      """
      {
        "data": {
          "type": "token",
          "relationships": {
            "bearer": {
              "data": { "type": "product", "id": "$products[0]" }
            }
          }
        }
      }
      """
    Then the response status should be "403"

  Scenario: Admin generates a new session token for a license
    Given the current account is "test1"
    And the current account has 1 "license"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/tokens" with the following:
      """
      {
        "data": {
          "type": "token",
          "relationships": {
            "bearer": {
              "data": { "type": "license", "id": "$licenses[0]" }
            }
          }
        }
      }
      """
    Then the response status should be "403"

  Scenario: Admin generates a new session token for a user
    Given the current account is "test1"
    And the current account has 1 "user"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/tokens" with the following:
      """
      {
        "data": {
          "type": "token",
          "relationships": {
            "bearer": {
              "data": { "type": "user", "id": "$users[1]" }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the response body should be a "token"
    And the response headers should contain "Set-Cookie" with an encrypted "session_id" cookie:
      """
      $sessions[0]
      """
    And the first "session" should have the following attributes:
      """
      {
        "bearerType": "User",
        "bearerId": "$users[1]",
        "tokenId": "$tokens[1]"
      }
      """

  Scenario: Environment generates a new session token (isolated)
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    When I send a POST request to "/accounts/test1/tokens"
    Then the response status should be "201"
    And the response body should be a "token"
    And the response headers should contain "Set-Cookie" with an encrypted "session_id" cookie:
      """
      $sessions[0]
      """
    And the response headers should contain the following:
      """
      { "Keygen-Environment": "isolated" }
      """
    And the first "session" should have the following attributes:
      """
      {
        "bearerType": "Environment",
        "bearerId": "$environments[0]",
        "tokenId": "$tokens[1]"
      }
      """

  Scenario: Environment creates a new session token (shared)
    Given the current account is "test1"
    And the current account has 1 shared "environment"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
    When I send a POST request to "/accounts/test1/tokens"
    Then the response status should be "201"
    And the response body should be a "token"
    And the response headers should contain "Set-Cookie" with an encrypted "session_id" cookie:
      """
      $sessions[0]
      """
    And the response headers should contain the following:
      """
      { "Keygen-Environment": "shared" }
      """
    And the first "session" should have the following attributes:
      """
      {
        "bearerType": "Environment",
        "bearerId": "$environments[0]",
        "tokenId": "$tokens[1]"
      }
      """

  # revoke
  Scenario: Admin revokes a session token via basic authentication
    Given the current account is "test1"
    And I am an admin of account "test1"
    And I authenticate with a session
    When I send a DELETE request to "/accounts/test1/tokens/$0"
    Then the response status should be "204"
    And the current account should have 0 "sessions"

  # environments
  Scenario: License validates itself via session authentication (isolated license in isolated env)
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And the current account has 1 isolated "license"
    And I am a license of account "test1"
    And I authenticate with a session
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    When I send a POST request to "/accounts/test1/licenses/$0/actions/validate"
    Then the response status should be "200"
    And the response body should be a "license"
    And the response headers should contain the following:
      """
      { "Keygen-Environment": "isolated" }
      """

  Scenario: License validates itself via session authentication (shared license in shared env)
    Given the current account is "test1"
    And the current account has 1 shared "environment"
    And the current account has 1 shared "license"
    And I am a license of account "test1"
    And I authenticate with a session
    And I send the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
    When I send a POST request to "/accounts/test1/licenses/$0/actions/validate"
    Then the response status should be "200"
    And the response body should be a "license"
    And the response headers should contain the following:
      """
      { "Keygen-Environment": "shared" }
      """

  Scenario: License validates itself via session authentication (global license in isolated env)
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And the current account has 1 global "license"
    And I am a license of account "test1"
    And I authenticate with a session
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    When I send a POST request to "/accounts/test1/licenses/$0/actions/validate"
    Then the response status should be "401"
    And the response headers should contain the following:
      """
      { "Keygen-Environment": "isolated" }
      """

  Scenario: License validates itself via session authentication (global license in shared env)
    Given the current account is "test1"
    And the current account has 1 shared "environment"
    And the current account has 1 global "license"
    And I am a license of account "test1"
    And I authenticate with a session
    And I send the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
    When I send a POST request to "/accounts/test1/licenses/$0/actions/validate"
    Then the response status should be "200"
    And the response body should be a "license"
    And the response headers should contain the following:
      """
      { "Keygen-Environment": "shared" }
      """

  Scenario: License validates itself via session authentication (shared license in global env)
    Given the current account is "test1"
    And the current account has 1 shared "environment"
    And the current account has 1 shared "license"
    And I am a license of account "test1"
    And I authenticate with a session
    When I send a POST request to "/accounts/test1/licenses/$0/actions/validate"
    Then the response status should be "401"

  Scenario: License validates itself via session authentication (isolated license in shared env)
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And the current account has 1 shared "environment"
    And the current account has 1 isolated "license"
    And I am a license of account "test1"
    And I authenticate with a session
    And I send the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
    When I send a POST request to "/accounts/test1/licenses/$0/actions/validate"
    Then the response status should be "401"
    And the response headers should contain the following:
      """
      { "Keygen-Environment": "shared" }
      """

  Scenario: License validates itself via session authentication (isolated license in global env)
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And the current account has 1 isolated "license"
    And I am a license of account "test1"
    And I authenticate with a session
    When I send a POST request to "/accounts/test1/licenses/$0/actions/validate"
    Then the response status should be "401"

  # create
  Scenario: User creates a trial license via session authentication
    Given the current account is "test1"
    And the current account has 1 "policy" with the following:
      """
      { "name": "Trial", "protected": false }
      """
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I authenticate with a session
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "license",
          "relationships": {
            "policy": {
              "data": { "type": "policy", "id": "$policies[0]" }
            },
            "owner": {
              "data": { "type": "user", "id": "$users[1]" }
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the response body should be a "license"

  Scenario: User creates a pro license via session authentication
    Given the current account is "test1"
    And the current account has 1 "policy" with the following:
      """
      { "name": "Pro", "protected": true }
      """
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I authenticate with a session
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "license",
          "relationships": {
            "policy": {
              "data": { "type": "policy", "id": "$policies[0]" }
            },
            "owner": {
              "data": { "type": "user", "id": "$users[1]" }
            }
          }
        }
      }
      """
    Then the response status should be "403"

  Scenario: User creates a license via session authentication
    Given the current account is "test1"
    And the current account has 1 "policy"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I authenticate with a session
    When I send a POST request to "/accounts/test1/licenses" with the following:
      """
      {
        "data": {
          "type": "license",
          "relationships": {
            "policy": {
              "data": { "type": "policy", "id": "$policies[0]" }
            }
          }
        }
      }
      """
    Then the response status should be "403"

  # read
  Scenario: User validates their license key via session authentication
    Given the current account is "test1"
    And the current account has 1 "user"
    And the current account has 1 "license" for the last "user" as "owner"
    And I am an user of account "test1"
    And I authenticate with a session
    When I send a POST request to "/accounts/test1/licenses/$0/actions/validate"
    Then the response status should be "200"
    And the response body should be a "license"

  Scenario: User validates a license key via session authentication
    Given the current account is "test1"
    And the current account has 1 "user"
    And the current account has 1 "license"
    And I am a user of account "test1"
    And I authenticate with a session
    When I send a POST request to "/accounts/test1/licenses/$0/actions/validate"
    Then the response status should be "404"

  # update
  Scenario: Product updates their license via session authentication
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "license" for the last "policy"
    And I am a product of account "test1"
    And I authenticate with a session
    When I send a PATCH request to "/accounts/test1/licenses/$0" with the following:
      """
      {
        "data": {
          "type": "license",
          "attributes": { "name": "Updated" }
        }
      }
      """
    Then the response status should be "200"
    And the response body should be a "license" with the name "Updated"

  Scenario: Product updates a license via session authentication
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "license"
    And I am a product of account "test1"
    And I authenticate with a session
    When I send a PATCH request to "/accounts/test1/licenses/$0" with the following:
      """
      {
        "data": {
          "type": "license",
          "attributes": { "name": "Updated" }
        }
      }
      """
    Then the response status should be "404"

  # delete
  Scenario: Product deletes their license via session authentication
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "license" for the last "policy"
    And I am a product of account "test1"
    And I authenticate with a session
    When I send a DELETE request to "/accounts/test1/licenses/$0"
    Then the response status should be "204"

  Scenario: Product deletes a license via session authentication
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "license"
    And I am a product of account "test1"
    And I authenticate with a session
    When I send a DELETE request to "/accounts/test1/licenses/$0"
    Then the response status should be "404"
