@api/v1
Feature: Token sessions
  Background:
    Given the following "accounts" exist:
      | Name    | Slug  |
      | Test 1  | test1 |
      | Test 2  | test2 |
    And I send the following headers:
      """
      { "Origin": "https://portal.keygen.sh" }
      """
    And I send and accept JSON

  # generate
  Scenario: Admin generates a new session token with basic authentication
    Given the current account is "test1"
    And time is frozen at "2552-02-28T00:00:00.000Z"
    And I am an admin of account "test1"
    And I send the following headers:
      """
      {
        "Authorization": "Basic \"$users[0].email:password\"",
        "User-Agent": "acme/1.0"
      }
      """
    When I send a POST request to "/accounts/test1/tokens"
    Then the response status should be "201"
    And the response body should be a "token"
    And the response headers should contain "Set-Cookie" with an encrypted cookie:
      """
      session_id=$sessions[0]; domain=keygen.sh; path=/; expires=Mon, 06 Mar 2552 00:00:00 GMT; secure; httponly; samesite=None; partitioned;
      """
    And the first "session" should have the following attributes:
      """
      {
        "bearerType": "User",
        "bearerId": "$users[0]",
        "tokenId": "$tokens[0]",
        "userAgent": "acme/1.0",
        "ip": "127.0.0.1",
        "lastUsedAt": null
      }
      """
    And time is unfrozen

  Scenario: Admin generates a new session token with token authentication
    Given the current account is "test1"
    And I am an admin of account "test1"
    And I use an authentication token
    And time is frozen at "2552-02-28T00:00:00.000Z"
    When I send a POST request to "/accounts/test1/tokens"
    Then the response status should be "201"
    And the response body should be a "token"
    And the response headers should contain "Set-Cookie" with an encrypted cookie:
      """
      session_id=$sessions[0]; domain=keygen.sh; path=/; expires=Mon, 06 Mar 2552 00:00:00 GMT; secure; httponly; samesite=None; partitioned;
      """
    And the first "session" should have the following attributes:
      """
      {
        "bearerType": "User",
        "bearerId": "$users[0]",
        "tokenId": "$tokens[1]"
      }
      """
    And time is unfrozen

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
    And the response headers should contain "Set-Cookie" with an encrypted cookie:
      """
      session_id=$sessions[0];
      """
    And the first "session" should have the following attributes:
      """
      {
        "bearerType": "User",
        "bearerId": "$users[1]",
        "tokenId": "$tokens[1]"
      }
      """

  @ee
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
    And the response headers should contain "Set-Cookie" with an encrypted cookie:
      """
      session_id=$sessions[0];
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

  @ee
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
    And the response headers should contain "Set-Cookie" with an encrypted cookie:
      """
      session_id=$sessions[0];
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
  Scenario: Admin revokes their session token with session authentication
    Given the current account is "test1"
    And I am an admin of account "test1"
    And I authenticate with a session
    When I send a DELETE request to "/accounts/test1/tokens/$0"
    Then the response status should be "204"
    And the response headers should contain "Set-Cookie" with a cookie:
      """
      session_id=; domain=keygen.sh; expires=Thu, 01 Jan 1970 00:00:00 GMT; samesite=None; partitioned;
      """
    And the current account should have 0 "sessions"

  Scenario: Admin revokes their session token with token authentication
    Given the current account is "test1"
    And I am an admin of account "test1"
    And I authenticate with a token
    When I send a DELETE request to "/accounts/test1/tokens/$0"
    Then the response status should be "204"
    And the response headers should not contain "Set-Cookie"
    And the current account should have 0 "sessions"

  Scenario: Admin revokes a session token with session authentication
    Given the current account is "test1"
    And the current account has 3 "tokens"
    And the current account has 1 "session" for the third "token"
    And I am an admin of account "test1"
    And I authenticate with a session
    When I send a DELETE request to "/accounts/test1/tokens/$2"
    Then the response status should be "204"
    And the response headers should not contain "Set-Cookie"
    And the current account should have 1 "session"

  # regen
  Scenario: Admin regenerates the current token with session authentication
    Given the current account is "test1"
    And I am an admin of account "test1"
    And I authenticate with a session
    When I send a PUT request to "/accounts/test1/tokens"
    Then the response status should be "200"
    And the response headers should contain "Set-Cookie" with an encrypted cookie:
      """
      session_id=$sessions[0];
      """
    And the current account should have 1 "session"

  Scenario: Admin regenerates their token with session authentication
    Given the current account is "test1"
    And I am an admin of account "test1"
    And I authenticate with a session
    When I send a PUT request to "/accounts/test1/tokens/$0"
    Then the response status should be "200"
    And the response headers should contain "Set-Cookie" with an encrypted cookie:
      """
      session_id=$sessions[0];
      """
    And the current account should have 1 "session"

  Scenario: Admin regenerates a token with session authentication
    Given the current account is "test1"
    And the current account has 3 "tokens"
    And the current account has 1 "session" for the third "token"
    And I am an admin of account "test1"
    And I authenticate with a session
    When I send a PUT request to "/accounts/test1/tokens/$2"
    Then the response status should be "200"
    And the response headers should not contain "Set-Cookie"
    And the current account should have 1 "session"

  # expiry
  Scenario: User reads their profile with a valid session
    Given the current account is "test1"
    And the current account has 1 "user"
    And time is frozen at "2552-02-28T00:00:00.000Z"
    And I am a user of account "test1"
    And I authenticate with a session
    When I send a GET request to "/accounts/test1/me"
    Then the response status should be "200"
    And the response headers should not contain "Set-Cookie"
    And time is unfrozen

  # should extend session expiry while it's in use until max age
  Scenario: User reads their profile with an expiring session
    Given the current account is "test1"
    And the current account has 1 "user"
    And time is frozen at "2552-03-03T00:00:00.000Z"
    And I am a user of account "test1"
    And I authenticate with an expiring session
    When I send a GET request to "/accounts/test1/me"
    Then the response status should be "200"
    And the response headers should contain "Set-Cookie" with an encrypted cookie:
      """
      session_id=$sessions[0]; domain=keygen.sh; path=/; expires=Fri, 03 Mar 2552 01:10:00 GMT; secure; httponly; samesite=None; partitioned;
      """
    And time is unfrozen

  Scenario: User reads their profile with an expired session
    Given the current account is "test1"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I authenticate with an expired session
    When I send a GET request to "/accounts/test1/me"
    Then the response status should be "401"
    And the response headers should contain "Set-Cookie" with a cookie:
      """
      session_id=; domain=keygen.sh; expires=Thu, 01 Jan 1970 00:00:00 GMT; samesite=None; partitioned;
      """

  Scenario: User creates a license with an invalid session
    Given the current account is "test1"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I authenticate with an invalid session
    When I send a GET request to "/accounts/test1/me"
    Then the response status should be "401"

  # origins
  Scenario: User reads their profile with a valid session (no origin)
    Given the current account is "test1"
    And I am an admin of account "test1"
    And I authenticate with a valid session
    And I send the following headers:
      """
      { "Origin": null }
      """
    When I send a GET request to "/accounts/test1/me"
    Then the response status should be "401"
    And the response headers should not contain "Set-Cookie"

  Scenario: User reads their profile with an invalid session (no origin)
    Given the current account is "test1"
    And I am an admin of account "test1"
    And I authenticate with an invalid session
    And I send the following headers:
      """
      { "Origin": null }
      """
    When I send a GET request to "/accounts/test1/me"
    Then the response status should be "401"
    And the response headers should not contain "Set-Cookie"

  Scenario: User reads their profile with a valid session (same-origin)
    Given the current account is "test1"
    And I am an admin of account "test1"
    And I authenticate with a valid session
    And I send the following headers:
      """
      { "Origin": "https://api.keygen.sh" }
      """
    When I send a GET request to "/accounts/test1/me"
    Then the response status should be "401"
    And the response headers should not contain "Set-Cookie"

  Scenario: User reads their profile with an invalid session (same-origin)
    Given the current account is "test1"
    And I am an admin of account "test1"
    And I authenticate with an invalid session
    And I send the following headers:
      """
      { "Origin": "https://api.keygen.sh" }
      """
    When I send a GET request to "/accounts/test1/me"
    Then the response status should be "401"
    And the response headers should not contain "Set-Cookie"

  Scenario: User reads their profile with a valid session (secure same-site portal)
    Given the current account is "test1"
    And I am an admin of account "test1"
    And I authenticate with a valid session
    And I send the following headers:
      """
      { "Origin": "https://portal.keygen.sh" }
      """
    When I send a GET request to "/accounts/test1/me"
    Then the response status should be "200"

  Scenario: User reads their profile with an invalid session (secure same-site portal)
    Given the current account is "test1"
    And I am an admin of account "test1"
    And I authenticate with an invalid session
    And I send the following headers:
      """
      { "Origin": "https://portal.keygen.sh" }
      """
    When I send a GET request to "/accounts/test1/me"
    Then the response status should be "401"
    And the response headers should contain "Set-Cookie" with a cookie:
      """
      session_id=; domain=keygen.sh; expires=Thu, 01 Jan 1970 00:00:00 GMT; samesite=None; partitioned;
      """

  Scenario: User reads their profile with a valid session (insecure same-site portal)
    Given the current account is "test1"
    And I am an admin of account "test1"
    And I authenticate with a valid session
    And I send the following headers:
      """
      { "Origin": "http://portal.keygen.sh" }
      """
    When I send a GET request to "/accounts/test1/me"
    Then the response status should be "401"
    And the response headers should not contain "Set-Cookie"

  Scenario: User reads their profile with an invalid session (insecure same-site portal)
    Given the current account is "test1"
    And I am an admin of account "test1"
    And I authenticate with an invalid session
    And I send the following headers:
      """
      { "Origin": "http://portal.keygen.sh" }
      """
    When I send a GET request to "/accounts/test1/me"
    Then the response status should be "401"
    And the response headers should not contain "Set-Cookie"

  Scenario: User reads their profile with a valid session (blocked same-site status)
    Given the current account is "test1"
    And I am an admin of account "test1"
    And I authenticate with a valid session
    And I send the following headers:
      """
      { "Origin": "https://status.keygen.sh" }
      """
    When I send a GET request to "/accounts/test1/me"
    Then the response status should be "401"
    And the response headers should not contain "Set-Cookie"

  Scenario: User reads their profile with an invalid session (blocked same-site status)
    Given the current account is "test1"
    And I am an admin of account "test1"
    And I authenticate with an invalid session
    And I send the following headers:
      """
      { "Origin": "https://status.keygen.sh" }
      """
    When I send a GET request to "/accounts/test1/me"
    Then the response status should be "401"
    And the response headers should not contain "Set-Cookie"

  Scenario: User reads their profile with a valid session (blocked same-site app)
    Given the current account is "test1"
    And I am an admin of account "test1"
    And I authenticate with a valid session
    And I send the following headers:
      """
      { "Origin": "https://app.keygen.sh" }
      """
    When I send a GET request to "/accounts/test1/me"
    Then the response status should be "401"
    And the response headers should not contain "Set-Cookie"

  Scenario: User reads their profile with an invalid session (blocked same-site app)
    Given the current account is "test1"
    And I am an admin of account "test1"
    And I authenticate with an invalid session
    And I send the following headers:
      """
      { "Origin": "https://app.keygen.sh" }
      """
    When I send a GET request to "/accounts/test1/me"
    Then the response status should be "401"
    And the response headers should not contain "Set-Cookie"

  Scenario: User reads their profile with a valid session (eltd+1)
    Given the current account is "test1"
    And I am an admin of account "test1"
    And I authenticate with a valid session
    And I send the following headers:
      """
      { "Origin": "https://keygen.sh" }
      """
    When I send a GET request to "/accounts/test1/me"
    Then the response status should be "401"
    And the response headers should not contain "Set-Cookie"

  Scenario: User reads their profile with an invalid session (eltd+1)
    Given the current account is "test1"
    And I am an admin of account "test1"
    And I authenticate with an invalid session
    And I send the following headers:
      """
      { "Origin": "https://keygen.sh" }
      """
    When I send a GET request to "/accounts/test1/me"
    Then the response status should be "401"
    And the response headers should not contain "Set-Cookie"

  Scenario: User reads their profile with a valid session (cross-origin)
    Given the current account is "test1"
    And I am an admin of account "test1"
    And I authenticate with a valid session
    And I send the following headers:
      """
      { "Origin": "https://evil.example" }
      """
    When I send a GET request to "/accounts/test1/me"
    Then the response status should be "401"
    And the response headers should not contain "Set-Cookie"

  Scenario: User reads their profile with an invalid session (cross-origin)
    Given the current account is "test1"
    And I am an admin of account "test1"
    And I authenticate with an invalid session
    And I send the following headers:
      """
      { "Origin": "https://evil.example" }
      """
    When I send a GET request to "/accounts/test1/me"
    Then the response status should be "401"
    And the response headers should not contain "Set-Cookie"

  Scenario: User reads their profile with a valid session (cross-origin suffix bypass)
    Given the current account is "test1"
    And I am an admin of account "test1"
    And I authenticate with a valid session
    And I send the following headers:
      """
      { "Origin": "https://evil-keygen.sh" }
      """
    When I send a GET request to "/accounts/test1/me"
    Then the response status should be "401"
    And the response headers should not contain "Set-Cookie"

  Scenario: User reads their profile with an invalid session (cross-origin suffix bypass)
    Given the current account is "test1"
    And I am an admin of account "test1"
    And I authenticate with an invalid session
    And I send the following headers:
      """
      { "Origin": "https://evil-keygen.sh" }
      """
    When I send a GET request to "/accounts/test1/me"
    Then the response status should be "401"
    And the response headers should not contain "Set-Cookie"

  # envs
  @ee
  Scenario: License validates itself with session authentication (isolated license in isolated env)
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And the current account has 1 isolated "policy" with the following:
      """
      { "authenticationStrategy": "SESSION" }
      """
    And the current account has 1 isolated "license" for the last "policy"
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

  @ee
  Scenario: License validates itself with session authentication (shared license in shared env)
    Given the current account is "test1"
    And the current account has 1 shared "environment"
    And the current account has 1 shared "policy" with the following:
      """
      { "authenticationStrategy": "SESSION" }
      """
    And the current account has 1 shared "license" for the last "policy"
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

  @ee
  Scenario: License validates itself with session authentication (global license in isolated env)
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And the current account has 1 global "policy" with the following:
      """
      { "authenticationStrategy": "SESSION" }
      """
    And the current account has 1 global "license" for the last "policy"
    And I am a license of account "test1"
    And I authenticate with a session
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    When I send a POST request to "/accounts/test1/licenses/$0/actions/validate"
    Then the response status should be "401"
    And the response headers should contain "Set-Cookie" with a cookie:
      """
      session_id=; domain=keygen.sh; expires=Thu, 01 Jan 1970 00:00:00 GMT; samesite=None; partitioned;
      """
    And the response headers should contain the following:
      """
      { "Keygen-Environment": "isolated" }
      """

  @ee
  Scenario: License validates itself with session authentication (global license in shared env)
    Given the current account is "test1"
    And the current account has 1 shared "environment"
    And the current account has 1 global "policy" with the following:
      """
      { "authenticationStrategy": "SESSION" }
      """
    And the current account has 1 global "license" for the last "policy"
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

  @ee
  Scenario: License validates itself with session authentication (shared license in global env)
    Given the current account is "test1"
    And the current account has 1 shared "environment"
    And the current account has 1 shared "policy" with the following:
      """
      { "authenticationStrategy": "SESSION" }
      """
    And the current account has 1 shared "license" for the last "policy"
    And I am a license of account "test1"
    And I authenticate with a session
    When I send a POST request to "/accounts/test1/licenses/$0/actions/validate"
    Then the response status should be "401"
    And the response headers should contain "Set-Cookie" with a cookie:
      """
      session_id=; domain=keygen.sh; expires=Thu, 01 Jan 1970 00:00:00 GMT; samesite=None; partitioned;
      """

  @ee
  Scenario: License validates itself with session authentication (isolated license in shared env)
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And the current account has 1 shared "environment"
    And the current account has 1 isolated "policy" with the following:
      """
      { "authenticationStrategy": "SESSION" }
      """
    And the current account has 1 isolated "license" for the last "policy"
    And I am a license of account "test1"
    And I authenticate with a session
    And I send the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
    When I send a POST request to "/accounts/test1/licenses/$0/actions/validate"
    Then the response status should be "401"
    And the response headers should contain "Set-Cookie" with a cookie:
      """
      session_id=; domain=keygen.sh; expires=Thu, 01 Jan 1970 00:00:00 GMT; samesite=None; partitioned;
      """
    And the response headers should contain the following:
      """
      { "Keygen-Environment": "shared" }
      """

  @ee
  Scenario: License validates itself with session authentication (isolated license in global env)
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And the current account has 1 isolated "policy" with the following:
      """
      { "authenticationStrategy": "SESSION" }
      """
    And the current account has 1 isolated "license" for the last "policy"
    And I am a license of account "test1"
    And I authenticate with a session
    When I send a POST request to "/accounts/test1/licenses/$0/actions/validate"
    Then the response status should be "401"
    And the response headers should contain "Set-Cookie" with a cookie:
      """
      session_id=; domain=keygen.sh; expires=Thu, 01 Jan 1970 00:00:00 GMT; samesite=None; partitioned;
      """

  # create
  Scenario: User creates a trial license with session authentication
    Given the current account is "test1"
    And the current account has 1 "policy" with the following:
      """
      { "name": "Trial", "protected": false }
      """
    And the current account has 1 "user"
    And time is frozen at "2552-03-10T00:00:00.000Z"
    And I am a user of account "test1"
    And I authenticate with a session
    And I send the following headers:
      """
      { "User-Agent": "acme/1.1" }
      """
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
    And the first "session" should have the following attributes:
      """
      {
        "bearerType": "User",
        "bearerId": "$users[1]",
        "tokenId": "$tokens[0]",
        "lastUsedAt": "2552-03-10T00:00:00.000Z",
        "userAgent": "acme/1.1",
        "ip": "127.0.0.1"
      }
      """
    And time is unfrozen

  Scenario: User creates a pro license with session authentication
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

  Scenario: User creates a license with session authentication
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
  Scenario: User validates their license key with session authentication
    Given the current account is "test1"
    And the current account has 1 "user"
    And the current account has 1 "license" for the last "user" as "owner"
    And I am an user of account "test1"
    And I authenticate with a session
    When I send a POST request to "/accounts/test1/licenses/$0/actions/validate"
    Then the response status should be "200"
    And the response headers should not contain "Set-Cookie"
    And the response body should be a "license"

  Scenario: User validates a license key with session authentication
    Given the current account is "test1"
    And the current account has 1 "user"
    And the current account has 1 "license"
    And I am a user of account "test1"
    And I authenticate with a session
    When I send a POST request to "/accounts/test1/licenses/$0/actions/validate"
    And the response headers should not contain "Set-Cookie"
    Then the response status should be "404"

  Scenario: User validates a license key with session authentication (banned)
    Given the current account is "test1"
    And the current account has 1 banned "user"
    And the current account has 1 "license"
    And I am a user of account "test1"
    And I authenticate with a session
    When I send a POST request to "/accounts/test1/licenses/$0/actions/validate"
    And the response headers should contain "Set-Cookie" with a cookie:
      """
      session_id=; domain=keygen.sh; expires=Thu, 01 Jan 1970 00:00:00 GMT; samesite=None; partitioned;
      """
    Then the response status should be "403"

  Scenario: License validates their key with session authentication (session auth strategy)
    Given the current account is "test1"
    And the current account has 1 "policy" with the following:
      """
      { "authenticationStrategy": "SESSION" }
      """
    And the current account has 1 "license" for the last "policy"
    And I am a license of account "test1"
    And I authenticate with a session
    When I send a POST request to "/accounts/test1/licenses/$0/actions/validate"
    Then the response status should be "200"
    And the response headers should not contain "Set-Cookie"
    And the response body should be a "license"

  Scenario: License validates their key with session authentication (token auth strategy)
    Given the current account is "test1"
    And the current account has 1 "policy" with the following:
      """
      { "authenticationStrategy": "TOKEN" }
      """
    And the current account has 1 "license" for the last "policy"
    And I am a license of account "test1"
    And I authenticate with a session
    When I send a POST request to "/accounts/test1/licenses/$0/actions/validate"
    Then the response status should be "403"
    And the response headers should contain "Set-Cookie" with a cookie:
      """
      session_id=; domain=keygen.sh; expires=Thu, 01 Jan 1970 00:00:00 GMT; samesite=None; partitioned;
      """
    And the first error should have the following properties:
      """
      {
        "title": "Access denied",
        "detail": "Session authentication is not allowed by policy",
        "code": "SESSION_NOT_ALLOWED"
      }
      """

  Scenario: License validates their key with session authentication (license auth strategy)
    Given the current account is "test1"
    And the current account has 1 "policy" with the following:
      """
      { "authenticationStrategy": "LICENSE" }
      """
    And the current account has 1 "license" for the last "policy"
    And I am a license of account "test1"
    And I authenticate with a session
    When I send a POST request to "/accounts/test1/licenses/$0/actions/validate"
    Then the response status should be "403"
    And the response headers should contain "Set-Cookie" with a cookie:
      """
      session_id=; domain=keygen.sh; expires=Thu, 01 Jan 1970 00:00:00 GMT; samesite=None; partitioned;
      """
    And the first error should have the following properties:
      """
      {
        "title": "Access denied",
        "detail": "Session authentication is not allowed by policy",
        "code": "SESSION_NOT_ALLOWED"
      }
      """

  Scenario: License validates a key with session authentication (mixed auth strategy)
    Given the current account is "test1"
    And the current account has 1 "policy" with the following:
      """
      { "authenticationStrategy": "MIXED" }
      """
    And the current account has 1 "license" for the last "policy"
    And I am a license of account "test1"
    And I authenticate with a session
    When I send a POST request to "/accounts/test1/licenses/$0/actions/validate"
    Then the response status should be "200"
    And the response headers should not contain "Set-Cookie"
    And the response body should be a "license"

  Scenario: License validates their key with session authentication (none auth strategy)
    Given the current account is "test1"
    And the current account has 1 "policy" with the following:
      """
      { "authenticationStrategy": "NONE" }
      """
    And the current account has 1 "license" for the last "policy"
    And I am a license of account "test1"
    And I authenticate with a session
    When I send a POST request to "/accounts/test1/licenses/$0/actions/validate"
    Then the response status should be "403"
    And the response headers should contain "Set-Cookie" with a cookie:
      """
      session_id=; domain=keygen.sh; expires=Thu, 01 Jan 1970 00:00:00 GMT; samesite=None; partitioned;
      """
    And the first error should have the following properties:
      """
      {
        "title": "Access denied",
        "detail": "Session authentication is not allowed by policy",
        "code": "SESSION_NOT_ALLOWED"
      }
      """

  Scenario: License validates their key with session authentication (banned)
    Given the current account is "test1"
    And the current account has 1 banned "user"
    And the current account has 1 "license" for the last "user" as "owner"
    And I am a license of account "test1"
    And I authenticate with a session
    When I send a POST request to "/accounts/test1/licenses/$0/actions/validate"
    And the response headers should contain "Set-Cookie" with a cookie:
      """
      session_id=; domain=keygen.sh; expires=Thu, 01 Jan 1970 00:00:00 GMT; samesite=None; partitioned;
      """
    Then the response status should be "403"

  # update
  Scenario: Product updates their license with session authentication
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

  Scenario: Product updates a license with session authentication
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
  Scenario: Product deletes their license with session authentication
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "license" for the last "policy"
    And I am a product of account "test1"
    And I authenticate with a session
    When I send a DELETE request to "/accounts/test1/licenses/$0"
    Then the response status should be "204"

  Scenario: Product deletes a license with session authentication
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "license"
    And I am a product of account "test1"
    And I authenticate with a session
    When I send a DELETE request to "/accounts/test1/licenses/$0"
    Then the response status should be "404"
