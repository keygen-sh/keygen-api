@api/v1
Feature: License policy relationship

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
    When I send a GET request to "/accounts/test1/licenses/$0/policy"
    Then the response status should be "403"

  Scenario: Admin retrieves the policy for a license
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 3 "licenses"
    And the first "license" has the following attributes:
      """
      { "key": "test-key" }
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/test-key/policy"
    Then the response status should be "200"
    And the response body should be a "policy"
    And the response should contain a valid signature header for "test1"

  @ee
  Scenario: Environment retrieves the policy of an isolated license
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And the current account has 1 isolated "license"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    When I send a GET request to "/accounts/test1/licenses/$0/policy"
    Then the response status should be "200"
    And the response body should be a "policy"

  Scenario: Product retrieves the policy for a license
    Given the current account is "test1"
    And the current account has 3 "licenses"
    And the current account has 1 "product"
    And I am a product of account "test1"
    And the current product has 3 "licenses"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0/policy"
    Then the response status should be "200"
    And the response body should be a "policy"

  Scenario: Product retrieves the policy for a license of another product
    Given the current account is "test1"
    And the current account has 3 "products"
    And the current account has 1 "policy"
    And all "policies" have the following attributes:
      """
      { "productId": "$products[3]" }
      """
    And the current account has 1 "webhook-endpoint"
    And the current account has 3 "licenses"
    And all "licenses" have the following attributes:
      """
      { "policyId": "$policies[0]" }
      """
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0/policy"
    Then the response status should be "404"

  Scenario: User attempts to retrieve the policy for a license they own
    Given the current account is "test1"
    And the current account has 3 "licenses"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And the current user has 1 "license" as "owner"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0/policy"
    Then the response status should be "403"

  Scenario: User attempts to retrieve the policy for a license they have
    Given the current account is "test1"
    And the current account has 1 "license"
    And the current account has 1 "user"
    And the current account has 1 "license-user" for the last "license" and the last "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0/policy"
    Then the response status should be "403"

  Scenario: Admin attempts to retrieve the policy for a license of another account
    Given I am an admin of account "test2"
    And the current account is "test1"
    And the current account has 3 "licenses"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/licenses/$0/policy"
    Then the response status should be "401"

  Scenario: Admin changes a license's policy relationship to a new policy
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "product"
    And the current account has 3 "policies" for the first "product"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "license" for the first "policy"
    And I use an authentication token
    When I send a PUT request to "/accounts/test1/licenses/$0/policy" with the following:
      """
      {
        "data": {
          "type": "policies",
          "id": "$policies[1]"
        }
      }
      """
    Then the response status should be "200"
    And the response body should be a "license" with the following relationships:
      """
      {
        "policy": {
          "links": { "related": "/v1/accounts/$account/licenses/$licenses[0]/policy" },
          "data": { "type": "policies", "id": "$policies[1]" }
        }
      }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin changes a license's policy relationship to a non-existent policy
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "product"
    And the current account has 3 "policies" for the first "product"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "license" for the first "policy"
    And I use an authentication token
    When I send a PUT request to "/accounts/test1/licenses/$0/policy" with the following:
      """
      {
        "data": {
          "type": "policies",
          "id": "$users[0]"
        }
      }
      """
    Then the response status should be "422"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin changes a license's policy relationship to a new policy that belongs to another product
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "products"
    And the current account has 1 "policy" for the first "product"
    And the current account has 1 "policy" for the second "product"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "license" for the first "policy"
    And I use an authentication token
    When I send a PUT request to "/accounts/test1/licenses/$0/policy" with the following:
      """
      {
        "data": {
          "type": "policies",
          "id": "$policies[1]"
        }
      }
      """
    Then the response status should be "200"
    And the response body should be a "license" with the following relationships:
      """
      {
        "policy": {
          "links": { "related": "/v1/accounts/$account/licenses/$licenses[0]/policy" },
          "data": { "type": "policies", "id": "$policies[1]" }
        }
      }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin changes a encrypted license's policy relationship to a new unencrypted policy
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "product"
    And the current account has 2 "policies" for the first "product"
    And the first "policy" has the following attributes:
      """
      { "encrypted": true }
      """
    And the second "policy" has the following attributes:
      """
      { "encrypted": false }
      """
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "license" for the first "policy"
    And I use an authentication token
    When I send a PUT request to "/accounts/test1/licenses/$0/policy" with the following:
      """
      {
        "data": {
          "type": "policies",
          "id": "$policies[1]"
        }
      }
      """
    Then the response status should be "422"
    And the first error should have the following properties:
      """
      {
        "title": "Unprocessable resource",
        "detail": "cannot change from an encrypted policy to an unencrypted policy (or vice-versa)",
        "code": "POLICY_NOT_COMPATIBLE",
        "source": {
          "pointer": "/data/relationships/policy"
        }
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin changes an unencrypted license's policy relationship to a new encrypted policy
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "product"
    And the current account has 2 "policies" for the first "product"
    And the first "policy" has the following attributes:
      """
      { "encrypted": false }
      """
    And the second "policy" has the following attributes:
      """
      { "encrypted": true }
      """
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "license" for the first "policy"
    And I use an authentication token
    When I send a PUT request to "/accounts/test1/licenses/$0/policy" with the following:
      """
      {
        "data": {
          "type": "policies",
          "id": "$policies[1]"
        }
      }
      """
    Then the response status should be "422"
    And the first error should have the following properties:
      """
      {
        "title": "Unprocessable resource",
        "detail": "cannot change from an encrypted policy to an unencrypted policy (or vice-versa)",
        "code": "POLICY_NOT_COMPATIBLE",
        "source": {
          "pointer": "/data/relationships/policy"
        }
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin changes a license's policy relationship to a new policy with a different scheme
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "product"
    And the current account has 2 "policies" for the first "product"
    And the first "policy" has the following attributes:
      """
      { "scheme": "RSA_2048_JWT_RS256" }
      """
    And the second "policy" has the following attributes:
      """
      { "scheme": "RSA_2048_PKCS1_ENCRYPT" }
      """
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "license" for the first "policy"
    And I use an authentication token
    When I send a PUT request to "/accounts/test1/licenses/$0/policy" with the following:
      """
      {
        "data": {
          "type": "policies",
          "id": "$policies[1]"
        }
      }
      """
    Then the response status should be "422"
    And the first error should have the following properties:
      """
      {
        "title": "Unprocessable resource",
        "detail": "cannot change to a policy with a different scheme",
        "code": "POLICY_NOT_COMPATIBLE",
        "source": {
          "pointer": "/data/relationships/policy"
        }
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin changes a pooled license's policy relationship to a new unpooled policy
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "product"
    And the current account has 2 "policies" for the first "product"
    And the first "policy" has the following attributes:
      """
      { "usePool": true }
      """
    And the second "policy" has the following attributes:
      """
      { "usePool": false }
      """
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "key" for the first "policy"
    And the current account has 1 "license" for the first "policy"
    And I use an authentication token
    When I send a PUT request to "/accounts/test1/licenses/$0/policy" with the following:
      """
      {
        "data": {
          "type": "policies",
          "id": "$policies[1]"
        }
      }
      """
    Then the response status should be "422"
    And the first error should have the following properties:
      """
      {
        "title": "Unprocessable resource",
        "detail": "cannot change from a pooled policy to an unpooled policy (or vice-versa)",
        "code": "POLICY_NOT_COMPATIBLE",
        "source": {
          "pointer": "/data/relationships/policy"
        }
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin changes an unpooled license's policy relationship to a new pooled policy
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "product"
    And the current account has 2 "policies" for the first "product"
    And the first "policy" has the following attributes:
      """
      { "usePool": false }
      """
    And the second "policy" has the following attributes:
      """
      { "usePool": true }
      """
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "license" for the first "policy"
    And I use an authentication token
    When I send a PUT request to "/accounts/test1/licenses/$0/policy" with the following:
      """
      {
        "data": {
          "type": "policies",
          "id": "$policies[1]"
        }
      }
      """
    Then the response status should be "422"
    And the first error should have the following properties:
      """
      {
        "title": "Unprocessable resource",
        "detail": "cannot change from a pooled policy to an unpooled policy (or vice-versa)",
        "code": "POLICY_NOT_COMPATIBLE",
        "source": {
          "pointer": "/data/relationships/policy"
        }
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin changes a license's policy relationship to a new policy for another account
    Given I am an admin of account "test1"
    And the current account is "test2"
    And the current account has 1 "product"
    And the current account has 3 "policies" for the first "product"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "license" for the first "policy"
    And I use an authentication token
    When I send a PUT request to "/accounts/test2/licenses/$0/policy" with the following:
      """
      {
        "data": {
          "type": "policies",
          "id": "$policies[1]"
        }
      }
      """
    Then the response status should be "401"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin changes a license's policy relationship to a policy with a more strict machine uniqueness strategy
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "product"
    And the current account has 2 "policies" for the first "product"
    And the first "policy" has the following attributes:
      """
      { "machineUniquenessStrategy": "UNIQUE_PER_LICENSE" }
      """
    And the second "policy" has the following attributes:
      """
      { "machineUniquenessStrategy": "UNIQUE_PER_PRODUCT" }
      """
    And the current account has 1 "webhook-endpoint"
    And the current account has 2 "licenses" for the first "policy"
    And the current account has 2 "machines"
    And the first "machine" has the following attributes:
      """
      {
        "fingerprint": "mN:8M:uK:WL:Dx:8z:Vb:9A:ut:zD:FA:xL:fv:zt:ZE",
        "licenseId": "$licenses[0]"
      }
      """
    And the second "machine" has the following attributes:
      """
      {
        "fingerprint": "mN:8M:uK:WL:Dx:8z:Vb:9A:ut:zD:FA:xL:fv:zt:ZE",
        "licenseId": "$licenses[1]"
      }
      """
    And I use an authentication token
    When I send a PUT request to "/accounts/test1/licenses/$0/policy" with the following:
      """
      {
        "data": {
          "type": "policies",
          "id": "$policies[1]"
        }
      }
      """
    Then the response status should be "422"
    And the first error should have the following properties:
      """
      {
        "title": "Unprocessable resource",
        "detail": "cannot change to a policy with a more strict machine uniqueness strategy",
        "code": "POLICY_NOT_COMPATIBLE",
        "source": {
          "pointer": "/data/relationships/policy"
        }
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin changes a license's policy relationship to a policy with a less strict machine uniqueness strategy
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "product"
    And the current account has 2 "policies" for the first "product"
    And the first "policy" has the following attributes:
      """
      { "machineUniquenessStrategy": "UNIQUE_PER_POLICY" }
      """
    And the second "policy" has the following attributes:
      """
      { "machineUniquenessStrategy": "UNIQUE_PER_LICENSE" }
      """
    And the current account has 1 "webhook-endpoint"
    And the current account has 2 "licenses" for the first "policy"
    And the current account has 2 "machines"
    And the first "machine" has the following attributes:
      """
      {
        "fingerprint": "mN:8M:uK:WL:Dx:8z:Vb:9A:ut:zD:FA:xL:fv:zt:ZE",
        "licenseId": "$licenses[0]"
      }
      """
    And the second "machine" has the following attributes:
      """
      {
        "fingerprint": "mN:8M:uK:WL:Dx:8z:Vb:9A:ut:zD:FA:xL:fv:zt:ZE",
        "licenseId": "$licenses[1]"
      }
      """
    And I use an authentication token
    When I send a PUT request to "/accounts/test1/licenses/$0/policy" with the following:
      """
      {
        "data": {
          "type": "policies",
          "id": "$policies[1]"
        }
      }
      """
    Then the response status should be "200"
    And the response body should be a "license" with the following relationships:
      """
      {
        "policy": {
          "links": { "related": "/v1/accounts/$account/licenses/$licenses[0]/policy" },
          "data": { "type": "policies", "id": "$policies[1]" }
        }
      }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin changes a license's policy relationship to a policy with a more strict component uniqueness strategy
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "product"
    And the current account has 2 "policies" for the first "product"
    And the first "policy" has the following attributes:
      """
      { "componentUniquenessStrategy": "UNIQUE_PER_MACHINE" }
      """
    And the second "policy" has the following attributes:
      """
      { "componentUniquenessStrategy": "UNIQUE_PER_LICENSE" }
      """
    And the current account has 1 "webhook-endpoint"
    And the current account has 2 "licenses" for the first "policy"
    And the current account has 2 "machines"
    And the first "machine" has the following attributes:
      """
      {
        "fingerprint": "mN:8M:uK:WL:Dx:8z:Vb:9A:ut:zD:FA:xL:fv:zt:ZE",
        "licenseId": "$licenses[0]"
      }
      """
    And the second "machine" has the following attributes:
      """
      {
        "fingerprint": "mN:8M:uK:WL:Dx:8z:Vb:9A:ut:zD:FA:xL:fv:zt:ZE",
        "licenseId": "$licenses[1]"
      }
      """
    And I use an authentication token
    When I send a PUT request to "/accounts/test1/licenses/$0/policy" with the following:
      """
      {
        "data": {
          "type": "policies",
          "id": "$policies[1]"
        }
      }
      """
    Then the response status should be "422"
    And the first error should have the following properties:
      """
      {
        "title": "Unprocessable resource",
        "detail": "cannot change to a policy with a more strict component uniqueness strategy",
        "code": "POLICY_NOT_COMPATIBLE",
        "source": {
          "pointer": "/data/relationships/policy"
        }
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin changes a license's policy relationship to a policy with a less strict component uniqueness strategy
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "product"
    And the current account has 2 "policies" for the first "product"
    And the first "policy" has the following attributes:
      """
      { "componentUniquenessStrategy": "UNIQUE_PER_LICENSE" }
      """
    And the second "policy" has the following attributes:
      """
      { "componentUniquenessStrategy": "UNIQUE_PER_MACHINE" }
      """
    And the current account has 1 "webhook-endpoint"
    And the current account has 2 "licenses" for the first "policy"
    And the current account has 2 "machines"
    And the first "machine" has the following attributes:
      """
      {
        "fingerprint": "mN:8M:uK:WL:Dx:8z:Vb:9A:ut:zD:FA:xL:fv:zt:ZE",
        "licenseId": "$licenses[0]"
      }
      """
    And the second "machine" has the following attributes:
      """
      {
        "fingerprint": "mN:8M:uK:WL:Dx:8z:Vb:9A:ut:zD:FA:xL:fv:zt:ZE",
        "licenseId": "$licenses[1]"
      }
      """
    And I use an authentication token
    When I send a PUT request to "/accounts/test1/licenses/$0/policy" with the following:
      """
      {
        "data": {
          "type": "policies",
          "id": "$policies[1]"
        }
      }
      """
    Then the response status should be "200"
    And the response body should be a "license" with the following relationships:
      """
      {
        "policy": {
          "links": { "related": "/v1/accounts/$account/licenses/$licenses[0]/policy" },
          "data": { "type": "policies", "id": "$policies[1]" }
        }
      }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin transfers a license to a new policy with a default transfer strategy
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "product"
    And the current account has 2 "policies" for the first "product"
    And the second "policy" has the following attributes:
      """
      { "duration": "$time.1.year" }
      """
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "license" for the first "policy"
    And the first "license" has the following attributes:
      """
      { "expiry": "2042-02-21T17:09:26.685Z" }
      """
    And I use an authentication token
    When I send a PUT request to "/accounts/test1/licenses/$0/policy" with the following:
      """
      {
        "data": {
          "type": "policies",
          "id": "$policies[1]"
        }
      }
      """
    Then the response status should be "200"
    And the response body should be a "license" with the expiry "2042-02-21T17:09:26.685Z"
    And the response body should be a "license" with the following relationships:
      """
      {
        "policy": {
          "links": { "related": "/v1/accounts/$account/licenses/$licenses[0]/policy" },
          "data": { "type": "policies", "id": "$policies[1]" }
        }
      }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin transfers a license to a new policy with a KEEP_EXPIRY transfer strategy (has duration)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "product"
    And the current account has 2 "policies" for the first "product"
    And the second "policy" has the following attributes:
      """
      {
        "transferStrategy": "KEEP_EXPIRY",
        "duration": "$time.1.year"
      }
      """
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "license" for the first "policy"
    And the first "license" has the following attributes:
      """
      { "expiry": "2042-02-21T17:09:26.685Z" }
      """
    And I use an authentication token
    When I send a PUT request to "/accounts/test1/licenses/$0/policy" with the following:
      """
      {
        "data": {
          "type": "policies",
          "id": "$policies[1]"
        }
      }
      """
    Then the response status should be "200"
    And the response body should be a "license" with the expiry "2042-02-21T17:09:26.685Z"
    And the response body should be a "license" with the following relationships:
      """
      {
        "policy": {
          "links": { "related": "/v1/accounts/$account/licenses/$licenses[0]/policy" },
          "data": { "type": "policies", "id": "$policies[1]" }
        }
      }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin transfers a license to a new policy with a KEEP_EXPIRY transfer strategy (no duration)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "product"
    And the current account has 2 "policies" for the first "product"
    And the second "policy" has the following attributes:
      """
      {
        "transferStrategy": "KEEP_EXPIRY",
        "duration": null
      }
      """
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "license" for the first "policy"
    And the first "license" has the following attributes:
      """
      { "expiry": "2042-02-21T17:09:26.685Z" }
      """
    And I use an authentication token
    When I send a PUT request to "/accounts/test1/licenses/$0/policy" with the following:
      """
      {
        "data": {
          "type": "policies",
          "id": "$policies[1]"
        }
      }
      """
    Then the response status should be "200"
    And the response body should be a "license" with the expiry "2042-02-21T17:09:26.685Z"
    And the response body should be a "license" with the following relationships:
      """
      {
        "policy": {
          "links": { "related": "/v1/accounts/$account/licenses/$licenses[0]/policy" },
          "data": { "type": "policies", "id": "$policies[1]" }
        }
      }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin transfers a license to a new policy with a RESET_EXPIRY transfer strategy (has duration)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "product"
    And the current account has 2 "policies" for the first "product"
    And the second "policy" has the following attributes:
      """
      {
        "transferStrategy": "RESET_EXPIRY",
        "duration": "$time.1.year"
      }
      """
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "license" for the first "policy"
    And the first "license" has the following attributes:
      """
      { "expiry": "2042-02-21T17:09:26.685Z" }
      """
    And I use an authentication token
    When I send a PUT request to "/accounts/test1/licenses/$0/policy" with the following:
      """
      {
        "data": {
          "type": "policies",
          "id": "$policies[1]"
        }
      }
      """
    Then the response status should be "200"
    And the response body should be a "license" with an expiry within seconds of "$time.1.year.from_now"
    And the response body should be a "license" with the following relationships:
      """
      {
        "policy": {
          "links": { "related": "/v1/accounts/$account/licenses/$licenses[0]/policy" },
          "data": { "type": "policies", "id": "$policies[1]" }
        }
      }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin transfers a license to a new policy with a RESET_EXPIRY transfer strategy (no duration)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "product"
    And the current account has 2 "policies" for the first "product"
    And the second "policy" has the following attributes:
      """
      {
        "transferStrategy": "RESET_EXPIRY",
        "duration": null
      }
      """
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "license" for the first "policy"
    And the first "license" has the following attributes:
      """
      { "expiry": "2042-02-21T17:09:26.685Z" }
      """
    And I use an authentication token
    When I send a PUT request to "/accounts/test1/licenses/$0/policy" with the following:
      """
      {
        "data": {
          "type": "policies",
          "id": "$policies[1]"
        }
      }
      """
    Then the response status should be "200"
    And the response body should be a "license" with a nil expiry
    And the response body should be a "license" with the following relationships:
      """
      {
        "policy": {
          "links": { "related": "/v1/accounts/$account/licenses/$licenses[0]/policy" },
          "data": { "type": "policies", "id": "$policies[1]" }
        }
      }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Product changes a license's policy relationship to a new policy
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And the current account has 3 "policies" for the first "product"
    And the current account has 1 "license" for the first "policy"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a PUT request to "/accounts/test1/licenses/$0/policy" with the following:
      """
      {
        "data": {
          "type": "policies",
          "id": "$policies[1]"
        }
      }
      """
    Then the response status should be "200"
    And the response body should be a "license" with the following relationships:
      """
      {
        "policy": {
          "links": { "related": "/v1/accounts/$account/licenses/$licenses[0]/policy" },
          "data": { "type": "policies", "id": "$policies[1]" }
        }
      }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Product changes a license's policy relationship to a new policy they don't own
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 2 "products"
    And the current account has 1 "policy" for the first "product"
    And the current account has 1 "policy" for the second "product"
    And the current account has 1 "license" for the first "policy"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a PUT request to "/accounts/test1/licenses/$0/policy" with the following:
      """
      {
        "data": {
          "type": "policies",
          "id": "$policies[1]"
        }
      }
      """
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Product changes a license's policy relationship to a new policy for a license they don't own
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 2 "products"
    And the current account has 1 "policy" for the first "product"
    And the current account has 1 "policy" for the second "product"
    And the current account has 1 "license" for the second "policy"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a PUT request to "/accounts/test1/licenses/$0/policy" with the following:
      """
      {
        "data": {
          "type": "policies",
          "id": "$policies[0]"
        }
      }
      """
    Then the response status should be "404"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: User changes a license's policy relationship from an unprotected policy to an unprotected policy (license owner)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And the current account has 3 "policies" for the first "product"
    And all "policies" have the following attributes:
      """
      { "protected": false }
      """
    And the current account has 1 "license" for the first "policy"
    And the first "license" has the following attributes:
      """
      { "expiry": "$time.1.day.from_now" }
      """
    And the current account has 1 "user"
    And I am a user of account "test1"
    And the current user has 1 "license" as "owner"
    And I use an authentication token
    When I send a PUT request to "/accounts/test1/licenses/$0/policy" with the following:
      """
      {
        "data": {
          "type": "policies",
          "id": "$policies[1]"
        }
      }
      """
    Then the response status should be "200"
    And the response body should be a "license" with the following relationships:
      """
      {
        "policy": {
          "links": { "related": "/v1/accounts/$account/licenses/$licenses[0]/policy" },
          "data": { "type": "policies", "id": "$policies[1]" }
        }
      }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: User changes a license's policy relationship from an unprotected policy to an unprotected policy (license user)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And the current account has 3 "policies" for the first "product"
    And all "policies" have the following attributes:
      """
      { "protected": false }
      """
    And the current account has 1 "license" for the first "policy"
    And the first "license" has the following attributes:
      """
      { "expiry": "$time.1.day.from_now" }
      """
    And the current account has 1 "user"
    And the current account has 1 "license-user" for the last "license" and the last "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a PUT request to "/accounts/test1/licenses/$0/policy" with the following:
      """
      {
        "data": {
          "type": "policies",
          "id": "$policies[1]"
        }
      }
      """
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: User changes a license's policy relationship from a protected policy to a protected policy
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And the current account has 3 "policies" for the first "product"
    And all "policies" have the following attributes:
      """
      { "protected": true }
      """
    And the current account has 1 "license" for the first "policy"
    And the first "license" has the following attributes:
      """
      { "expiry": "$time.1.day.from_now" }
      """
    And the current account has 1 "user"
    And I am a user of account "test1"
    And the current user has 1 "license" as "owner"
    And I use an authentication token
    When I send a PUT request to "/accounts/test1/licenses/$0/policy" with the following:
      """
      {
        "data": {
          "type": "policies",
          "id": "$policies[1]"
        }
      }
      """
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: User changes an unprotected license's policy relationship from an unprotected policy to a protected policy
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And the current account has 2 "policies" for the first "product"
    And the first "policy" has the following attributes:
      """
      { "protected": false }
      """
    And the second "policy" has the following attributes:
      """
      { "protected": true }
      """
    And the current account has 1 "license" for the first "policy"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And the current user has 1 "license" as "owner"
    And I use an authentication token
    When I send a PUT request to "/accounts/test1/licenses/$0/policy" with the following:
      """
      {
        "data": {
          "type": "policies",
          "id": "$policies[1]"
        }
      }
      """
    Then the response status should be "403"
    And the first "license" should have the following attributes:
      """
      { "policyId": "$policies[0]" }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: User changes a protected license's policy relationship from a protected policy to an unprotected policy
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And the current account has 2 "policies" for the first "product"
    And the first "policy" has the following attributes:
      """
      { "protected": true }
      """
    And the second "policy" has the following attributes:
      """
      { "protected": false }
      """
    And the current account has 1 "license" for the first "policy"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And the current user has 1 "license" as "owner"
    And I use an authentication token
    When I send a PUT request to "/accounts/test1/licenses/$0/policy" with the following:
      """
      {
        "data": {
          "type": "policies",
          "id": "$policies[1]"
        }
      }
      """
    Then the response status should be "403"
    And the first "license" should have the following attributes:
      """
      { "policyId": "$policies[0]" }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: User changes an unprotected license's policy relationship to a non-existent policy
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And the current account has 1 "policy" for the first "product"
    And the first "policy" has the following attributes:
      """
      { "protected": false }
      """
    And the current account has 1 "license" for the first "policy"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And the current user has 1 "license" as "owner"
    And I use an authentication token
    When I send a PUT request to "/accounts/test1/licenses/$0/policy" with the following:
      """
      {
        "data": {
          "type": "policies",
          "id": "5e9527ce-a9ba-4f0f-a881-980129f4d36c"
        }
      }
      """
    Then the response status should be "422"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: User changes a license's policy relationship to a new policy for a license they don't own
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And the current account has 3 "policies" for the first "product"
    And the current account has 2 "users"
    And the current account has 1 "license" for the first "policy"
    And all "licenses" have the following attributes:
      """
      { "userId": "$users[2]" }
      """
    And I am a user of account "test1"
    And I use an authentication token
    When I send a PUT request to "/accounts/test1/licenses/$0/policy" with the following:
      """
      {
        "data": {
          "type": "policies",
          "id": "$policies[1]"
        }
      }
      """
    Then the response status should be "404"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: User transfers a license to a protected policy with a RESET_EXPIRY transfer strategy
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 2 "policies" for the first "product"
    And the first "policy" has the following attributes:
      """
      { "protected": false }
      """
    And the second "policy" has the following attributes:
      """
      {
        "transferStrategy": "RESET_EXPIRY",
        "duration": "$time.1.year",
        "protected": true
      }
      """
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "user"
    And the current account has 1 "license" for the first "policy"
    And the first "license" has the following attributes:
      """
      {
        "expiry": "2042-02-21T17:09:26.685Z",
        "userId": "$users[1]"
      }
      """
    And I am a user of account "test1"
    And I use an authentication token
    When I send a PUT request to "/accounts/test1/licenses/$0/policy" with the following:
      """
      {
        "data": {
          "type": "policies",
          "id": "$policies[1]"
        }
      }
      """
    Then the response status should be "403"
    And the first "license" should have the following attributes:
      """
      {
        "expiry": "2042-02-21T17:09:26.685Z",
        "policyId": "$policies[0]"
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Anonymous changes a license's policy relationship to a new policy
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And the current account has 3 "policies" for the first "product"
    And the current account has 1 "license" for the first "policy"
    When I send a PUT request to "/accounts/test1/licenses/$0/policy" with the following:
      """
      {
        "data": {
          "type": "policies",
          "id": "$policies[1]"
        }
      }
      """
    Then the response status should be "401"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job
