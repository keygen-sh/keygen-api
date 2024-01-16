@api/v1
Feature: Release entitlements relationship

  Background:
    Given the following "accounts" exist:
      | name    | slug  |
      | Test 1  | test1 |
      | Test 2  | test2 |
    And I send and accept JSON

  Scenario: Endpoint should be inaccessible when account is disabled
    Given the account "test1" is canceled
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "release"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$0/entitlements"
    Then the response status should be "403"

  Scenario: Admin retrieves the entitlements for a release
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "release"
    And the current account has 3 "release-entitlement-constraints" for existing "releases"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$0/entitlements"
    Then the response status should be "200"
    And the response body should be an array with 3 "entitlements"

  @ee
  Scenario: Product retrieves the entitlements for an isolated release
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And the current account has 1 isolated "release"
    And the current account has 3 isolated "release-entitlement-constraints" for each "release"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "keygen-environment": "isolated" }
      """
    When I send a GET request to "/accounts/test1/releases/$0/entitlements"
    Then the response status should be "200"
    And the response body should be an array with 3 "entitlements"

  Scenario: Product retrieves the entitlements for a release
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "release" for existing "products"
    And the current account has 3 "release-entitlement-constraints" for existing "releases"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$0/entitlements"
    Then the response status should be "200"
    And the response body should be an array with 3 "entitlements"

  Scenario: Admin retrieves an entitlement for a release
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "release"
    And the current account has 3 "release-entitlement-constraints" for existing "releases"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$0/entitlements/$0"
    Then the response status should be "200"
    And the response body should be a "entitlement"

  Scenario: Product retrieves an entitlement for a release
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "release" for existing "products"
    And the current account has 3 "release-entitlement-constraints" for existing "releases"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$0/entitlements/$0"
    Then the response status should be "200"
    And the response body should be a "entitlement"

  Scenario: Product retrieves the entitlements for a release of another product
    Given the current account is "test1"
    And the current account has 2 "products"
    And the current account has 1 "release" for the second "product"
    And the current account has 3 "release-entitlement-constraints" for existing "releases"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$0/entitlements"
    Then the response status should be "404"

  Scenario: License attempts to retrieve the entitlements for a release of a different product
    Given the current account is "test1"
    And the current account has 1 "release"
    And the current account has 3 "release-entitlement-constraints" for existing "releases"
    And the current account has 1 "license"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$0/entitlements"
    Then the response status should be "404"

  Scenario: License attempts to retrieve the entitlements for a release of their product
    Given the current account is "test1"
    And the current account has 3 "entitlements"
    And the current account has 1 "product"
    And the current account has 1 "release" for the last "product"
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "license" for the last "policy"
    And the current account has 1 "license-entitlement" with the following:
      """
      { "entitlementId": "$entitlements[0]", "licenseId": "$licenses[0]" }
      """
    And the current account has 1 "policy-entitlement" with the following:
      """
      { "entitlementId": "$entitlements[1]", "policyId": "$policies[0]" }
      """
    And the current account has 1 "policy-entitlement" with the following:
      """
      { "entitlementId": "$entitlements[2]", "policyId": "$policies[0]" }
      """
    And the current account has 1 "release-entitlement-constraint" with the following:
      """
      { "entitlementId": "$entitlements[0]", "releaseId": "$releases[0]" }
      """
    And the current account has 1 "release-entitlement-constraint" with the following:
      """
      { "entitlementId": "$entitlements[1]", "releaseId": "$releases[0]" }
      """
    And the current account has 1 "release-entitlement-constraint" with the following:
      """
      { "entitlementId": "$entitlements[2]", "releaseId": "$releases[0]" }
      """
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$0/entitlements"
    Then the response status should be "200"
    And the response body should be an array with 3 "entitlements"

  Scenario: User attempts to retrieve the entitlements for a release they don't have a license for
    Given the current account is "test1"
    And the current account has 1 "release"
    And the current account has 3 "release-entitlement-constraints" for existing "releases"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$0/entitlements"
    Then the response status should be "404"

  Scenario: User attempts to retrieve the entitlements for a release they do have a license for (license owner)
    Given the current account is "test1"
    And the current account has 3 "entitlements"
    And the current account has 1 "user"
    And the current account has 1 "product"
    And the current account has 1 "release" for the last "product"
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "license" for the last "policy"
    And the last "license" has the following attributes:
      """
      { "userId": "$users[1]" }
      """
    And the current account has 1 "license-entitlement" with the following:
      """
      { "entitlementId": "$entitlements[0]", "licenseId": "$licenses[0]" }
      """
    And the current account has 1 "policy-entitlement" with the following:
      """
      { "entitlementId": "$entitlements[1]", "policyId": "$policies[0]" }
      """
    And the current account has 1 "policy-entitlement" with the following:
      """
      { "entitlementId": "$entitlements[2]", "policyId": "$policies[0]" }
      """
    And the current account has 1 "release-entitlement-constraint" with the following:
      """
      { "entitlementId": "$entitlements[0]", "releaseId": "$releases[0]" }
      """
    And the current account has 1 "release-entitlement-constraint" with the following:
      """
      { "entitlementId": "$entitlements[1]", "releaseId": "$releases[0]" }
      """
    And the current account has 1 "release-entitlement-constraint" with the following:
      """
      { "entitlementId": "$entitlements[2]", "releaseId": "$releases[0]" }
      """
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$0/entitlements"
    Then the response status should be "200"
    And the response body should be an array with 3 "entitlements"

  Scenario: User attempts to retrieve the entitlements for a release they do have a license for (license user)
    Given the current account is "test1"
    And the current account has 3 "entitlements"
    And the current account has 1 "user"
    And the current account has 1 "product"
    And the current account has 1 "release" for the last "product"
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "license" for the last "policy"
    And the current account has 1 "license-user" for the last "license" and the last "user"
    And the current account has 1 "license-entitlement" with the following:
      """
      { "entitlementId": "$entitlements[0]", "licenseId": "$licenses[0]" }
      """
    And the current account has 1 "policy-entitlement" with the following:
      """
      { "entitlementId": "$entitlements[1]", "policyId": "$policies[0]" }
      """
    And the current account has 1 "policy-entitlement" with the following:
      """
      { "entitlementId": "$entitlements[2]", "policyId": "$policies[0]" }
      """
    And the current account has 1 "release-entitlement-constraint" with the following:
      """
      { "entitlementId": "$entitlements[0]", "releaseId": "$releases[0]" }
      """
    And the current account has 1 "release-entitlement-constraint" with the following:
      """
      { "entitlementId": "$entitlements[1]", "releaseId": "$releases[0]" }
      """
    And the current account has 1 "release-entitlement-constraint" with the following:
      """
      { "entitlementId": "$entitlements[2]", "releaseId": "$releases[0]" }
      """
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$0/entitlements"
    Then the response status should be "200"
    And the response body should be an array with 3 "entitlements"

  Scenario: Admin attempts to retrieve the entitlements for a release of another account
    Given I am an admin of account "test2"
    And the current account is "test1"
    And the current account has 1 "release"
    And the current account has 3 "release-entitlement-constraints" for existing "releases"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$0/entitlements"
    Then the response status should be "401"

  Scenario: License attempts to retrieve an entitlement for a release of their product (has entitlements)
    Given the current account is "test1"
    And the current account has 1 "entitlement"
    And the current account has 1 "product"
    And the current account has 1 "release" for the last "product"
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "license" for the last "policy"
    And the current account has 1 "license-entitlement" with the following:
      """
      { "entitlementId": "$entitlements[0]", "licenseId": "$licenses[0]" }
      """
    And the current account has 1 "release-entitlement-constraint" with the following:
      """
      { "entitlementId": "$entitlements[0]", "releaseId": "$releases[0]" }
      """
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$0/entitlements/$0"
    Then the response status should be "200"
    And the response body should be a "entitlement"

  Scenario: License attempts to retrieve an entitlement for a release of their product (no entitlements)
    Given the current account is "test1"
    And the current account has 1 "entitlement"
    And the current account has 1 "product"
    And the current account has 1 "release" for the last "product"
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "license" for the last "policy"
    And the current account has 1 "release-entitlement-constraint" with the following:
      """
      { "entitlementId": "$entitlements[0]", "releaseId": "$releases[0]" }
      """
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$0/entitlements/$0"
    Then the response status should be "404"

  Scenario: License attempts to retrieve an entitlement for a product release
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "release" for the last "product"
    And the current account has 3 "release-entitlement-constraints" for each "release"
    And the current account has 1 "license"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$0/entitlements/$0"
    Then the response status should be "404"

  Scenario: User attempts to retrieve an entitlement for a release they do have a license for (license owner, has entitlements)
    Given the current account is "test1"
    And the current account has 1 "entitlement"
    And the current account has 1 "user"
    And the current account has 1 "product"
    And the current account has 1 "release" for the last "product"
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "license" for the last "policy"
    And the last "license" has the following attributes:
      """
      { "userId": "$users[1]" }
      """
    And the current account has 1 "license-entitlement" with the following:
      """
      { "entitlementId": "$entitlements[0]", "licenseId": "$licenses[0]" }
      """
    And the current account has 1 "release-entitlement-constraint" with the following:
      """
      { "entitlementId": "$entitlements[0]", "releaseId": "$releases[0]" }
      """
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$0/entitlements/$0"
    Then the response status should be "200"
    And the response body should be a "entitlement"

  Scenario: User attempts to retrieve an entitlement for a release they do have a license for (license user, has entitlements)
    Given the current account is "test1"
    And the current account has 1 "entitlement"
    And the current account has 1 "user"
    And the current account has 1 "product"
    And the current account has 1 "release" for the last "product"
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "license" for the last "policy"
    And the current account has 1 "license-user" for the last "license" and the last "user"
    And the current account has 1 "license-entitlement" with the following:
      """
      { "entitlementId": "$entitlements[0]", "licenseId": "$licenses[0]" }
      """
    And the current account has 1 "release-entitlement-constraint" with the following:
      """
      { "entitlementId": "$entitlements[0]", "releaseId": "$releases[0]" }
      """
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$0/entitlements/$0"
    Then the response status should be "200"
    And the response body should be a "entitlement"

  Scenario: User attempts to retrieve an entitlement for a release they do have a license for (no entitlements)
    Given the current account is "test1"
    And the current account has 1 "entitlement"
    And the current account has 1 "user"
    And the current account has 1 "product"
    And the current account has 1 "release" for the last "product"
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "license" for the last "policy"
    And the last "license" has the following attributes:
      """
      { "userId": "$users[1]" }
      """
    And the current account has 1 "release-entitlement-constraint" with the following:
      """
      { "entitlementId": "$entitlements[0]", "releaseId": "$releases[0]" }
      """
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$0/entitlements/$0"
    Then the response status should be "404"

  Scenario: User attempts to retrieve an entitlement for a release they don't have a license for
    Given the current account is "test1"
    And the current account has 1 "user"
    And the current account has 1 "product"
    And the current account has 1 "release" for the last "product"
    And the current account has 3 "release-entitlement-constraints" for each "release"
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "license" for the last "policy"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$0/entitlements/$0"
    Then the response status should be "404"
