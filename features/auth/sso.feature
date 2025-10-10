@ee
Feature: SSO
  Background:
    Given the following "accounts" exist:
      | name             | slug          | sso_organization_id                   | sso_organization_domains | sso_session_duration | sso_jit_provisioning | sso_external_authn | sso_sync_roles | secret_key                       |
      | Keygen           | keygen-sh     |                                       |                          |                      |                      |                    |                | 04cd269a781e207653eb2ff3e9ab0be5 |
      | Example          | example-com   |                                       |                          |                      |                      |                    |                | a1f091cf41085e9436708a79090e37a6 |
      | Evil Corp        | ecorp-example | test_org_59f4ac10f7b6acbf3304f3fc2211 | ecorp.example            | 43200                | false                | true               | true           | a9be6bf4b17f353d002758ad33a0e0a4 |
      | Lumon Industries | lumon-example | test_org_669aa06c521982d5c12b3eb74bf0 | lumon.example            |                      | true                 | false              | false          | 98a2f3ad35a80561ce2b2c2d93d7e7e4 |

  Scenario: We receive a successful callback for an existing admin
    Given the first "admin" of account "ecorp-example" has the following attributes:
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
    And time is frozen at "2552-02-28T00:00:00.000Z"
    When I send a GET request to "//auth.keygen.sh/sso?code=test_123&state=SXl6am0fF0jxPO8VuBphPMbE8wy18p4PD8hSrW0S1GO--e-FVmMYxA9v0hXfSUIR9ZbVQgp4.DsAMB2uZeC41x0d2.okZe2vuFMPoxKUwixFo_cg"
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

  Scenario: We receive a successful callback for an existing admin (isolated environment, isolated admin)
    Given the account "ecorp-example" has 1 isolated "environment" with the following attributes:
      """
      { "id": "cb2cab2f-aec0-4102-a1ca-8abc674d6adc", "code": "isolated" }
      """
    And the account "ecorp-example" has 1 isolated "admin"
    And the last "admin" of account "ecorp-example" has the following attributes:
      """
      { "email": "elliot+isolated@ecorp.example" }
      """
    And the SSO callback code "test_123" returns the following profile:
      """
      {
        "id": "test_prof_61bbd8f6eedbaff8b040d1c98ba9",
        "organization_id": "test_org_59f4ac10f7b6acbf3304f3fc2211",
        "connection_id": "test_conn_565647f76ab997ed8a62444451c6",
        "idp_id": "test_idp_332389f4fb8a9e823cb8308a2179",
        "email": "elliot+isolated@ecorp.example",
        "first_name": "Elliot",
        "last_name": "Alderson",
        "role": {
          "slug": "admin"
        }
      }
      """
    And I use user agent "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:136.0) Gecko/20100101 Firefox/136.0"
    And time is frozen at "2552-02-28T00:00:00.000Z"
    When I send a GET request to "//auth.keygen.sh/sso?code=test_123&state=KifUWHVVV-N0OtbDeBGekJL3_k4OpBgr5ppN-8lDtOFqVFvNvYOIF_gG3AfoCq0GkzuuEpZEI0Jt-VVO-0eTOyAppqFATvnCfZCEwBg-gVLOyRT7e3qtfKzgm_e2LwLbKg.GgCfJOBuViu-jgV2.9m8thHfui7B70drku0qVEA"
    Then the response status should be "303"
    And the response headers should contain "Location" with "https://portal.keygen.sh/ecorp-example?env=isolated"
    And the response headers should contain "Set-Cookie" with an encrypted cookie:
      """
      session_id=$sessions[0]; domain=keygen.sh; path=/; expires=Mon, 28 Feb 2552 12:00:00 GMT; secure; httponly; samesite=None; partitioned;
      """
    And the account "ecorp-example" should have 2 "admins"
    And the last "admin" of account "ecorp-example" should have the following attributes:
      """
      {
        "environment_id": "cb2cab2f-aec0-4102-a1ca-8abc674d6adc",
        "sso_profile_id": "test_prof_61bbd8f6eedbaff8b040d1c98ba9",
        "sso_connection_id": "test_conn_565647f76ab997ed8a62444451c6",
        "sso_idp_id": "test_idp_332389f4fb8a9e823cb8308a2179",
        "email": "elliot+isolated@ecorp.example",
        "first_name": "Elliot",
        "last_name": "Alderson"
      }
      """
    And the account "ecorp-example" should have 1 "session"
    And the last "session" of account "ecorp-example" should have the following attributes:
      """
      {
        "environment_id": "cb2cab2f-aec0-4102-a1ca-8abc674d6adc",
        "bearer_type": "User",
        "bearer_id": "$users[1]",
        "token_id": null,
        "user_agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:136.0) Gecko/20100101 Firefox/136.0",
        "ip": "127.0.0.1",
        "last_used_at": null
      }
      """
    And time is unfrozen

  Scenario: We receive a successful callback for an existing admin (isolated environment, global admin)
    Given the account "ecorp-example" has 1 isolated "environment" with the following attributes:
      """
      { "id": "cb2cab2f-aec0-4102-a1ca-8abc674d6adc", "code": "isolated" }
      """
    And the last "admin" of account "ecorp-example" has the following attributes:
      """
      { "email": "elliot+global@ecorp.example" }
      """
    And the SSO callback code "test_123" returns the following profile:
      """
      {
        "id": "test_prof_61bbd8f6eedbaff8b040d1c98ba9",
        "organization_id": "test_org_59f4ac10f7b6acbf3304f3fc2211",
        "connection_id": "test_conn_565647f76ab997ed8a62444451c6",
        "idp_id": "test_idp_332389f4fb8a9e823cb8308a2179",
        "email": "elliot+global@ecorp.example",
        "first_name": "Elliot",
        "last_name": "Alderson",
        "role": {
          "slug": "admin"
        }
      }
      """
    And I use user agent "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:136.0) Gecko/20100101 Firefox/136.0"
    And time is frozen at "2552-02-28T00:00:00.000Z"
    When I send a GET request to "//auth.keygen.sh/sso?code=test_123&state=zkeKTgQw357Nek3z7aeFHDTSSIdfkSwA-7s9E6NYj5QEKJA_h0sNnKjaJ7GJDOep8R_VC_cy_H0RlP1UQavxpk7Z40Ap15xxWgcdVT5FWjR8cUlVH94bgg-MeLhejto.pHs06JgatU88k4Ud.xbT5-byycH4IraHGZsOJeA"
    Then the response status should be "303"
    And the response headers should contain "Location" with "https://portal.keygen.sh/ecorp-example?env=isolated"
    And the response headers should contain "Set-Cookie" with an encrypted cookie:
      """
      session_id=$sessions[0]; domain=keygen.sh; path=/; expires=Mon, 28 Feb 2552 12:00:00 GMT; secure; httponly; samesite=None; partitioned;
      """
    And the account "ecorp-example" should have 1 "admin"
    And the last "admin" of account "ecorp-example" should have the following attributes:
      """
      {
        "environment_id": null,
        "sso_profile_id": "test_prof_61bbd8f6eedbaff8b040d1c98ba9",
        "sso_connection_id": "test_conn_565647f76ab997ed8a62444451c6",
        "sso_idp_id": "test_idp_332389f4fb8a9e823cb8308a2179",
        "email": "elliot+global@ecorp.example",
        "first_name": "Elliot",
        "last_name": "Alderson"
      }
      """
    And the account "ecorp-example" should have 1 "session"
    And the last "session" of account "ecorp-example" should have the following attributes:
      """
      {
        "environment_id": "cb2cab2f-aec0-4102-a1ca-8abc674d6adc",
        "bearer_type": "User",
        "bearer_id": "$users[0]",
        "token_id": null,
        "user_agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:136.0) Gecko/20100101 Firefox/136.0",
        "ip": "127.0.0.1",
        "last_used_at": null
      }
      """
    And time is unfrozen

  Scenario: We receive a successful callback for an existing admin (shared environment, shared admin)
    Given the account "ecorp-example" has 1 shared "environment" with the following attributes:
      """
      { "id": "e0291f64-9eef-4da6-a187-87bd85c1e5cb", "code": "shared" }
      """
    And the account "ecorp-example" has 1 shared "admin"
    And the last "admin" of account "ecorp-example" has the following attributes:
      """
      { "email": "elliot+shared@ecorp.example" }
      """
    And the SSO callback code "test_123" returns the following profile:
      """
      {
        "id": "test_prof_61bbd8f6eedbaff8b040d1c98ba9",
        "organization_id": "test_org_59f4ac10f7b6acbf3304f3fc2211",
        "connection_id": "test_conn_565647f76ab997ed8a62444451c6",
        "idp_id": "test_idp_332389f4fb8a9e823cb8308a2179",
        "email": "elliot+shared@ecorp.example",
        "first_name": "Elliot",
        "last_name": "Alderson",
        "role": {
          "slug": "admin"
        }
      }
      """
    And I use user agent "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:136.0) Gecko/20100101 Firefox/136.0"
    And time is frozen at "2552-02-28T00:00:00.000Z"
    When I send a GET request to "//auth.keygen.sh/sso?code=test_123&state=Vn1Ac0DtQ1Px44fZYCCYPSnc3zZW3j_WUyW7KrA-xK3rtpcqmqL0bNUJ6MOZZ8soTjOWDAP49Yab7Yto6LlDLvu2K8TpJ9wFzh0AXJtDckFUKTFkFurupEf9Rn61Mgs.rsZwO6MRyhZ0XfJX.IY9nSOsC2JBpsLVhxgM2BQ"
    Then the response status should be "303"
    And the response headers should contain "Location" with "https://portal.keygen.sh/ecorp-example?env=shared"
    And the response headers should contain "Set-Cookie" with an encrypted cookie:
      """
      session_id=$sessions[0]; domain=keygen.sh; path=/; expires=Mon, 28 Feb 2552 12:00:00 GMT; secure; httponly; samesite=None; partitioned;
      """
    And the account "ecorp-example" should have 2 "admins"
    And the last "admin" of account "ecorp-example" should have the following attributes:
      """
      {
        "environment_id": "e0291f64-9eef-4da6-a187-87bd85c1e5cb",
        "sso_profile_id": "test_prof_61bbd8f6eedbaff8b040d1c98ba9",
        "sso_connection_id": "test_conn_565647f76ab997ed8a62444451c6",
        "sso_idp_id": "test_idp_332389f4fb8a9e823cb8308a2179",
        "email": "elliot+shared@ecorp.example",
        "first_name": "Elliot",
        "last_name": "Alderson"
      }
      """
    And the account "ecorp-example" should have 1 "session"
    And the last "session" of account "ecorp-example" should have the following attributes:
      """
      {
        "environment_id": "e0291f64-9eef-4da6-a187-87bd85c1e5cb",
        "bearer_type": "User",
        "bearer_id": "$users[1]",
        "token_id": null,
        "user_agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:136.0) Gecko/20100101 Firefox/136.0",
        "ip": "127.0.0.1",
        "last_used_at": null
      }
      """
    And time is unfrozen

  Scenario: We receive a successful callback for an existing admin (shared environment, global admin)
    Given the account "ecorp-example" has 1 shared "environment" with the following attributes:
      """
      { "id": "e0291f64-9eef-4da6-a187-87bd85c1e5cb", "code": "shared" }
      """
    And the first "admin" of account "ecorp-example" has the following attributes:
      """
      { "email": "elliot+global@ecorp.example" }
      """
    And the SSO callback code "test_123" returns the following profile:
      """
      {
        "id": "test_prof_61bbd8f6eedbaff8b040d1c98ba9",
        "organization_id": "test_org_59f4ac10f7b6acbf3304f3fc2211",
        "connection_id": "test_conn_565647f76ab997ed8a62444451c6",
        "idp_id": "test_idp_332389f4fb8a9e823cb8308a2179",
        "email": "elliot+global@ecorp.example",
        "first_name": "Elliot",
        "last_name": "Alderson",
        "role": {
          "slug": "admin"
        }
      }
      """
    And I use user agent "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:136.0) Gecko/20100101 Firefox/136.0"
    And time is frozen at "2552-02-28T00:00:00.000Z"
    When I send a GET request to "//auth.keygen.sh/sso?code=test_123&state=1ntzI6KOvv8HkYqMKe_qrFAYsnoTRHWqH64xj3MduUjcjOiPCwvQ3led2Lrsp6WAxOrfcygNrKs-hci4TLXfvl-CBYsnQnTvc_XDpr12MpohZf5SPomfkNogprZGl40.rUBdAXuf11a-qP8U.kmJiW_ngctZzpWfjIUcviQ"
    Then the response status should be "303"
    And the response headers should contain "Location" with "https://portal.keygen.sh/ecorp-example?env=shared"
    And the response headers should contain "Set-Cookie" with an encrypted cookie:
      """
      session_id=$sessions[0]; domain=keygen.sh; path=/; expires=Mon, 28 Feb 2552 12:00:00 GMT; secure; httponly; samesite=None; partitioned;
      """
    And the account "ecorp-example" should have 1 "admin"
    And the last "admin" of account "ecorp-example" should have the following attributes:
      """
      {
        "environment_id": null,
        "sso_profile_id": "test_prof_61bbd8f6eedbaff8b040d1c98ba9",
        "sso_connection_id": "test_conn_565647f76ab997ed8a62444451c6",
        "sso_idp_id": "test_idp_332389f4fb8a9e823cb8308a2179",
        "email": "elliot+global@ecorp.example",
        "first_name": "Elliot",
        "last_name": "Alderson"
      }
      """
    And the account "ecorp-example" should have 1 "session"
    And the last "session" of account "ecorp-example" should have the following attributes:
      """
      {
        "environment_id": "e0291f64-9eef-4da6-a187-87bd85c1e5cb",
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
    Given the account "ecorp-example" has 1 "user" with the following:
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
    And time is frozen at "2552-02-28T00:00:00.000Z"
    When I send a GET request to "//auth.keygen.sh/sso?code=test_123&state=sAPLaAyiQ1QJQaDiL6Vvsc2LO8swxOIdyivBaOvET6Lo8x-wackm9Zb1Lf6QOR2iOAftnFa9.Jl5bBJczTP2EqxNH.5aNfRHD9LHUYuSQ3UwKiLA"
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

  Scenario: We receive a successful callback for an existing user (changed role, role sync enabled)
    Given the account "ecorp-example" has 1 "user" with the following:
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
    And time is frozen at "2552-02-28T00:00:00.000Z"
    When I send a GET request to "//auth.keygen.sh/sso?code=test_123&state=SXl6am0fF0jxPO8VuBphPMbE8wy18p4PD8hSrW0S1GO--e-FVmMYxA9v0hXfSUIR9ZbVQgp4.DsAMB2uZeC41x0d2.okZe2vuFMPoxKUwixFo_cg"
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

  Scenario: We receive a successful callback for an existing user (changed role, role sync disabled)
    Given the account "lumon-example" has 1 "user" with the following:
      """
      { "email": "mark@lumon.example" }
      """
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
          "slug": "admin"
        }
      }
      """
    And I use user agent "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:136.0) Gecko/20100101 Firefox/136.0"
    And time is frozen at "2552-02-28T00:00:00.000Z"
    When I send a GET request to "//auth.keygen.sh/sso?code=test_123&state=TOqaPpXRH1plNlmQrU76PG35WvLupDqoJPpQX52M8LcYIUh1fIpvlj5kiM1wiyVpRWEAYA.LE-szECwEiE2sSqH.f9GClmuiFnrT7Xe81U_Rxw"
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

  Scenario: We receive a successful callback for an existing user (invalid role)
    Given the account "ecorp-example" has 1 "user" with the following:
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
    And time is frozen at "2552-02-28T00:00:00.000Z"
    When I send a GET request to "//auth.keygen.sh/sso?code=test_123&state=4MCmD2k6u8LMHBU2Skk7d3hlr9Oalx_6ANH8loibkdmhKLCSZRKoSXbZ7lRD5jQMAUIXxY8Z.9pJxc13QRyw9OMWF.rtnqi8Yvg1CbnkaLcJ1t8g"
    Then the response status should be "303"
    And the response headers should contain "Location" with "https://portal.keygen.sh/sso/error?code=SSO_USER_INVALID"
    And the response headers should not contain "Set-Cookie"
    And the account "ecorp-example" should have 1 "admin"
    And the account "ecorp-example" should have 1 "user"
    And the account "ecorp-example" should have 0 "sessions"
    And time is unfrozen

  Scenario: We receive a successful callback for a new user (jit-provisioning enabled, with role)
    Given the SSO callback code "test_123" returns the following profile:
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
    And time is frozen at "2552-02-28T00:00:00.000Z"
    When I send a GET request to "//auth.keygen.sh/sso?code=test_123&state=TOqaPpXRH1plNlmQrU76PG35WvLupDqoJPpQX52M8LcYIUh1fIpvlj5kiM1wiyVpRWEAYA.LE-szECwEiE2sSqH.f9GClmuiFnrT7Xe81U_Rxw"
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
    Given the SSO callback code "test_123" returns the following profile:
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
    And time is frozen at "2552-02-28T00:00:00.000Z"
    When I send a GET request to "//auth.keygen.sh/sso?code=test_123&state=y88jm-1LwjhPdcadnH7oij25_eA-8KpwrkC1Q8LOM9gKJYWoHgBcUEVhvMJWJ5Dh2B5jyw.8RODJ1BdAl-qqG-q.V-A0X2XETw5o45X-MNFpuQ"
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
    Given the SSO callback code "test_123" returns the following profile:
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
    And time is frozen at "2552-02-28T00:00:00.000Z"
    When I send a GET request to "//auth.keygen.sh/sso?code=test_123&state=YFPShi7mtJFpAOuPKr8WpgU5IX8pkfJ8r2WWN5pgFM56HBP-q0O_nv7yqDYa-F7uaByl0w.3qJmmzeON5s-zixB.9OdPVwymuMNyk8JhxLFw_w"
    Then the response status should be "303"
    And the response headers should contain "Location" with "https://portal.keygen.sh/sso/error?code=SSO_USER_INVALID"
    And the response headers should not contain "Set-Cookie"
    And the account "lumon-example" should have 1 "admin"
    And the account "lumon-example" should have 0 "users"
    And the account "lumon-example" should have 0 "sessions"
    And time is unfrozen

  Scenario: We receive a successful callback for a new user (jit-provisioning enabled, isolated environment)
    Given the account "lumon-example" has 1 isolated "environment" with the following attributes:
      """
      { "id": "cb2cab2f-aec0-4102-a1ca-8abc674d6adc", "code": "isolated" }
      """
    And the SSO callback code "test_123" returns the following profile:
      """
      {
        "id": "test_prof_b2c45c1af54f9cad85edf6104091",
        "organization_id": "test_org_669aa06c521982d5c12b3eb74bf0",
        "connection_id": "test_conn_6ca55425d9b4842cdd3ba3f1ea9c",
        "idp_id": "test_idp_34d99d8985608b3d0297183a1265",
        "email": "mark+isolated@lumon.example",
        "first_name": "Mark",
        "last_name": "Scout",
        "role": {
          "slug": "read-only"
        }
      }
      """
    And I use user agent "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:136.0) Gecko/20100101 Firefox/136.0"
    And time is frozen at "2552-02-28T00:00:00.000Z"
    When I send a GET request to "//auth.keygen.sh/sso?code=test_123&state=HKeA4LFaD37uh4cZ0pos3fGiTKqqgEWyX0GJIcWtfKLolOYS8X0i5BIMzTE4Qiu86NLJtR4QPx0yxE1-rVOBX6aYjIWyOWHlKmKAGtTciKrOc1NmLdjA5LKwcEmOFqA.J2SSUH2qDkWvcT4J.Z4Pi9plyQOR4ZdbdNmewcA"
    Then the response status should be "303"
    And the response headers should contain "Location" with "https://portal.keygen.sh/lumon-example?env=isolated"
    And the response headers should contain "Set-Cookie" with an encrypted cookie:
      """
      session_id=$sessions[0]; domain=keygen.sh; path=/; expires=Mon, 28 Feb 2552 08:00:00 GMT; secure; httponly; samesite=None; partitioned;
      """
    And the account "lumon-example" should have 1 "admin"
    And the account "lumon-example" should have 1 "read-only" admin
    And the last "read-only" admin of account "lumon-example" should have the following attributes:
      """
      {
        "environment_id": "cb2cab2f-aec0-4102-a1ca-8abc674d6adc",
        "sso_profile_id": "test_prof_b2c45c1af54f9cad85edf6104091",
        "sso_connection_id": "test_conn_6ca55425d9b4842cdd3ba3f1ea9c",
        "sso_idp_id": "test_idp_34d99d8985608b3d0297183a1265",
        "email": "mark+isolated@lumon.example",
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

  Scenario: We receive a successful callback for a new user (jit-provisioning disabled)
    Given the SSO callback code "test_123" returns the following profile:
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
    And time is frozen at "2552-02-28T00:00:00.000Z"
    When I send a GET request to "//auth.keygen.sh/sso?code=test_123&state=f2a2A21iPIhKarskLTfgOH1ZuJ1cTno4a44KrEGQiZq4yJfxmXNSufdhz_Pc5i0oklD2Dgel.RxFfY7ueVCNA1sda.vHfjD8tsRqXbGnrvG6KqyA"
    Then the response status should be "303"
    And the response headers should contain "Location" with "https://portal.keygen.sh/sso/error?code=SSO_USER_NOT_FOUND"
    And the response headers should not contain "Set-Cookie"
    And the account "ecorp-example" should have 1 "admin"
    And the account "ecorp-example" should have 0 "sessions"
    And time is unfrozen

  Scenario: We receive a successful callback for an external user (external auth enabled)
    Given the account "ecorp-example" has 1 "user" with the following:
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
    And time is frozen at "2552-02-28T00:00:00.000Z"
    When I send a GET request to "//auth.keygen.sh/sso?code=test_123&state=vvWeWnM9l-n-kJr7lbJN6gqGaqiczfOkZSqW-EH6wJw5FIlzV1v9oP_5jZ28CDKleupRDqM.z2Aa1UFQfmlFHWh2.CdrSOlSch6c3VGNrPepouA"
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
    Given the SSO callback code "test_123" returns the following profile:
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
    And time is frozen at "2552-02-28T00:00:00.000Z"
    When I send a GET request to "//auth.keygen.sh/sso?code=test_123&state=SrXkfd0s-X-ozWM6YBXJNQD8AcDApsMG5Vv1bdH4KpjP3135C1_8-EBppSW4WMA0g4H4WQ.S0QJYAKCnlo6L8BR.ofVtWcQLmYCBt9_9qDli4A"
    Then the response status should be "303"
    And the response headers should contain "Location" with "https://portal.keygen.sh/sso/error?code=SSO_USER_NOT_ALLOWED"
    And the response headers should not contain "Set-Cookie"
    And the account "lumon-example" should have 1 "admin"
    And the account "lumon-example" should have 0 "sessions"
    And time is unfrozen

  Scenario: We receive a callback for an unrecognized organization
    Given the SSO callback code "test_123" returns the following profile:
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
    And time is frozen at "2552-02-28T00:00:00.000Z"
    When I send a GET request to "//auth.keygen.sh/sso?code=test_123"
    Then the response status should be "303"
    And the response headers should contain "Location" with "https://portal.keygen.sh/sso/error?code=SSO_ACCOUNT_NOT_FOUND"
    And the response headers should not contain "Set-Cookie"
    And there should be 0 "sessions"
    And time is unfrozen

  Scenario: We receive a callback with unknown environment state
    Given time is frozen at "2552-02-28T00:00:00.000Z"
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
    When I send a GET request to "//auth.keygen.sh/sso?code=test_123&state=FHsInXgBpGQO2C4gBMkRuNlIJFszgqP-PIM4nUr1wcZHhahUQvLejzrmH5bUYfU3ZFJmtFjk2hi1t-O9ZzSWx0ODiVoJV2yc4LukRNjHDPcaLNrlcdDr.g1-jACKFjW6OXvcG.qHD8tyDNTuvthGteFzy2JA"
    Then the response status should be "303"
    And the response headers should contain "Location" with "https://portal.keygen.sh/sso/error?code=SSO_ENVIRONMENT_NOT_FOUND"
    And the response headers should not contain "Set-Cookie"
    And there should be 0 "sessions"
    And time is unfrozen

  Scenario: We receive a callback with tampered state
    Given the SSO callback code "test_123" returns the following profile:
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
    And time is frozen at "2552-02-28T00:00:00.000Z"
    When I send a GET request to "//auth.keygen.sh/sso?code=test_123&state=RVh-jwIExT9kq4vGiNqUvtjhOVnZ_0MDlO9Z-UWXbUxQ60Nv9BlZJL9DriU7QeG5AcOGwu9q.bpJ9av9o21oYo4br.LbvCyDxrgFLM9cLnb7STRA"
    Then the response status should be "303"
    And the response headers should contain "Location" with "https://portal.keygen.sh/sso/error?code=SSO_STATE_INVALID"
    And the response headers should not contain "Set-Cookie"
    And there should be 0 "sessions"
    And time is unfrozen

  Scenario: We receive a callback with expired state
    Given the SSO callback code "test_123" returns the following profile:
      """
      {
        "id": "test_prof_4feac6c06830a47bf740628c9038",
        "organization_id": "test_org_669aa06c521982d5c12b3eb74bf0",
        "connection_id": "test_conn_6ca55425d9b4842cdd3ba3f1ea9c",
        "idp_id": "test_idp_34d99d8985608b3d0297183a1265",
        "email": "milkshake@lumon.example",
        "first_name": "Seth",
        "last_name": "Milchick",
        "role": {
          "slug": "admin"
        }
      }
      """
    And I use user agent "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:136.0) Gecko/20100101 Firefox/136.0"
    And time is frozen at "2552-02-28T00:00:00.000Z"
    When I send a GET request to "//auth.keygen.sh/sso?code=test_123&state=vE_aR_Yo4LznQ030504ZNDartFen77pvvDX05d5PJIMtWKbwVBdqgSYIwJGRBdUYc1UR9EsXZOCc7x8J09gLLIcwzELAatnPmnY_HzacQMxM8Mtml081c7zQzw-gK2n81WYdGXzx7qizLwnvqhk.eHPuRpXNN3GIpegz.dGFivEgj7PTiuNvw72P_RA"
    Then the response status should be "303"
    And the response headers should contain "Location" with "https://portal.keygen.sh/sso/error?code=SSO_STATE_INVALID"
    And the response headers should not contain "Set-Cookie"
    And there should be 0 "sessions"
    And time is unfrozen

  Scenario: We receive a callback with invalid state
    Given the SSO callback code "test_123" returns the following profile:
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
    And time is frozen at "2552-02-28T00:00:00.000Z"
    When I send a GET request to "//auth.keygen.sh/sso?code=test_123&state=bad"
    Then the response status should be "303"
    And the response headers should contain "Location" with "https://portal.keygen.sh/sso/error?code=SSO_STATE_INVALID"
    And the response headers should not contain "Set-Cookie"
    And there should be 0 "sessions"
    And time is unfrozen

  Scenario: We receive a callback with missing state
    Given the SSO callback code "test_123" returns the following profile:
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
    And time is frozen at "2552-02-28T00:00:00.000Z"
    When I send a GET request to "//auth.keygen.sh/sso?code=test_123"
    Then the response status should be "303"
    And the response headers should contain "Location" with "https://portal.keygen.sh/sso/error?code=SSO_STATE_INVALID"
    And the response headers should not contain "Set-Cookie"
    And there should be 0 "sessions"
    And time is unfrozen

  Scenario: We receive a callback with an invalid callback code
    Given the SSO callback code "test_123" returns an "access_denied" error
    And I use user agent "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:136.0) Gecko/20100101 Firefox/136.0"
    And time is frozen at "2552-02-28T00:00:00.000Z"
    When I send a GET request to "//auth.keygen.sh/sso?code=test_123"
    Then the response status should be "303"
    And the response headers should contain "Location" with "https://portal.keygen.sh/sso/error?code=SSO_ACCESS_DENIED"
    And the response headers should not contain "Set-Cookie"
    And there should be 0 "sessions"
    And time is unfrozen

  Scenario: We receive a failed callback
    Given I use user agent "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:136.0) Gecko/20100101 Firefox/136.0"
    And time is frozen at "2552-02-28T00:00:00.000Z"
    When I send a GET request to "//auth.keygen.sh/sso?error=connection_invalid"
    Then the response status should be "303"
    And the response headers should contain "Location" with "https://portal.keygen.sh/sso/error?code=SSO_CONNECTION_INVALID"
    And the response headers should not contain "Set-Cookie"
    And there should be 0 "sessions"
    And time is unfrozen
