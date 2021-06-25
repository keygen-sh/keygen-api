@api/v1
Feature: Release blob relationship

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
    When I send a GET request to "/accounts/test1/releases/$0/blob"
    Then the response status should be "403"

  # Blob download links
  Scenario: Admin retrieves the blob for a release
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 3 "releases"
    And the first "release" has a blob that is uploaded
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$0/blob"
    Then the response status should be "303"
    And the JSON response should be a "release-download-link" with the following attributes:
      """
      { "ttl": 60 }
      """

   Scenario: Admin retrieves the blob for a release (1 hour TTL)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 3 "releases"
    And the first "release" has a blob that is uploaded
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$0/blob?ttl=3600"
    Then the response status should be "303"
    And the JSON response should be a "release-download-link" with the following attributes:
      """
      { "ttl": 3600 }
      """

  Scenario: Admin retrieves the blob for a release (10 second TTL)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 3 "releases"
    And the first "release" has a blob that is uploaded
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$0/blob?ttl=10"
    Then the response status should be "400"
    And the first error should have the following properties:
      """
      {
        "title": "Bad request",
        "detail": "must be greater than or equal to 60 (1 minute)",
        "source": {
          "parameter": "ttl"
        }
      }
      """

  Scenario: Admin retrieves the blob for a release (2 week TTL)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 3 "releases"
    And the first "release" has a blob that is uploaded
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$0/blob?ttl=1209600"
    Then the response status should be "400"
    And the first error should have the following properties:
      """
      {
        "title": "Bad request",
        "detail": "must be less than or equal to 604800 (1 week)",
        "source": {
          "parameter": "ttl"
        }
      }
      """

  Scenario: Admin retrieves the blob for a release that has not been uploaded
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 3 "releases"
    And the first "release" has a blob that is not uploaded
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$0/blob"
    Then the response status should be "404"
    And the first error should have the following properties:
      """
      {
        "title": "Not found",
        "detail": "does not exist or is unavailable",
        "source": {
          "pointer": "/data/relationships/blob"
        },
        "code": "RELEASE_BLOB_UNAVAILABLE"
      }
      """

  Scenario: Admin retrieves the blob for a release that has not been uploaded
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 3 "releases"
    And the first "release" has a blob that is timing out
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$0/blob"
    Then the response status should be "404"
    And the first error should have the following properties:
      """
      {
        "title": "Not found",
        "detail": "does not exist or is unavailable",
        "source": {
          "pointer": "/data/relationships/blob"
        },
        "code": "RELEASE_BLOB_UNAVAILABLE"
      }
      """

  Scenario: Product retrieves the blob for a release of their product
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 3 "releases" for the first "product"
    And the first "release" has a blob that is uploaded
    Given I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$0/blob"
    Then the response status should be "303"
    And the JSON response should be a "release-download-link" with the following attributes:
      """
      { "ttl": 60 }
      """

  Scenario: Product retrieves the blob for a release of their product (1 week TTL)
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 3 "releases" for the first "product"
    And the first "release" has a blob that is uploaded
    Given I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$0/blob?ttl=604800"
    Then the response status should be "303"
    And the JSON response should be a "release-download-link" with the following attributes:
      """
      { "ttl": 604800 }
      """

  Scenario: Product retrieves the blob for a release of a different product
    Given the current account is "test1"
    And the current account has 2 "products"
    And the current account has 2 "releases" for the second "product"
    And the first "release" has a blob that is uploaded
    Given I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$0/blob"
    Then the response status should be "404"

  Scenario: License retrieves the blob for a release of their product
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "policy" for an existing "product"
    And the current account has 1 "license" for an existing "policy"
    And the current account has 3 "releases" for the first "product"
    And the first "release" has a blob that is uploaded
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$0/blob"
    Then the response status should be "303"
    And the JSON response should be a "release-download-link" with the following attributes:
      """
      { "ttl": 60 }
      """

  Scenario: License retrieves the blob for a release of their product (1 day TTL)
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "policy" for an existing "product"
    And the current account has 1 "license" for an existing "policy"
    And the current account has 3 "releases" for the first "product"
    And the first "release" has a blob that is uploaded
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$0/blob?ttl=86400"
    Then the response status should be "303"
    And the JSON response should be a "release-download-link" with the following attributes:
      """
      { "ttl": 60 }
      """

  Scenario: License retrieves the blob for a release of their product (expired)
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "policy" for an existing "product"
    And the current account has 1 "license" for an existing "policy"
    And the first "license" has the following attributes:
      """
      { "expiry": "$time.2.minutes.ago" }
      """
    And the current account has 3 "releases" for the first "product"
    And the first "release" has a blob that is uploaded
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$0/blob"
    Then the response status should be "403"

  Scenario: License retrieves the blob for a release of their product (expired after release)
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "policy" for an existing "product"
    And the current account has 1 "license" for an existing "policy"
    And the first "license" has the following attributes:
      """
      { "expiry": "$time.2.months.ago" }
      """
    And the current account has 3 "releases" for the first "product"
    And the first "release" has the following attributes:
      """
      { "createdAt": "$time.3.months.ago" }
      """
    And the first "release" has a blob that is uploaded
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$0/blob"
    Then the response status should be "303"
    And the JSON response should be a "release-download-link"

  Scenario: License retrieves the blob for a release of their product (suspended)
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "policy" for an existing "product"
    And the current account has 1 "license" for an existing "policy"
    And the first "license" has the following attributes:
      """
      { "suspended": true }
      """
    And the current account has 3 "releases" for the first "product"
    And the first "release" has a blob that is uploaded
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$0/blob"
    Then the response status should be "403"

  Scenario: License retrieves the blob for a release of a different product
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "license"
    And the current account has 3 "releases" for the first "product"
    And the first "release" has a blob that is uploaded
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$0/blob"
    Then the response status should be "404"

  Scenario: License retrieves a release blob of their product (has single entitlement)
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "entitlement"
    And the current account has 1 "policy" for an existing "product"
    And the current account has 1 "license" for an existing "policy"
    And the current account has 1 "license-entitlement" with the following:
      """
      {
        "entitlementId": "$entitlements[0]",
        "licenseId": "$licenses[0]"
      }
      """
    And the current account has 1 "release" for an existing "product"
    And the current account has 1 "release-entitlement-constraint" with the following:
      """
      {
        "entitlementId": "$entitlements[0]",
        "releaseId": "$releases[0]"
      }
      """
    And the first "release" has a blob that is uploaded
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$0/blob"
    Then the response status should be "303"

  Scenario: License retrieves a release blob of their product (has multiple entitlements)
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 2 "entitlements"
    And the current account has 1 "policy" for an existing "product"
    And the current account has 1 "license" for an existing "policy"
    And the current account has 1 "license-entitlement" with the following:
      """
      {
        "entitlementId": "$entitlements[0]",
        "licenseId": "$licenses[0]"
      }
      """
    And the current account has 1 "license-entitlement" with the following:
      """
      {
        "entitlementId": "$entitlements[1]",
        "licenseId": "$licenses[0]"
      }
      """
    And the current account has 1 "release" for an existing "product"
    And the current account has 1 "release-entitlement-constraint" with the following:
      """
      {
        "entitlementId": "$entitlements[0]",
        "releaseId": "$releases[0]"
      }
      """
    And the current account has 1 "release-entitlement-constraint" with the following:
      """
      {
        "entitlementId": "$entitlements[1]",
        "releaseId": "$releases[0]"
      }
      """
    And the first "release" has a blob that is uploaded
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$0/blob"
    Then the response status should be "303"

  Scenario: License retrieves a release blob of their product (missing some entitlements)
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 2 "entitlements"
    And the current account has 1 "policy" for an existing "product"
    And the current account has 1 "license" for an existing "policy"
    And the current account has 1 "license-entitlement" with the following:
      """
      {
        "entitlementId": "$entitlements[0]",
        "licenseId": "$licenses[0]"
      }
      """
    And the current account has 1 "release" for an existing "product"
    And the current account has 1 "release-entitlement-constraint" with the following:
      """
      {
        "entitlementId": "$entitlements[0]",
        "releaseId": "$releases[0]"
      }
      """
    And the current account has 1 "release-entitlement-constraint" with the following:
      """
      {
        "entitlementId": "$entitlements[1]",
        "releaseId": "$releases[0]"
      }
      """
    And the first "release" has a blob that is uploaded
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$0/blob"
    Then the response status should be "403"

  Scenario: License retrieves a release blob of their product (missing all entitlements)
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "policy" for an existing "product"
    And the current account has 1 "license" for an existing "policy"
    And the current account has 1 "release" for an existing "product"
    And the current account has 1 "release-entitlement-constraint" for an existing "release"
    And the first "release" has a blob that is uploaded
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$0/blob"
    Then the response status should be "403"

  Scenario: User retrieves a release blob with a license for it
    Given the current account is "test1"
    And the current account has 1 "user"
    And the current account has 1 "product"
    And the current account has 1 "policy" for an existing "product"
    And the current account has 1 "license" for an existing "policy"
    And the current account has 1 "release" for an existing "product"
    And the first "release" has a blob that is uploaded
    And I am a user of account "test1"
    And I use an authentication token
    And the current user has 1 "license"
    When I send a GET request to "/accounts/test1/releases/$0/blob"
    Then the response status should be "303"
    And the JSON response should be a "release-download-link" with the following attributes:
      """
      { "ttl": 60 }
      """

  Scenario: User retrieves a release blob with a license for it (2 minute TTL)
    Given the current account is "test1"
    And the current account has 1 "user"
    And the current account has 1 "product"
    And the current account has 1 "policy" for an existing "product"
    And the current account has 1 "license" for an existing "policy"
    And the current account has 1 "release" for an existing "product"
    And the first "release" has a blob that is uploaded
    And I am a user of account "test1"
    And I use an authentication token
    And the current user has 1 "license"
    When I send a GET request to "/accounts/test1/releases/$0/blob?ttl=120"
    Then the response status should be "303"
    And the JSON response should be a "release-download-link" with the following attributes:
      """
      { "ttl": 60 }
      """

  Scenario: User retrieves a release blob with a license for it (expired)
    Given the current account is "test1"
    And the current account has 1 "user"
    And the current account has 1 "product"
    And the current account has 1 "policy" for an existing "product"
    And the current account has 1 "license" for an existing "policy"
    And the first "license" has the following attributes:
      """
      { "expiry": "$time.2.days.ago" }
      """
    And the current account has 1 "release" for an existing "product"
    And the first "release" has a blob that is uploaded
    And I am a user of account "test1"
    And I use an authentication token
    And the current user has 1 "license"
    When I send a GET request to "/accounts/test1/releases/$0/blob"
    Then the response status should be "403"

  Scenario: User retrieves a release blob with a license for it (expired after release)
    Given the current account is "test1"
    And the current account has 1 "user"
    And the current account has 1 "product"
    And the current account has 1 "policy" for an existing "product"
    And the current account has 1 "license" for an existing "policy"
    And the first "license" has the following attributes:
      """
      { "expiry": "$time.2.days.ago" }
      """
    And the current account has 1 "release" for an existing "product"
    And the first "release" has the following attributes:
      """
      { "createdAt": "$time.1.months.ago" }
      """
    And the first "release" has a blob that is uploaded
    And I am a user of account "test1"
    And I use an authentication token
    And the current user has 1 "license"
    When I send a GET request to "/accounts/test1/releases/$0/blob"
    Then the response status should be "303"
    And the JSON response should be a "release-download-link"

  Scenario: User retrieves a release blob with a license for it (suspended)
    Given the current account is "test1"
    And the current account has 1 "user"
    And the current account has 1 "product"
    And the current account has 1 "policy" for an existing "product"
    And the current account has 1 "license" for an existing "policy"
    And the first "license" has the following attributes:
      """
      { "suspended": true }
      """
    And the current account has 1 "release" for an existing "product"
    And the first "release" has a blob that is uploaded
    And I am a user of account "test1"
    And I use an authentication token
    And the current user has 1 "license"
    When I send a GET request to "/accounts/test1/releases/$0/blob"
    Then the response status should be "403"

  Scenario: User retrieves a release blob with multiple licenses for it (expired and non-expired)
    Given the current account is "test1"
    And the current account has 1 "user"
    And the current account has 1 "product"
    And the current account has 1 "policy" for an existing "product"
    And the current account has 2 "licenses" for an existing "policy"
    And the first "license" has the following attributes:
      """
      { "expiry": "$time.2.days.ago" }
      """
    And the current account has 1 "release" for an existing "product"
    And the first "release" has a blob that is uploaded
    And I am a user of account "test1"
    And I use an authentication token
    And the current user has 2 "licenses"
    When I send a GET request to "/accounts/test1/releases/$0/blob"
    Then the response status should be "303"

  Scenario: User retrieves a release blob with multiple licenses for it (suspended, expired and valid)
    Given the current account is "test1"
    And the current account has 1 "user"
    And the current account has 1 "product"
    And the current account has 1 "policy" for an existing "product"
    And the current account has 3 "licenses" for an existing "policy"
    And the first "license" has the following attributes:
      """
      { "expiry": "$time.2.days.ago" }
      """
    And the second "license" has the following attributes:
      """
      { "suspended": true }
      """
    And the current account has 1 "release" for an existing "product"
    And the first "release" has a blob that is uploaded
    And I am a user of account "test1"
    And I use an authentication token
    And the current user has 3 "licenses"
    When I send a GET request to "/accounts/test1/releases/$0/blob"
    Then the response status should be "303"

  Scenario: User retrieves a release blob with a license for it (has single entitlement)
    Given the current account is "test1"
    And the current account has 1 "user"
    And the current account has 1 "product"
    And the current account has 1 "entitlement"
    And the current account has 1 "policy" for an existing "product"
    And the current account has 1 "license" for an existing "policy"
    And the current account has 1 "license-entitlement" with the following:
      """
      {
        "entitlementId": "$entitlements[0]",
        "licenseId": "$licenses[0]"
      }
      """
    And the current account has 1 "release" for an existing "product"
    And the current account has 1 "release-entitlement-constraint" with the following:
      """
      {
        "entitlementId": "$entitlements[0]",
        "releaseId": "$releases[0]"
      }
      """
    And the first "release" has a blob that is uploaded
    And I am a user of account "test1"
    And I use an authentication token
    And the current user has 1 "license"
    When I send a GET request to "/accounts/test1/releases/$0/blob"
    Then the response status should be "303"

  Scenario: User retrieves a release blob with a license for it (has multiple entitlements)
    Given the current account is "test1"
    And the current account has 1 "user"
    And the current account has 1 "product"
    And the current account has 2 "entitlements"
    And the current account has 1 "policy" for an existing "product"
    And the current account has 1 "license" for an existing "policy"
    And the current account has 1 "license-entitlement" with the following:
      """
      {
        "entitlementId": "$entitlements[0]",
        "licenseId": "$licenses[0]"
      }
      """
    And the current account has 1 "license-entitlement" with the following:
      """
      {
        "entitlementId": "$entitlements[1]",
        "licenseId": "$licenses[0]"
      }
      """
    And the current account has 1 "release" for an existing "product"
    And the current account has 1 "release-entitlement-constraint" with the following:
      """
      {
        "entitlementId": "$entitlements[0]",
        "releaseId": "$releases[0]"
      }
      """
    And the current account has 1 "release-entitlement-constraint" with the following:
      """
      {
        "entitlementId": "$entitlements[1]",
        "releaseId": "$releases[0]"
      }
      """
    And the first "release" has a blob that is uploaded
    And I am a user of account "test1"
    And I use an authentication token
    And the current user has 1 "license"
    When I send a GET request to "/accounts/test1/releases/$0/blob"
    Then the response status should be "303"

  Scenario: User retrieves a release blob with a license for it (missing some entitlements)
    Given the current account is "test1"
    And the current account has 1 "user"
    And the current account has 1 "product"
    And the current account has 2 "entitlements"
    And the current account has 1 "policy" for an existing "product"
    And the current account has 1 "license" for an existing "policy"
    And the current account has 1 "license-entitlement" with the following:
      """
      {
        "entitlementId": "$entitlements[0]",
        "licenseId": "$licenses[0]"
      }
      """
    And the current account has 1 "release" for an existing "product"
    And the current account has 1 "release-entitlement-constraint" with the following:
      """
      {
        "entitlementId": "$entitlements[0]",
        "releaseId": "$releases[0]"
      }
      """
    And the current account has 1 "release-entitlement-constraint" with the following:
      """
      {
        "entitlementId": "$entitlements[1]",
        "releaseId": "$releases[0]"
      }
      """
    And the first "release" has a blob that is uploaded
    And I am a user of account "test1"
    And I use an authentication token
    And the current user has 1 "license"
    When I send a GET request to "/accounts/test1/releases/$0/blob"
    Then the response status should be "403"

  Scenario: User retrieves a release blob with a license for it (missing all entitlements)
    Given the current account is "test1"
    And the current account has 1 "user"
    And the current account has 1 "product"
    And the current account has 1 "policy" for an existing "product"
    And the current account has 1 "license" for an existing "policy"
    And the current account has 1 "release" for an existing "product"
    And the current account has 1 "release-entitlement-constraint" for an existing "release"
    And the first "release" has a blob that is uploaded
    And I am a user of account "test1"
    And I use an authentication token
    And the current user has 1 "license"
    When I send a GET request to "/accounts/test1/releases/$0/blob"
    Then the response status should be "403"

  Scenario: User retrieves a release blob without a license for it
    Given the current account is "test1"
    And the current account has 1 "user"
    And the current account has 1 "release"
    And the first "release" has a blob that is uploaded
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$0/blob"
    Then the response status should be "404"

  # Blob upload links
  Scenario: Admin uploads a blob for a release (not uploaded)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 3 "releases"
    And the first "release" has a blob that is not uploaded
    And I use an authentication token
    When I send a PUT request to "/accounts/test1/releases/$0/blob"
    Then the response status should be "307"
    And the JSON response should be a "release-upload-link"

  Scenario: Admin uploads a blob for a release (already uploaded)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 3 "releases"
    And the first "release" has a blob that is uploaded
    And I use an authentication token
    When I send a PUT request to "/accounts/test1/releases/$0/blob"
    Then the response status should be "307"
    And the JSON response should be a "release-upload-link"

  Scenario: Product uploads a blob for a release of their product
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 3 "releases" for the first "product"
    And the first "release" has a blob that is not uploaded
    Given I am a product of account "test1"
    And I use an authentication token
    When I send a PUT request to "/accounts/test1/releases/$0/blob"
    Then the response status should be "307"
    And the JSON response should be a "release-upload-link"

  Scenario: Product uploads a blob for a release of a different product
    Given the current account is "test1"
    And the current account has 2 "products"
    And the current account has 2 "releases" for the second "product"
    And the first "release" has a blob that is not uploaded
    Given I am a product of account "test1"
    And I use an authentication token
    When I send a PUT request to "/accounts/test1/releases/$0/blob"
    Then the response status should be "404"

  Scenario: License uploads a blob for a release of their product
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "policy" for an existing "product"
    And the current account has 1 "license" for an existing "policy"
    And the current account has 3 "releases" for the first "product"
    And the first "release" has a blob that is uploaded
    And I am a license of account "test1"
    And I use an authentication token
    When I send a PUT request to "/accounts/test1/releases/$0/blob"
    Then the response status should be "403"

  Scenario: License uploads a blob for a release of a different product
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "license"
    And the current account has 3 "releases" for the first "product"
    And the first "release" has a blob that is uploaded
    And I am a license of account "test1"
    And I use an authentication token
    When I send a PUT request to "/accounts/test1/releases/$0/blob"
    Then the response status should be "404"

  Scenario: User uploads a blob for a release with a license for it
    Given the current account is "test1"
    And the current account has 1 "user"
    And the current account has 1 "product"
    And the current account has 1 "policy" for an existing "product"
    And the current account has 1 "license" for an existing "policy"
    And the current account has 1 "release" for an existing "product"
    And the first "release" has a blob that is uploaded
    And I am a user of account "test1"
    And I use an authentication token
    And the current user has 1 "license"
    When I send a PUT request to "/accounts/test1/releases/$0/blob"
    Then the response status should be "403"

  Scenario: User uploads a blob for a release without a license for it
    Given the current account is "test1"
    And the current account has 1 "user"
    And the current account has 1 "release"
    And the first "release" has a blob that is uploaded
    And I am a user of account "test1"
    And I use an authentication token
    When I send a PUT request to "/accounts/test1/releases/$0/blob"
    Then the response status should be "404"

  # Blob yank
  Scenario: Admin yanks a blob for a release (not uploaded)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 3 "releases"
    And the first "release" has a blob that is not uploaded
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/releases/$0/blob"
    Then the response status should be "204"
    And the first "release" should be yanked

  Scenario: Admin yanks a blob for a release (uploaded)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 3 "releases"
    And the first "release" has a blob that is uploaded
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/releases/$0/blob"
    Then the response status should be "204"
    And the first "release" should be yanked

  Scenario: Product yanks a blob for a release of their product
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 3 "releases" for the first "product"
    And the first "release" has a blob that is uploaded
    Given I am a product of account "test1"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/releases/$0/blob"
    Then the response status should be "204"
    And the first "release" should be yanked

  Scenario: Product yanks a blob for a release of a different product
    Given the current account is "test1"
    And the current account has 2 "products"
    And the current account has 2 "releases" for the second "product"
    And the first "release" has a blob that is not uploaded
    Given I am a product of account "test1"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/releases/$0/blob"
    Then the response status should be "404"
    And the first "release" should not be yanked

  Scenario: License yanks a blob for a release of their product
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "policy" for an existing "product"
    And the current account has 1 "license" for an existing "policy"
    And the current account has 3 "releases" for the first "product"
    And the first "release" has a blob that is uploaded
    And I am a license of account "test1"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/releases/$0/blob"
    Then the response status should be "403"
    And the first "release" should not be yanked

  Scenario: License yanks a blob for a release of a different product
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "license"
    And the current account has 3 "releases" for the first "product"
    And the first "release" has a blob that is uploaded
    And I am a license of account "test1"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/releases/$0/blob"
    Then the response status should be "404"
    And the first "release" should not be yanked

  Scenario: User yanks a blob for a release with a license for it
    Given the current account is "test1"
    And the current account has 1 "user"
    And the current account has 1 "product"
    And the current account has 1 "policy" for an existing "product"
    And the current account has 1 "license" for an existing "policy"
    And the current account has 1 "release" for an existing "product"
    And the first "release" has a blob that is uploaded
    And I am a user of account "test1"
    And I use an authentication token
    And the current user has 1 "license"
    When I send a DELETE request to "/accounts/test1/releases/$0/blob"
    Then the response status should be "403"
    And the first "release" should not be yanked

  Scenario: User yanks a blob for a release without a license for it
    Given the current account is "test1"
    And the current account has 1 "user"
    And the current account has 1 "release"
    And the first "release" has a blob that is uploaded
    And I am a user of account "test1"
    And I use an authentication token
    When I send a DELETE request to "/accounts/test1/releases/$0/blob"
    Then the response status should be "404"
    And the first "release" should not be yanked
