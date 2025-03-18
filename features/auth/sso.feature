@ee
Feature: SSO
  Background:
    Given the following "accounts" exist:
      | name             | slug          | sso_organization_id                   | sso_organization_domains | sso_session_duration | sso_jit_provisioning | sso_external_authn |
      | Keygen           | keygen-sh     |                                       |                          |                      |                      |                    |
      | Example          | example-com   |                                       |                          |                      |                      |                    |
      | Evil Corp        | ecorp-example | test_org_59f4ac10f7b6acbf3304f3fc2211 | ecorp.example            | 43200                | false                | true               |
      | Lumon Industries | lumon-example | test_org_669aa06c521982d5c12b3eb74bf0 | lumon.example            |                      | true                 | false              |

  Scenario: We receive a successful callback for an existing admin
    Given time is frozen at "2552-02-28T00:00:00.000Z"
    And the first "admin" of account "ecorp-example" has the following attributes:
      """
      { "email": "elliot@ecorp.example" }
      """
    And the SSO callback code "test_123" returns the following profile:
      """
      {
        "id": "test_prof_61bbd8f6eedbaff8b040d1c98ba9",
        "organization_id": "test_org_59f4ac10f7b6acbf3304f3fc2211",
        "connection_id": "test_conn_565647f76ab997ed8a62444451c6",
        "idp_id": "test_idp_332389f4fb8a9e823cb8308a2179",
        "email": "elliot@ecorp.example",
        "first_name": "Elliot",
        "last_name": "Alderson",
        "role": {
          "slug": "admin"
        }
      }
      """
    And I use user agent "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:136.0) Gecko/20100101 Firefox/136.0"
    When I send a GET request to "//auth.keygen.sh/sso?code=test_123"
    Then the response status should be "303"
    And the response headers should contain "Location" with "https://portal.keygen.sh/ecorp-example"
    And the response headers should contain "Set-Cookie" with an encrypted cookie:
      """
      session_id=$sessions[0]; domain=keygen.sh; path=/; expires=Mon, 28 Feb 2552 12:00:00 GMT; secure; httponly; samesite=None; partitioned;
      """
    And the account "ecorp-example" should have 1 "admin"
    And the last "admin" of account "ecorp-example" should have the following attributes:
      """
      {
        "sso_profile_id": "test_prof_61bbd8f6eedbaff8b040d1c98ba9",
        "sso_connection_id": "test_conn_565647f76ab997ed8a62444451c6",
        "sso_idp_id": "test_idp_332389f4fb8a9e823cb8308a2179",
        "email": "elliot@ecorp.example",
        "first_name": "Elliot",
        "last_name": "Alderson"
      }
      """
    And the account "ecorp-example" should have 1 "session"
    And the last "session" of account "ecorp-example" should have the following attributes:
      """
      {
        "bearer_type": "User",
        "bearer_id": "$users[0]",
        "token_id": null,
        "user_agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:136.0) Gecko/20100101 Firefox/136.0",
        "ip": "127.0.0.1",
        "last_used_at": null
      }
      """
    And time is unfrozen

  Scenario: We receive a successful callback for an existing user (unchanged role)
    Given time is frozen at "2552-02-28T00:00:00.000Z"
    And the account "ecorp-example" has 1 "user" with the following:
      """
      { "email": "elliot@ecorp.example" }
      """
    And the SSO callback code "test_123" returns the following profile:
      """
      {
        "id": "test_prof_61bbd8f6eedbaff8b040d1c98ba9",
        "organization_id": "test_org_59f4ac10f7b6acbf3304f3fc2211",
        "connection_id": "test_conn_565647f76ab997ed8a62444451c6",
        "idp_id": "test_idp_332389f4fb8a9e823cb8308a2179",
        "email": "elliot@ecorp.example",
        "first_name": "Elliot",
        "last_name": "Alderson",
        "role": {
          "slug": "user"
        }
      }
      """
    And I use user agent "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:136.0) Gecko/20100101 Firefox/136.0"
    When I send a GET request to "//auth.keygen.sh/sso?code=test_123"
    Then the response status should be "303"
    And the response headers should contain "Location" with "https://portal.keygen.sh/ecorp-example"
    And the response headers should contain "Set-Cookie" with an encrypted cookie:
      """
      session_id=$sessions[0]; domain=keygen.sh; path=/; expires=Mon, 28 Feb 2552 12:00:00 GMT; secure; httponly; samesite=None; partitioned;
      """
    And the account "ecorp-example" should have 1 "admin"
    And the account "ecorp-example" should have 1 "user"
    And the last "user" of account "ecorp-example" should have the following attributes:
      """
      {
        "sso_profile_id": "test_prof_61bbd8f6eedbaff8b040d1c98ba9",
        "sso_connection_id": "test_conn_565647f76ab997ed8a62444451c6",
        "sso_idp_id": "test_idp_332389f4fb8a9e823cb8308a2179",
        "email": "elliot@ecorp.example",
        "first_name": "Elliot",
        "last_name": "Alderson"
      }
      """
    And the account "ecorp-example" should have 1 "session"
    And the last "session" of account "ecorp-example" should have the following attributes:
      """
      {
        "bearer_type": "User",
        "bearer_id": "$users[1]",
        "token_id": null,
        "user_agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:136.0) Gecko/20100101 Firefox/136.0",
        "ip": "127.0.0.1",
        "last_used_at": null
      }
      """
    And time is unfrozen

  Scenario: We receive a successful callback for an existing user (changed role)
    Given time is frozen at "2552-02-28T00:00:00.000Z"
    And the account "ecorp-example" has 1 "user" with the following:
      """
      { "email": "elliot@ecorp.example" }
      """
    And the SSO callback code "test_123" returns the following profile:
      """
      {
        "id": "test_prof_61bbd8f6eedbaff8b040d1c98ba9",
        "organization_id": "test_org_59f4ac10f7b6acbf3304f3fc2211",
        "connection_id": "test_conn_565647f76ab997ed8a62444451c6",
        "idp_id": "test_idp_332389f4fb8a9e823cb8308a2179",
        "email": "elliot@ecorp.example",
        "first_name": "Elliot",
        "last_name": "Alderson",
        "role": {
          "slug": "developer"
        }
      }
      """
    And I use user agent "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:136.0) Gecko/20100101 Firefox/136.0"
    When I send a GET request to "//auth.keygen.sh/sso?code=test_123"
    Then the response status should be "303"
    And the response headers should contain "Location" with "https://portal.keygen.sh/ecorp-example"
    And the response headers should contain "Set-Cookie" with an encrypted cookie:
      """
      session_id=$sessions[0]; domain=keygen.sh; path=/; expires=Mon, 28 Feb 2552 12:00:00 GMT; secure; httponly; samesite=None; partitioned;
      """
    And the account "ecorp-example" should have 1 "admin"
    And the account "ecorp-example" should have 1 "developer" admin
    And the account "ecorp-example" should have 0 "users"
    And the last "developer" admin of account "ecorp-example" should have the following attributes:
      """
      {
        "sso_profile_id": "test_prof_61bbd8f6eedbaff8b040d1c98ba9",
        "sso_connection_id": "test_conn_565647f76ab997ed8a62444451c6",
        "sso_idp_id": "test_idp_332389f4fb8a9e823cb8308a2179",
        "email": "elliot@ecorp.example",
        "first_name": "Elliot",
        "last_name": "Alderson"
      }
      """
    And the account "ecorp-example" should have 1 "session"
    And the last "session" of account "ecorp-example" should have the following attributes:
      """
      {
        "bearer_type": "User",
        "bearer_id": "$users[1]",
        "token_id": null,
        "user_agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:136.0) Gecko/20100101 Firefox/136.0",
        "ip": "127.0.0.1",
        "last_used_at": null
      }
      """
    And time is unfrozen

  Scenario: We receive a successful callback for an existing user (invalid role)
    Given time is frozen at "2552-02-28T00:00:00.000Z"
    And the account "ecorp-example" has 1 "user" with the following:
      """
      { "email": "elliot@ecorp.example" }
      """
    And the SSO callback code "test_123" returns the following profile:
      """
      {
        "id": "test_prof_61bbd8f6eedbaff8b040d1c98ba9",
        "organization_id": "test_org_59f4ac10f7b6acbf3304f3fc2211",
        "connection_id": "test_conn_565647f76ab997ed8a62444451c6",
        "idp_id": "test_idp_332389f4fb8a9e823cb8308a2179",
        "email": "elliot@ecorp.example",
        "first_name": "Elliot",
        "last_name": "Alderson",
        "role": {
          "slug": "invalid"
        }
      }
      """
    And I use user agent "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:136.0) Gecko/20100101 Firefox/136.0"
    When I send a GET request to "//auth.keygen.sh/sso?code=test_123"
    Then the response status should be "303"
    And the response headers should contain "Location" with "https://portal.keygen.sh/sso/error?code=SSO_USER_INVALID"
    And the response headers should not contain "Set-Cookie"
    And the account "ecorp-example" should have 1 "admin"
    And the account "ecorp-example" should have 1 "user"
    And the account "ecorp-example" should have 0 "sessions"
    And time is unfrozen

  Scenario: We receive a successful callback for a new user (jit-provisioning enabled, with role)
    Given time is frozen at "2552-02-28T00:00:00.000Z"
    And the SSO callback code "test_123" returns the following profile:
      """
      {
        "id": "test_prof_b2c45c1af54f9cad85edf6104091",
        "organization_id": "test_org_669aa06c521982d5c12b3eb74bf0",
        "connection_id": "test_conn_6ca55425d9b4842cdd3ba3f1ea9c",
        "idp_id": "test_idp_34d99d8985608b3d0297183a1265",
        "email": "mark@lumon.example",
        "first_name": "Mark",
        "last_name": "Scout",
        "role": {
          "slug": "read-only"
        }
      }
      """
    And I use user agent "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:136.0) Gecko/20100101 Firefox/136.0"
    When I send a GET request to "//auth.keygen.sh/sso?code=test_123"
    Then the response status should be "303"
    And the response headers should contain "Location" with "https://portal.keygen.sh/lumon-example"
    And the response headers should contain "Set-Cookie" with an encrypted cookie:
      """
      session_id=$sessions[0]; domain=keygen.sh; path=/; expires=Mon, 28 Feb 2552 08:00:00 GMT; secure; httponly; samesite=None; partitioned;
      """
    And the account "lumon-example" should have 1 "admin"
    And the account "lumon-example" should have 1 "read-only" admin
    And the last "read-only" admin of account "lumon-example" should have the following attributes:
      """
      {
        "sso_profile_id": "test_prof_b2c45c1af54f9cad85edf6104091",
        "sso_connection_id": "test_conn_6ca55425d9b4842cdd3ba3f1ea9c",
        "sso_idp_id": "test_idp_34d99d8985608b3d0297183a1265",
        "email": "mark@lumon.example",
        "first_name": "Mark",
        "last_name": "Scout"
      }
      """
    And the account "lumon-example" should have 1 "session"
    And the last "session" of account "lumon-example" should have the following attributes:
      """
      {
        "bearer_type": "User",
        "bearer_id": "$users[1]",
        "token_id": null,
        "user_agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:136.0) Gecko/20100101 Firefox/136.0",
        "ip": "127.0.0.1",
        "last_used_at": null
      }
      """
    And time is unfrozen

  Scenario: We receive a successful callback for a new user (jit-provisioning enabled, no role)
    Given time is frozen at "2552-02-28T00:00:00.000Z"
    And the SSO callback code "test_123" returns the following profile:
      """
      {
        "id": "test_prof_b2c45c1af54f9cad85edf6104091",
        "organization_id": "test_org_669aa06c521982d5c12b3eb74bf0",
        "connection_id": "test_conn_6ca55425d9b4842cdd3ba3f1ea9c",
        "idp_id": "test_idp_34d99d8985608b3d0297183a1265",
        "email": "mark@lumon.example",
        "first_name": "Mark",
        "last_name": "Scout",
        "role": null
      }
      """
    And I use user agent "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:136.0) Gecko/20100101 Firefox/136.0"
    When I send a GET request to "//auth.keygen.sh/sso?code=test_123"
    Then the response status should be "303"
    And the response headers should contain "Location" with "https://portal.keygen.sh/lumon-example"
    And the response headers should contain "Set-Cookie" with an encrypted cookie:
      """
      session_id=$sessions[0]; domain=keygen.sh; path=/; expires=Mon, 28 Feb 2552 08:00:00 GMT; secure; httponly; samesite=None; partitioned;
      """
    And the account "lumon-example" should have 1 "admin"
    And the account "lumon-example" should have 1 "user"
    And the last "user" of account "lumon-example" should have the following attributes:
      """
      {
        "sso_profile_id": "test_prof_b2c45c1af54f9cad85edf6104091",
        "sso_connection_id": "test_conn_6ca55425d9b4842cdd3ba3f1ea9c",
        "sso_idp_id": "test_idp_34d99d8985608b3d0297183a1265",
        "email": "mark@lumon.example",
        "first_name": "Mark",
        "last_name": "Scout"
      }
      """
    And the account "lumon-example" should have 1 "session"
    And the last "session" of account "lumon-example" should have the following attributes:
      """
      {
        "bearer_type": "User",
        "bearer_id": "$users[1]",
        "token_id": null,
        "user_agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:136.0) Gecko/20100101 Firefox/136.0",
        "ip": "127.0.0.1",
        "last_used_at": null
      }
      """
    And time is unfrozen

  Scenario: We receive a successful callback for a new user (jit-provisioning enabled, invalid role)
    Given time is frozen at "2552-02-28T00:00:00.000Z"
    And the SSO callback code "test_123" returns the following profile:
      """
      {
        "id": "test_prof_b2c45c1af54f9cad85edf6104091",
        "organization_id": "test_org_669aa06c521982d5c12b3eb74bf0",
        "connection_id": "test_conn_6ca55425d9b4842cdd3ba3f1ea9c",
        "idp_id": "test_idp_34d99d8985608b3d0297183a1265",
        "email": "mark@lumon.example",
        "first_name": "Mark",
        "last_name": "Scout",
        "role": {
          "slug": "invalid"
        }
      }
      """
    And I use user agent "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:136.0) Gecko/20100101 Firefox/136.0"
    When I send a GET request to "//auth.keygen.sh/sso?code=test_123"
    Then the response status should be "303"
    And the response headers should contain "Location" with "https://portal.keygen.sh/sso/error?code=SSO_USER_INVALID"
    And the response headers should not contain "Set-Cookie"
    And the account "lumon-example" should have 1 "admin"
    And the account "lumon-example" should have 0 "users"
    And the account "lumon-example" should have 0 "sessions"
    And time is unfrozen

  Scenario: We receive a successful callback for a new user (jit-provisioning disabled)
    Given time is frozen at "2552-02-28T00:00:00.000Z"
    And the SSO callback code "test_123" returns the following profile:
      """
      {
        "id": "test_prof_817ecc3d254abf20003c3b65de62",
        "organization_id": "test_org_59f4ac10f7b6acbf3304f3fc2211",
        "connection_id": "test_conn_4fe0dc9ef9fc9b97c9a61ffb2c53",
        "idp_id": "test_idp_e6da15dff602b7bb39e16e9a8f86",
        "email": "tyrell@ecorp.example",
        "first_name": "Tyrell",
        "last_name": "Wellick",
        "role": {
          "slug": "admin"
        }
      }
      """
    And I use user agent "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:136.0) Gecko/20100101 Firefox/136.0"
    When I send a GET request to "//auth.keygen.sh/sso?code=test_123"
    Then the response status should be "303"
    And the response headers should contain "Location" with "https://portal.keygen.sh/sso/error?code=SSO_USER_NOT_FOUND"
    And the response headers should not contain "Set-Cookie"
    And the account "ecorp-example" should have 1 "admin"
    And the account "ecorp-example" should have 0 "sessions"
    And time is unfrozen

  Scenario: We receive a successful callback for an external user (external auth enabled)
    Given time is frozen at "2552-02-28T00:00:00.000Z"
    And the account "ecorp-example" has 1 "user" with the following:
      """
      { "email": "mr@fsociety.example" }
      """
    And the SSO callback code "test_123" returns the following profile:
      """
      {
        "id": "test_prof_81f49904d5dab08b383227991dad",
        "organization_id": "test_org_59f4ac10f7b6acbf3304f3fc2211",
        "connection_id": "test_conn_350787fce355b6205b5e6a20e675",
        "idp_id": "test_idp_ee679133e84194c147486ec5cea9",
        "email": "mr@fsociety.example",
        "first_name": "Mr",
        "last_name": "Robot",
        "role": {
          "slug": "user"
        }
      }
      """
    And I use user agent "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:136.0) Gecko/20100101 Firefox/136.0"
    When I send a GET request to "//auth.keygen.sh/sso?code=test_123"
    Then the response status should be "303"
    And the response headers should contain "Location" with "https://portal.keygen.sh/ecorp-example"
    And the response headers should contain "Set-Cookie" with an encrypted cookie:
      """
      session_id=$sessions[0]; domain=keygen.sh; path=/; expires=Mon, 28 Feb 2552 12:00:00 GMT; secure; httponly; samesite=None; partitioned;
      """
    And the account "ecorp-example" should have 1 "admin"
    And the account "ecorp-example" should have 1 "user"
    And the last "user" of account "ecorp-example" should have the following attributes:
      """
      {
        "sso_profile_id": "test_prof_81f49904d5dab08b383227991dad",
        "sso_connection_id": "test_conn_350787fce355b6205b5e6a20e675",
        "sso_idp_id": "test_idp_ee679133e84194c147486ec5cea9",
        "email": "mr@fsociety.example",
        "first_name": "Mr",
        "last_name": "Robot"
      }
      """
    And the account "ecorp-example" should have 1 "session"
    And the last "session" of account "ecorp-example" should have the following attributes:
      """
      {
        "bearer_type": "User",
        "bearer_id": "$users[1]",
        "token_id": null,
        "user_agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:136.0) Gecko/20100101 Firefox/136.0",
        "ip": "127.0.0.1",
        "last_used_at": null
      }
      """
    And time is unfrozen

  Scenario: We receive a successful callback for an external user (external authn disabled)
    Given time is frozen at "2552-02-28T00:00:00.000Z"
    And the SSO callback code "test_123" returns the following profile:
      """
      {
        "id": "test_prof_b2c45c1af54f9cad85edf6104091",
        "organization_id": "test_org_669aa06c521982d5c12b3eb74bf0",
        "connection_id": "test_conn_6ca55425d9b4842cdd3ba3f1ea9c",
        "idp_id": "test_idp_34d99d8985608b3d0297183a1265",
        "email": "cobel@mail.example",
        "first_name": "Harmony",
        "last_name": "Cobel",
        "role": {
          "slug": "admin"
        }
      }
      """
    And I use user agent "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:136.0) Gecko/20100101 Firefox/136.0"
    When I send a GET request to "//auth.keygen.sh/sso?code=test_123"
    Then the response status should be "303"
    And the response headers should contain "Location" with "https://portal.keygen.sh/sso/error?code=SSO_USER_NOT_ALLOWED"
    And the response headers should not contain "Set-Cookie"
    And the account "lumon-example" should have 1 "admin"
    And the account "lumon-example" should have 0 "sessions"
    And time is unfrozen

  Scenario: We receive a callback for an unrecognized organization
    Given time is frozen at "2552-02-28T00:00:00.000Z"
    And the SSO callback code "test_123" returns the following profile:
      """
      {
        "id": "test_prof_aa6fb68cd146993adf8d0bebe192",
        "organization_id": "test_org_7dcd28cc7c6e8924a43d61b9072f",
        "connection_id": "test_conn_490e20b5ef728d5da105c7491ad4",
        "idp_id": "test_idp_c1e45c0f15378390824adc56accb",
        "email": "john@example.com",
        "first_name": "John",
        "last_name": "Doe",
        "role": {
          "slug": "admin"
        }
      }
      """
    And I use user agent "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:136.0) Gecko/20100101 Firefox/136.0"
    When I send a GET request to "//auth.keygen.sh/sso?code=test_123"
    Then the response status should be "303"
    And the response headers should contain "Location" with "https://portal.keygen.sh/sso/error?code=SSO_ACCOUNT_NOT_FOUND"
    And the response headers should not contain "Set-Cookie"
    And there should be 0 "sessions"
    And time is unfrozen

  Scenario: We receive a callback with an invalid callback code
    Given time is frozen at "2552-02-28T00:00:00.000Z"
    And the SSO callback code "test_123" returns an "access_denied" error
    And I use user agent "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:136.0) Gecko/20100101 Firefox/136.0"
    When I send a GET request to "//auth.keygen.sh/sso?code=test_123"
    Then the response status should be "303"
    And the response headers should contain "Location" with "https://portal.keygen.sh/sso/error?code=SSO_ACCESS_DENIED"
    And the response headers should not contain "Set-Cookie"
    And there should be 0 "sessions"
    And time is unfrozen

  Scenario: We receive a failed callback
    Given time is frozen at "2552-02-28T00:00:00.000Z"
    And I use user agent "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:136.0) Gecko/20100101 Firefox/136.0"
    When I send a GET request to "//auth.keygen.sh/sso?error=connection_invalid"
    Then the response status should be "303"
    And the response headers should contain "Location" with "https://portal.keygen.sh/sso/error?code=SSO_CONNECTION_INVALID"
    And the response headers should not contain "Set-Cookie"
    And there should be 0 "sessions"
    And time is unfrozen
