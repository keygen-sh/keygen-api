@api/v1
Feature: Release upgrade actions

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
    When I send a GET request to "/accounts/test1/releases/$0/actions/upgrade"
    Then the response status should be "403"

  # Upgrade by ID
  Scenario: Admin retrieves an upgrade for a product release (upgrade available)
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name     |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test App |
    And the current account has the following "release" rows:
      | product_id                           | version      | filename                  | filetype | platform | channel  |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0        | Test-App-1.0.0.dmg        | dmg      | macos    | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.1        | Test-App-1.0.1.dmg        | dmg      | macos    | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.2        | Test-App-1.0.2.dmg        | dmg      | macos    | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.3        | Test-App-1.0.3.dmg        | dmg      | macos    | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.0        | Test-App-1.1.0.dmg        | dmg      | macos    | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.1        | Test-App-1.1.1.dmg        | dmg      | macos    | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.2        | Test-App-1.1.2.dmg        | dmg      | macos    | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.2.0        | Test-App-1.2.0.dmg        | dmg      | macos    | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.3.0        | Test-App-1.3.0.dmg        | dmg      | macos    | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.4.0        | Test-App-1.4.0.dmg        | dmg      | macos    | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.5.0        | Test-App-1.5.0.dmg        | dmg      | macos    | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.6.0        | Test-App-1.6.0.dmg        | dmg      | macos    | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.7.0        | Test-App-1.7.0.dmg        | dmg      | macos    | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0        | Test-App-2.0.0.dmg        | dmg      | macos    | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.1        | Test-App-2.0.1.dmg        | dmg      | macos    | stable   |
    And all "releases" have artifacts that are uploaded
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$0/actions/upgrade"
    Then the response status should be "303"
    And the JSON response should be an "artifact"
    And the JSON response should contain meta which includes the following:
      """
      {
        "current": "1.0.0",
        "next": "2.0.1"
      }
      """

  Scenario: Admin retrieves an upgrade for a product release (no upgrade available)
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name     |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test App |
    And the current account has the following "release" rows:
      | product_id                           | version      | filename                  | filetype | platform | channel  |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0        | Test-App-1.0.0.dmg        | dmg      | macos    | stable   |
    And all "releases" have artifacts that are uploaded
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$0/actions/upgrade"
    Then the response status should be "204"

  Scenario: Admin retrieves an upgrade for a product release (no artifact available)
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name     |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test App |
    And the current account has the following "release" rows:
      | product_id                           | version      | filename                  | filetype | platform | channel  |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0        | Test-App-1.0.0.dmg        | dmg      | macos    | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.1        | Test-App-1.0.1.dmg        | dmg      | macos    | stable   |
    And the all "releases" have artifacts that are not uploaded
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$0/actions/upgrade"
    Then the response status should be "204"

  Scenario: Admin retrieves an upgrade for a product release (artifact timing out)
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name     |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test App |
    And the current account has the following "release" rows:
      | product_id                           | version      | filename                  | filetype | platform | channel  |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0        | Test-App-1.0.0.dmg        | dmg      | macos    | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.1        | Test-App-1.0.1.dmg        | dmg      | macos    | stable   |
    And the all "releases" have artifacts that are timing out
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$0/actions/upgrade"
    Then the response status should be "204"

  # Products
  Scenario: Product retrieves an upgrade for a release (upgrade available)
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name     |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test App |
    And the current account has the following "release" rows:
      | product_id                           | version      | filename                  | filetype | platform | channel  |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0        | Test-App-1.0.0.dmg        | dmg      | macos    | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.2.0        | Test-App-1.2.0.dmg        | dmg      | macos    | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.1        | Test-App-1.0.1.zip        | zip      | macos    | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.0        | Test-App-1.1.0.zip        | zip      | macos    | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.3.0        | Test-App-1.3.0.zip        | zip      | macos    | stable   |
    And all "releases" have artifacts that are uploaded
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$0/actions/upgrade"
    Then the response status should be "303"
    And the JSON response should be an "artifact"
    And the JSON response should contain meta which includes the following:
      """
      {
        "current": "1.0.0",
        "next": "1.2.0"
      }
      """
  Scenario: Product retrieves an upgrade for a release (no upgrade available)
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name     |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test App |
    And the current account has the following "release" rows:
      | product_id                           | version      | filename                  | filetype | platform | channel  |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 0.1.0        | Test-App-0.1.0.dmg        | dmg      | macos    | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0        | Test-App-1.0.0.dmg        | dmg      | macos    | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0        | Test-App-2.0.0.exe        | exe      | win32    | stable   |
    And all "releases" have artifacts that are uploaded
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$1/actions/upgrade"
    Then the response status should be "204"

  Scenario: Product retrieves an upgrade for a release of a different product
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name       |
      | 6ac37cee-0027-4cdb-ba25-ac98fa0d29b4 | Test App A |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test App B |
    And the current account has the following "release" rows:
      | product_id                           | version      | filename                  | filetype | platform | channel  |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0        | Test-App-B-1.0.0.exe      | exe      | win32    | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0        | Test-App-B-2.0.0.exe      | exe      | win32    | stable   |
    And all "releases" have artifacts that are uploaded
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$0/actions/upgrade"
    Then the response status should be "404"

  # Licenses
  Scenario: License retrieves an upgrade for a release of their product (upgrade available)
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name     |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test App |
    And the current account has the following "release" rows:
      | product_id                           | version      | filename                  | filetype | platform | channel  |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0        | Test-App-1.0.0.dmg        | dmg      | macos    | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.2.0        | Test-App-1.2.0.dmg        | dmg      | macos    | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.1        | Test-App-1.0.1.zip        | zip      | macos    | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.0        | Test-App-1.1.0.zip        | zip      | macos    | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.3.0        | Test-App-1.3.0.zip        | zip      | macos    | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0-beta.1 | Test-App-2.0.0-beta.1.zip | zip      | macos    | beta     |
    And all "releases" have artifacts that are uploaded
    And the current account has 1 "policy" for the first "product"
    And the current account has 1 "license" for the first "policy"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$2/actions/upgrade"
    Then the response status should be "303"
    And the JSON response should be an "artifact"
    And the JSON response should contain meta which includes the following:
      """
      {
        "current": "1.0.1",
        "next": "1.3.0"
      }
      """

  Scenario: License retrieves an upgrade for a release of their product (expired, but access restricted)
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name     |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test App |
    And the current account has the following "release" rows:
      | product_id                           | version      | filename                  | filetype | platform | channel  |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0        | Test-App-1.0.0.dmg        | dmg      | macos    | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.2.0        | Test-App-1.2.0.dmg        | dmg      | macos    | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.1        | Test-App-1.0.1.zip        | zip      | macos    | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.0        | Test-App-1.1.0.zip        | zip      | macos    | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.3.0        | Test-App-1.3.0.zip        | zip      | macos    | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0-beta.1 | Test-App-2.0.0-beta.1.zip | zip      | macos    | beta     |
    And all "releases" have artifacts that are uploaded
    And the current account has 1 "policy" for the first "product"
    And the first "policy" has the following attributes:
      """
      { "expirationStrategy": "RESTRICT_ACCESS" }
      """
    And the current account has 1 "license" for the first "policy"
    And the first "license" has the following attributes:
      """
      { "expiry": "$time.2.months.ago" }
      """
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$2/actions/upgrade"
    Then the response status should be "204"

  Scenario: License retrieves an upgrade for a release of their product (expired, but access revoked)
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name     |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test App |
    And the current account has the following "release" rows:
      | product_id                           | version      | filename                  | filetype | platform | channel  |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0        | Test-App-1.0.0.dmg        | dmg      | macos    | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.2.0        | Test-App-1.2.0.dmg        | dmg      | macos    | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.1        | Test-App-1.0.1.zip        | zip      | macos    | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.0        | Test-App-1.1.0.zip        | zip      | macos    | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.3.0        | Test-App-1.3.0.zip        | zip      | macos    | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0-beta.1 | Test-App-2.0.0-beta.1.zip | zip      | macos    | beta     |
    And all "releases" have artifacts that are uploaded
    And the current account has 1 "policy" for the first "product"
    And the first "policy" has the following attributes:
      """
      { "expirationStrategy": "REVOKE_ACCESS" }
      """
    And the current account has 1 "license" for the first "policy"
    And the first "license" has the following attributes:
      """
      { "expiry": "$time.6.months.ago" }
      """
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$2/actions/upgrade"
    Then the response status should be "204"

  Scenario: License retrieves an upgrade for a release of their product (suspended)
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name     |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test App |
    And the current account has the following "release" rows:
      | product_id                           | version      | filename                  | filetype | platform | channel  |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0        | Test-App-1.0.0.dmg        | dmg      | macos    | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.2.0        | Test-App-1.2.0.dmg        | dmg      | macos    | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.1        | Test-App-1.0.1.zip        | zip      | macos    | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.0        | Test-App-1.1.0.zip        | zip      | macos    | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.3.0        | Test-App-1.3.0.zip        | zip      | macos    | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0-beta.1 | Test-App-2.0.0-beta.1.zip | zip      | macos    | beta     |
    And all "releases" have artifacts that are uploaded
    And the current account has 1 "policy" for the first "product"
    And the current account has 1 "license" for the first "policy"
    And the first "license" has the following attributes:
      """
      { "suspended": true }
      """
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$2/actions/upgrade"
    Then the response status should be "204"

  Scenario: License retrieves an upgrade for a release of a different product
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name     |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test App |
    And the current account has the following "release" rows:
      | product_id                           | version      | filename                  | filetype | platform | channel  |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0        | Test-App-1.0.0.dmg        | dmg      | macos    | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.2.0        | Test-App-1.2.0.dmg        | dmg      | macos    | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.1        | Test-App-1.0.1.zip        | zip      | macos    | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.0        | Test-App-1.1.0.zip        | zip      | macos    | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.3.0        | Test-App-1.3.0.zip        | zip      | macos    | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0-beta.1 | Test-App-2.0.0-beta.1.zip | zip      | macos    | beta     |
    And all "releases" have artifacts that are uploaded
    And the current account has 1 "license"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$2/actions/upgrade"
    Then the response status should be "404"

  Scenario: License retrieves an upgrade for a release of their product (has single entitlement)
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name     |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test App |
    And the current account has the following "release" rows:
      | product_id                           | version      | filename                  | filetype | platform | channel  |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0        | Test-App-1.0.0.dmg        | dmg      | macos    | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.0        | Test-App-1.1.0.dmg        | dmg      | macos    | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.2.0        | Test-App-1.2.0.zip        | zip      | macos    | stable   |
    And all "releases" have artifacts that are uploaded
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
        "entitlementId": "$entitlements[0]",
        "releaseId": "$releases[1]"
      }
      """
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$0/actions/upgrade"
    Then the response status should be "303"
    And the JSON response should be an "artifact"
    And the JSON response should contain meta which includes the following:
      """
      {
        "current": "1.0.0",
        "next": "1.1.0"
      }
      """

  Scenario: License retrieves an upgrade for a release of their product (has multiple entitlements)
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name     |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test App |
    And the current account has the following "release" rows:
      | product_id                           | version       | filename                   | filetype | platform | channel  |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0-alpha.1 | Test-App-1.0.0-alpha.1.dmg | dmg      | macos    | alpha    |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0         | Test-App-1.0.0.dmg         | dmg      | macos    | stable   |
    And all "releases" have artifacts that are uploaded
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
        "entitlementId": "$entitlements[0]",
        "releaseId": "$releases[1]"
      }
      """
    And the current account has 1 "release-entitlement-constraint" with the following:
      """
      {
        "entitlementId": "$entitlements[1]",
        "releaseId": "$releases[1]"
      }
      """
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$0/actions/upgrade?channel=alpha"
    Then the response status should be "303"
    And the JSON response should be an "artifact"
    And the JSON response should contain meta which includes the following:
      """
      {
        "current": "1.0.0-alpha.1",
        "next": "1.0.0"
      }
      """

  Scenario: License retrieves an upgrade for a release of their product (missing some entitlements)
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name     |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test App |
    And the current account has the following "release" rows:
      | product_id                           | version      | filename                  | filetype | platform | channel  |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0        | Test-App-1.0.0.dmg        | dmg      | macos    | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0        | Test-App-2.0.0.dmg        | dmg      | macos    | stable   |
    And all "releases" have artifacts that are uploaded
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
        "entitlementId": "$entitlements[0]",
        "releaseId": "$releases[1]"
      }
      """
    And the current account has 1 "release-entitlement-constraint" with the following:
      """
      {
        "entitlementId": "$entitlements[1]",
        "releaseId": "$releases[1]"
      }
      """
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$0/actions/upgrade"
    Then the response status should be "204"

  Scenario: License retrieves an upgrade for a release of their product (missing all entitlements)
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name     |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test App |
    And the current account has the following "release" rows:
      | product_id                           | version      | filename                  | filetype | platform | channel  |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0        | Test-App-1.0.0.dmg        | dmg      | macos    | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0        | Test-App-2.0.0.dmg        | dmg      | macos    | stable   |
    And all "releases" have artifacts that are uploaded
    And the current account has 1 "policy" for an existing "product"
    And the current account has 1 "license" for an existing "policy"
    And the current account has 2 "release-entitlement-constraints" for the first "release"
    And the current account has 2 "release-entitlement-constraints" for the second "release"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$0/actions/upgrade"
    Then the response status should be "204"

  # Users
  Scenario: User retrieves an upgrade for a release of their product (upgrade available)
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name     |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test App |
    And the current account has the following "release" rows:
      | product_id                           | version      | filename                  | filetype | platform | channel  |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0        | Test-App-1.0.0.dmg        | dmg      | macos    | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.2.0        | Test-App-1.2.0.dmg        | dmg      | macos    | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.1        | Test-App-1.0.1.zip        | zip      | macos    | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.0        | Test-App-1.1.0.zip        | zip      | macos    | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.3.0        | Test-App-1.3.0.zip        | zip      | macos    | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0-beta.1 | Test-App-2.0.0-beta.1.zip | zip      | macos    | beta     |
    And all "releases" have artifacts that are uploaded
    And the current account has 1 "policy" for the first "product"
    And the current account has 1 "license" for the first "policy"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    And the current user has 1 "license"
    When I send a GET request to "/accounts/test1/releases/$2/actions/upgrade?channel=beta"
    Then the response status should be "303"
    And the JSON response should be an "artifact"
    And the JSON response should contain meta which includes the following:
      """
      {
        "current": "1.0.1",
        "next": "2.0.0-beta.1"
      }
      """

  Scenario: User retrieves an upgrade for a release of their product (expired)
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name     |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test App |
    And the current account has the following "release" rows:
      | product_id                           | version      | filename                  | filetype | platform | channel  |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0        | Test-App-1.0.0.dmg        | dmg      | macos    | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.2.0        | Test-App-1.2.0.dmg        | dmg      | macos    | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.1        | Test-App-1.0.1.zip        | zip      | macos    | stable   |
    And all "releases" have artifacts that are uploaded
    And the current account has 1 "policy" for the first "product"
    And the current account has 1 "license" for the first "policy"
    And the first "license" has the following attributes:
      """
      { "expiry": "$time.2.months.ago" }
      """
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    And the current user has 1 "license"
    When I send a GET request to "/accounts/test1/releases/$0/actions/upgrade"
    Then the response status should be "204"

  Scenario: User retrieves an upgrade for a release of their product (suspended)
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name     |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test App |
    And the current account has the following "release" rows:
      | product_id                           | version      | filename                  | filetype | platform | channel  |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0        | Test-App-1.0.0.exe        | exe      | win32    | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0        | Test-App-2.0.0.exe        | exe      | win32    | stable   |
    And all "releases" have artifacts that are uploaded
    And the current account has 1 "policy" for the first "product"
    And the current account has 1 "license" for the first "policy"
    And the first "license" has the following attributes:
      """
      { "suspended": true }
      """
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    And the current user has 1 "license"
    When I send a GET request to "/accounts/test1/releases/$0/actions/upgrade"
    Then the response status should be "204"

  Scenario: License retrieves an upgrade for a release of a different product
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name     |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test App |
    And the current account has the following "release" rows:
      | product_id                           | version      | filename                  | filetype | platform | channel  |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0        | Test-App-1.0.0.tar.gz     | tar.gz   | linux    | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.0        | Test-App-1.2.0.tar.gz     | tar.gz   | linux    | stable   |
    And all "releases" have artifacts that are uploaded
    And the current account has 1 "license"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    And the current user has 1 "license"
    When I send a GET request to "/accounts/test1/releases/$0/actions/upgrade"
    Then the response status should be "404"

  Scenario: User retrieves an upgrade for a release of their product (has single entitlement)
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name     |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test App |
    And the current account has the following "release" rows:
      | product_id                           | version      | filename                  | filetype | platform | channel  |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0        | Test-App-1.0.0.dmg        | dmg      | macos    | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.0        | Test-App-1.1.0.dmg        | dmg      | macos    | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.2.0        | Test-App-1.2.0.zip        | zip      | macos    | stable   |
    And all "releases" have artifacts that are uploaded
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
        "entitlementId": "$entitlements[0]",
        "releaseId": "$releases[1]"
      }
      """
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    And the current user has 1 "license"
    When I send a GET request to "/accounts/test1/releases/$0/actions/upgrade"
    Then the response status should be "303"
    And the JSON response should be an "artifact"
    And the JSON response should contain meta which includes the following:
      """
      {
        "current": "1.0.0",
        "next": "1.1.0"
      }
      """

  Scenario: User retrieves an upgrade for a release of their product (has multiple entitlements)
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name     |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test App |
    And the current account has the following "release" rows:
      | product_id                           | version       | filename                   | filetype | platform | channel  |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0-alpha.1 | Test-App-1.0.0-alpha.1.dmg | dmg      | macos    | alpha    |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0         | Test-App-1.0.0.dmg         | dmg      | macos    | stable   |
    And all "releases" have artifacts that are uploaded
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
        "entitlementId": "$entitlements[0]",
        "releaseId": "$releases[1]"
      }
      """
    And the current account has 1 "release-entitlement-constraint" with the following:
      """
      {
        "entitlementId": "$entitlements[1]",
        "releaseId": "$releases[1]"
      }
      """
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    And the current user has 1 "license"
    When I send a GET request to "/accounts/test1/releases/$0/actions/upgrade"
    Then the response status should be "303"
    And the JSON response should be an "artifact"
    And the JSON response should contain meta which includes the following:
      """
      {
        "current": "1.0.0-alpha.1",
        "next": "1.0.0"
      }
      """

  Scenario: User retrieves an upgrade for a release of their product (missing some entitlements)
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name     |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test App |
    And the current account has the following "release" rows:
      | product_id                           | version      | filename                  | filetype | platform | channel  |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0        | Test-App-1.0.0.dmg        | dmg      | macos    | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0        | Test-App-2.0.0.dmg        | dmg      | macos    | stable   |
    And all "releases" have artifacts that are uploaded
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
        "entitlementId": "$entitlements[0]",
        "releaseId": "$releases[1]"
      }
      """
    And the current account has 1 "release-entitlement-constraint" with the following:
      """
      {
        "entitlementId": "$entitlements[1]",
        "releaseId": "$releases[1]"
      }
      """
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    And the current user has 1 "license"
    When I send a GET request to "/accounts/test1/releases/$0/actions/upgrade"
    Then the response status should be "204"

  Scenario: User retrieves an upgrade for a release of their product (missing all entitlements)
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name     |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test App |
    And the current account has the following "release" rows:
      | product_id                           | version      | filename                  | filetype | platform | channel  |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0        | Test-App-1.0.0.dmg        | dmg      | macos    | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0        | Test-App-2.0.0.dmg        | dmg      | macos    | stable   |
    And all "releases" have artifacts that are uploaded
    And the current account has 1 "policy" for an existing "product"
    And the current account has 1 "license" for an existing "policy"
    And the current account has 2 "release-entitlement-constraints" for the first "release"
    And the current account has 2 "release-entitlement-constraints" for the second "release"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    And the current user has 1 "license"
    When I send a GET request to "/accounts/test1/releases/$0/actions/upgrade"
    Then the response status should be "204"

  # Upgrade by query
  Scenario: Admin retrieves an upgrade for a product release (upgrade available)
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name     |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test App |
    And the current account has the following "release" rows:
      | product_id                           | version      | filename                  | filetype | platform | channel  |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0        | Test-App-1.0.0.dmg        | dmg      | macos    | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.1        | Test-App-1.0.1.dmg        | dmg      | macos    | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.2        | Test-App-1.0.2.dmg        | dmg      | macos    | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.3        | Test-App-1.0.3.dmg        | dmg      | macos    | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.0        | Test-App-1.1.0.dmg        | dmg      | macos    | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.1        | Test-App-1.1.1.dmg        | dmg      | macos    | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.2        | Test-App-1.1.2.dmg        | dmg      | macos    | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.2.0        | Test-App-1.2.0.dmg        | dmg      | macos    | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.3.0        | Test-App-1.3.0.dmg        | dmg      | macos    | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.4.0        | Test-App-1.4.0.dmg        | dmg      | macos    | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.5.0        | Test-App-1.5.0.dmg        | dmg      | macos    | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.6.0        | Test-App-1.6.0.dmg        | dmg      | macos    | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.7.0        | Test-App-1.7.0.dmg        | dmg      | macos    | stable   |
    And all "releases" have artifacts that are uploaded
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/actions/upgrade?version=1.1.1&platform=macos&filetype=dmg&product=6198261a-48b5-4445-a045-9fed4afc7735"
    Then the response status should be "303"
    And the JSON response should be an "artifact"
    And the JSON response should contain meta which includes the following:
      """
      {
        "current": "1.1.1",
        "next": "1.7.0"
      }
      """

  Scenario: Admin retrieves an upgrade for a product release (unknown platform)
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name     |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test App |
    And the current account has the following "release" rows:
      | product_id                           | version      | filename                  | filetype | platform | channel  |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0        | Test-App-1.0.0.zip        | zip      | macos    | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.0        | Test-App-1.1.0.zip        | zip      | macos    | stable   |
    And all "releases" have artifacts that are uploaded
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/actions/upgrade?version=1.0.0&platform=win32&filetype=zip&product=6198261a-48b5-4445-a045-9fed4afc7735"
    Then the response status should be "204"

  Scenario: Admin retrieves an upgrade for a product release (unknown filetype)
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name     |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test App |
    And the current account has the following "release" rows:
      | product_id                           | version      | filename                  | filetype | platform | channel  |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0        | Test-App-1.0.0.zip        | zip      | macos    | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.0        | Test-App-1.1.0.zip        | zip      | macos    | stable   |
    And all "releases" have artifacts that are uploaded
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/actions/upgrade?version=1.0.0&platform=macos&filetype=dmg&product=6198261a-48b5-4445-a045-9fed4afc7735"
    Then the response status should be "204"

  Scenario: Admin retrieves an upgrade for a product release (unknown product)
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name     |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test App |
    And the current account has the following "release" rows:
      | product_id                           | version      | filename                  | filetype | platform | channel  |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0        | Test-App-1.0.0.zip        | zip      | macos    | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.0        | Test-App-1.1.0.zip        | zip      | macos    | stable   |
    And all "releases" have artifacts that are uploaded
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/actions/upgrade?version=1.0.0&platform=macos&filetype=zip&product=4f1c06e0-a4b2-4e3e-8a19-f2ce7f2f6e62"
    Then the response status should be "204"

  Scenario: Admin retrieves an upgrade for a product release (constrained to v1.x)
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name     |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test App |
    And the current account has the following "release" rows:
      | product_id                           | version      | filename                  | filetype | platform | channel  |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0        | Test-App-1.0.0.zip        | zip      | macos    | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.1        | Test-App-1.0.1.zip        | zip      | macos    | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.0        | Test-App-1.1.0.zip        | zip      | macos    | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0        | Test-App-2.0.0.zip        | zip      | macos    | stable   |
    And all "releases" have artifacts that are uploaded
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/actions/upgrade?version=1.0.0&constraint=1.0&platform=macos&filetype=zip&product=6198261a-48b5-4445-a045-9fed4afc7735"
    Then the response status should be "303"
    And the JSON response should be an "artifact"
    And the JSON response should contain meta which includes the following:
      """
      {
        "current": "1.0.0",
        "next": "1.1.0"
      }
      """

  Scenario: Admin retrieves an upgrade for a product release (constrained to v2.x)
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name     |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test App |
    And the current account has the following "release" rows:
      | product_id                           | version      | filename                  | filetype | platform | channel  |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0        | Test-App-1.0.0.zip        | zip      | macos    | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.0        | Test-App-1.1.0.zip        | zip      | macos    | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0        | Test-App-2.0.0.zip        | zip      | macos    | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 3.0.0        | Test-App-3.0.0.zip        | zip      | macos    | stable   |
    And all "releases" have artifacts that are uploaded
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/actions/upgrade?version=1.0.0&constraint=2.0&platform=macos&filetype=zip&product=6198261a-48b5-4445-a045-9fed4afc7735"
    Then the response status should be "303"
    And the JSON response should be an "artifact"
    And the JSON response should contain meta which includes the following:
      """
      {
        "current": "1.0.0",
        "next": "2.0.0"
      }
      """

  # Entitlements
  Scenario: License retrieves an upgrade for a product release (has v2 entitlement)
    Given the current account is "test1"
    And the current account has the following "entitlement" rows:
      | id                                   | code     |
      | 8cdf47c8-9cdc-44c9-a752-1e137355ecaf | APP_V1   |
      | ac1f0d43-383a-4cbf-8d42-91e7820f4c61 | APP_V2   |
    And the current account has the following "product" rows:
      | id                                   | name     |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test App |
    And the current account has the following "release" rows:
      | product_id                           | version      | filename                  | filetype | platform | channel  | entitlements |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0        | Test-App-1.0.0.dmg        | dmg      | macos    | stable   | APP_V1       |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.1        | Test-App-1.0.1.dmg        | dmg      | macos    | stable   | APP_V1       |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.2        | Test-App-1.0.2.dmg        | dmg      | macos    | stable   | APP_V1       |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.3        | Test-App-1.0.3.dmg        | dmg      | macos    | stable   | APP_V1       |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.0        | Test-App-1.1.0.dmg        | dmg      | macos    | stable   | APP_V1       |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.1        | Test-App-1.1.1.dmg        | dmg      | macos    | stable   | APP_V1       |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.2        | Test-App-1.1.2.dmg        | dmg      | macos    | stable   | APP_V1       |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.2.0        | Test-App-1.2.0.dmg        | dmg      | macos    | stable   | APP_V1       |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.3.0        | Test-App-1.3.0.dmg        | dmg      | macos    | stable   | APP_V1       |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.4.0        | Test-App-1.4.0.dmg        | dmg      | macos    | stable   | APP_V1       |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.5.0        | Test-App-1.5.0.dmg        | dmg      | macos    | stable   | APP_V1       |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.6.0        | Test-App-1.6.0.dmg        | dmg      | macos    | stable   | APP_V1       |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.7.0        | Test-App-1.7.0.dmg        | dmg      | macos    | stable   | APP_V1       |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0        | Test-App-2.0.0.dmg        | dmg      | macos    | stable   | APP_V2       |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.1        | Test-App-2.0.1.dmg        | dmg      | macos    | stable   | APP_V2       |
    And all "releases" have artifacts that are uploaded
    And the current account has 1 "policy" for an existing "product"
    And the current account has 1 "license" for an existing "policy"
    And the current account has 1 "license-entitlement" with the following:
      """
      {
        "entitlementId": "8cdf47c8-9cdc-44c9-a752-1e137355ecaf",
        "licenseId": "$licenses[0]"
      }
      """
    And the current account has 1 "license-entitlement" with the following:
      """
      {
        "entitlementId": "ac1f0d43-383a-4cbf-8d42-91e7820f4c61",
        "licenseId": "$licenses[0]"
      }
      """
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/actions/upgrade?version=1.0.0&constraint=2.0&platform=macos&filetype=dmg&product=6198261a-48b5-4445-a045-9fed4afc7735"
    Then the response status should be "303"
    And the JSON response should be an "artifact"
    And the JSON response should contain meta which includes the following:
      """
      {
        "current": "1.0.0",
        "next": "2.0.1"
      }
      """

  Scenario: License retrieves an upgrade for a product release (missing v2 entitlement)
    Given the current account is "test1"
    And the current account has the following "entitlement" rows:
      | id                                   | code     |
      | 8cdf47c8-9cdc-44c9-a752-1e137355ecaf | APP_V1   |
      | ac1f0d43-383a-4cbf-8d42-91e7820f4c61 | APP_V2   |
    And the current account has the following "product" rows:
      | id                                   | name     |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test App |
    And the current account has the following "release" rows:
      | product_id                           | version      | filename                  | filetype | platform | channel  | entitlements |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0        | Test-App-1.0.0.dmg        | dmg      | macos    | stable   | APP_V1       |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.1        | Test-App-1.0.1.dmg        | dmg      | macos    | stable   | APP_V1       |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.2        | Test-App-1.0.2.dmg        | dmg      | macos    | stable   | APP_V1       |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.3        | Test-App-1.0.3.dmg        | dmg      | macos    | stable   | APP_V1       |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.0        | Test-App-1.1.0.dmg        | dmg      | macos    | stable   | APP_V1       |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.1        | Test-App-1.1.1.dmg        | dmg      | macos    | stable   | APP_V1       |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.2        | Test-App-1.1.2.dmg        | dmg      | macos    | stable   | APP_V1       |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.2.0        | Test-App-1.2.0.dmg        | dmg      | macos    | stable   | APP_V1       |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.3.0        | Test-App-1.3.0.dmg        | dmg      | macos    | stable   | APP_V1       |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.4.0        | Test-App-1.4.0.dmg        | dmg      | macos    | stable   | APP_V1       |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.5.0        | Test-App-1.5.0.dmg        | dmg      | macos    | stable   | APP_V1       |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.6.0        | Test-App-1.6.0.dmg        | dmg      | macos    | stable   | APP_V1       |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.7.0        | Test-App-1.7.0.dmg        | dmg      | macos    | stable   | APP_V1       |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0        | Test-App-2.0.0.dmg        | dmg      | macos    | stable   | APP_V2       |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.1        | Test-App-2.0.1.dmg        | dmg      | macos    | stable   | APP_V2       |
    And all "releases" have artifacts that are uploaded
    And the current account has 1 "policy" for an existing "product"
    And the current account has 1 "license" for an existing "policy"
    And the current account has 1 "license-entitlement" with the following:
      """
      {
        "entitlementId": "8cdf47c8-9cdc-44c9-a752-1e137355ecaf",
        "licenseId": "$licenses[0]"
      }
      """
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/actions/upgrade?version=1.0.0&constraint=2.0&platform=macos&filetype=dmg&product=6198261a-48b5-4445-a045-9fed4afc7735"
    Then the response status should be "204"

  Scenario: License retrieves an upgrade for a product release (missing v2 entitlement, constrained to v1)
    Given the current account is "test1"
    And the current account has the following "entitlement" rows:
      | id                                   | code     |
      | 8cdf47c8-9cdc-44c9-a752-1e137355ecaf | APP_V1   |
      | ac1f0d43-383a-4cbf-8d42-91e7820f4c61 | APP_V2   |
    And the current account has the following "product" rows:
      | id                                   | name     |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test App |
    And the current account has the following "release" rows:
      | product_id                           | version      | filename                  | filetype | platform | channel  | entitlements |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0        | Test-App-1.0.0.dmg        | dmg      | macos    | stable   | APP_V1       |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.1        | Test-App-1.0.1.dmg        | dmg      | macos    | stable   | APP_V1       |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.2        | Test-App-1.0.2.dmg        | dmg      | macos    | stable   | APP_V1       |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.3        | Test-App-1.0.3.dmg        | dmg      | macos    | stable   | APP_V1       |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.0        | Test-App-1.1.0.dmg        | dmg      | macos    | stable   | APP_V1       |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.1        | Test-App-1.1.1.dmg        | dmg      | macos    | stable   | APP_V1       |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.2        | Test-App-1.1.2.dmg        | dmg      | macos    | stable   | APP_V1       |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.2.0        | Test-App-1.2.0.dmg        | dmg      | macos    | stable   | APP_V1       |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.3.0        | Test-App-1.3.0.dmg        | dmg      | macos    | stable   | APP_V1       |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.4.0        | Test-App-1.4.0.dmg        | dmg      | macos    | stable   | APP_V1       |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.5.0        | Test-App-1.5.0.dmg        | dmg      | macos    | stable   | APP_V1       |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.6.0        | Test-App-1.6.0.dmg        | dmg      | macos    | stable   | APP_V1       |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.7.0        | Test-App-1.7.0.dmg        | dmg      | macos    | stable   | APP_V1       |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0        | Test-App-2.0.0.dmg        | dmg      | macos    | stable   | APP_V2       |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.1        | Test-App-2.0.1.dmg        | dmg      | macos    | stable   | APP_V2       |
    And all "releases" have artifacts that are uploaded
    And the current account has 1 "policy" for an existing "product"
    And the current account has 1 "license" for an existing "policy"
    And the current account has 1 "license-entitlement" with the following:
      """
      {
        "entitlementId": "8cdf47c8-9cdc-44c9-a752-1e137355ecaf",
        "licenseId": "$licenses[0]"
      }
      """
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/actions/upgrade?version=1.0.0&constraint=1.0&platform=macos&filetype=dmg&product=6198261a-48b5-4445-a045-9fed4afc7735"
    Then the response status should be "303"
    And the JSON response should be an "artifact"
    And the JSON response should contain meta which includes the following:
      """
      {
        "current": "1.0.0",
        "next": "1.7.0"
      }
      """

  # Pre-releases
  Scenario: License retrieves an upgrade for a product release (stable channel)
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name     |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test App |
    And the current account has the following "release" rows:
      | product_id                           | version                    | filename                   | filetype | platform | channel  |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0-alpha.1              | Test-App-1.0.0-alpha.1.dmg | dmg      | darwin   | alpha    |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0                      | Test-App-1.0.0.dmg         | dmg      | darwin   | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.1                      | Test-App-1.0.1.dmg         | dmg      | darwin   | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.2                      | Test-App-1.0.2.dmg         | dmg      | darwin   | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.3                      | Test-App-1.0.3.dmg         | dmg      | darwin   | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.0                      | Test-App-1.1.0.dmg         | dmg      | darwin   | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.1                      | Test-App-1.1.1.dmg         | dmg      | darwin   | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.2                      | Test-App-1.1.2.dmg         | dmg      | darwin   | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.2.0                      | Test-App-1.2.0.dmg         | dmg      | darwin   | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.3.0                      | Test-App-1.3.0.dmg         | dmg      | darwin   | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.4.0-beta.1               | Test-App-1.4.0-beta.1.dmg  | dmg      | darwin   | beta     |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.4.0-beta.2               | Test-App-1.4.0-beta.2.dmg  | dmg      | darwin   | beta     |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.4.0-beta.3               | Test-App-1.4.0-beta.3.dmg  | dmg      | darwin   | beta     |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.4.0                      | Test-App-1.4.0.dmg         | dmg      | darwin   | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.5.0                      | Test-App-1.5.0.dmg         | dmg      | darwin   | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.6.0                      | Test-App-1.6.0.dmg         | dmg      | darwin   | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.7.0-dev+build.1624653614 | Test-App-1624653614.dmg    | dmg      | darwin   | dev      |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.7.0                      | Test-App-1.7.0.dmg         | dmg      | darwin   | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0-dev+build.1624653627 | Test-App-1624653627.dmg    | dmg      | darwin   | dev      |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0-dev+build.1624653693 | Test-App-1624653693.dmg    | dmg      | darwin   | dev      |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0-dev+build.1624653702 | Test-App-1624653702.dmg    | dmg      | darwin   | dev      |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0-dev+build.1624653708 | Test-App-1624653708.dmg    | dmg      | darwin   | dev      |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0-dev+build.1624653716 | Test-App-1624653716.dmg    | dmg      | darwin   | dev      |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0-alpha.1              | Test-App-2.0.0-alpha.1.dmg | dmg      | darwin   | alpha    |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0-alpha.2              | Test-App-2.0.0-alpha.2.dmg | dmg      | darwin   | alpha    |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0-beta.1               | Test-App-2.0.0-beta.1.dmg  | dmg      | darwin   | beta     |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0-beta.2               | Test-App-2.0.0-beta.2.dmg  | dmg      | darwin   | beta     |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0-beta.3               | Test-App-2.0.0-beta.3.dmg  | dmg      | darwin   | beta     |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0-rc.1                 | Test-App-2.0.0-rc.1.dmg    | dmg      | darwin   | rc       |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0                      | Test-App-2.0.0.dmg         | dmg      | darwin   | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.1-dev+build.1624653735 | Test-App-1624653735.dmg    | dmg      | darwin   | dev      |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.1-dev+build.1624653760 | Test-App-1624653760.dmg    | dmg      | darwin   | dev      |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.1-rc.1                 | Test-App-2.0.1-rc.1.dmg    | dmg      | darwin   | rc       |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.1                      | Test-App-2.0.1.dmg         | dmg      | darwin   | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.2-dev+build.1624653771 | Test-App-1624653771.dmg    | dmg      | darwin   | dev      |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.2-alpha.1              | Test-App-2.0.2-alpha.1.dmg | dmg      | darwin   | alpha    |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.2-beta.1               | Test-App-2.0.2-beta.1.dmg  | dmg      | darwin   | beta     |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.3-alpha.1              | Test-App-2.0.3-alpha.1.dmg | dmg      | darwin   | alpha    |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.1.0-dev+build.1624654615 | Test-App-1624654615.dmg    | dmg      | darwin   | dev      |
    And all "releases" have artifacts that are uploaded
    And the current account has 1 "policy" for the first "product"
    And the current account has 1 "license" for the first "policy"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/actions/upgrade?version=1.6.0&channel=stable&platform=darwin&filetype=dmg&product=6198261a-48b5-4445-a045-9fed4afc7735"
    Then the response status should be "303"
    And the JSON response should be an "artifact"
    And the JSON response should contain meta which includes the following:
      """
      {
        "current": "1.6.0",
        "next": "2.0.1"
      }
      """

  Scenario: License retrieves an upgrade for a product release (rc channel)
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name     |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test App |
    And the current account has the following "release" rows:
      | product_id                           | version                    | filename                   | filetype | platform | channel  |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0-alpha.1              | Test-App-1.0.0-alpha.1.dmg | dmg      | darwin   | alpha    |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0                      | Test-App-1.0.0.dmg         | dmg      | darwin   | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.1                      | Test-App-1.0.1.dmg         | dmg      | darwin   | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.2                      | Test-App-1.0.2.dmg         | dmg      | darwin   | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.3                      | Test-App-1.0.3.dmg         | dmg      | darwin   | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.0                      | Test-App-1.1.0.dmg         | dmg      | darwin   | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.1                      | Test-App-1.1.1.dmg         | dmg      | darwin   | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.2                      | Test-App-1.1.2.dmg         | dmg      | darwin   | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.2.0                      | Test-App-1.2.0.dmg         | dmg      | darwin   | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.3.0                      | Test-App-1.3.0.dmg         | dmg      | darwin   | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.4.0-beta.1               | Test-App-1.4.0-beta.1.dmg  | dmg      | darwin   | beta     |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.4.0-beta.2               | Test-App-1.4.0-beta.2.dmg  | dmg      | darwin   | beta     |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.4.0-beta.3               | Test-App-1.4.0-beta.3.dmg  | dmg      | darwin   | beta     |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.4.0                      | Test-App-1.4.0.dmg         | dmg      | darwin   | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.5.0                      | Test-App-1.5.0.dmg         | dmg      | darwin   | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.6.0                      | Test-App-1.6.0.dmg         | dmg      | darwin   | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.7.0-dev+build.1624653614 | Test-App-1624653614.dmg    | dmg      | darwin   | dev      |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.7.0                      | Test-App-1.7.0.dmg         | dmg      | darwin   | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0-dev+build.1624653627 | Test-App-1624653627.dmg    | dmg      | darwin   | dev      |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0-dev+build.1624653693 | Test-App-1624653693.dmg    | dmg      | darwin   | dev      |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0-dev+build.1624653702 | Test-App-1624653702.dmg    | dmg      | darwin   | dev      |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0-dev+build.1624653708 | Test-App-1624653708.dmg    | dmg      | darwin   | dev      |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0-dev+build.1624653716 | Test-App-1624653716.dmg    | dmg      | darwin   | dev      |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0-alpha.1              | Test-App-2.0.0-alpha.1.dmg | dmg      | darwin   | alpha    |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0-alpha.2              | Test-App-2.0.0-alpha.2.dmg | dmg      | darwin   | alpha    |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0-beta.1               | Test-App-2.0.0-beta.1.dmg  | dmg      | darwin   | beta     |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0-beta.2               | Test-App-2.0.0-beta.2.dmg  | dmg      | darwin   | beta     |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0-beta.3               | Test-App-2.0.0-beta.3.dmg  | dmg      | darwin   | beta     |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0-rc.1                 | Test-App-2.0.0-rc.1.dmg    | dmg      | darwin   | rc       |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0                      | Test-App-2.0.0.dmg         | dmg      | darwin   | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.1-dev+build.1624653735 | Test-App-1624653735.dmg    | dmg      | darwin   | dev      |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.1-dev+build.1624653760 | Test-App-1624653760.dmg    | dmg      | darwin   | dev      |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.1-rc.1                 | Test-App-2.0.1-rc.1.dmg    | dmg      | darwin   | rc       |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.1                      | Test-App-2.0.1.dmg         | dmg      | darwin   | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.2-dev+build.1624653771 | Test-App-1624653771.dmg    | dmg      | darwin   | dev      |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.2-alpha.1              | Test-App-2.0.2-alpha.1.dmg | dmg      | darwin   | alpha    |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.2-beta.1               | Test-App-2.0.2-beta.1.dmg  | dmg      | darwin   | beta     |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.3-alpha.1              | Test-App-2.0.3-alpha.1.dmg | dmg      | darwin   | alpha    |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.1.0-dev+build.1624654615 | Test-App-1624654615.dmg    | dmg      | darwin   | dev      |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.1.0-beta.1               | Test-App-2.1.0-beta.1.dmg  | dmg      | darwin   | beta     |
    And all "releases" have artifacts that are uploaded
    And the current account has 1 "policy" for the first "product"
    And the current account has 1 "license" for the first "policy"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/actions/upgrade?version=1.0.0-dev%2bbuild.0&channel=rc&platform=darwin&filetype=dmg&product=6198261a-48b5-4445-a045-9fed4afc7735"
    Then the response status should be "303"
    And the JSON response should be an "artifact"
    And the JSON response should contain meta which includes the following:
      """
      {
        "current": "1.0.0-dev+build.0",
        "next": "2.0.1"
      }
      """

  Scenario: License retrieves an upgrade for a product release (beta channel)
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name     |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test App |
    And the current account has the following "release" rows:
      | product_id                           | version                    | filename                   | filetype | platform | channel  |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0-alpha.1              | Test-App-1.0.0-alpha.1.dmg | dmg      | darwin   | alpha    |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0                      | Test-App-1.0.0.dmg         | dmg      | darwin   | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.1                      | Test-App-1.0.1.dmg         | dmg      | darwin   | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.2                      | Test-App-1.0.2.dmg         | dmg      | darwin   | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.3                      | Test-App-1.0.3.dmg         | dmg      | darwin   | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.0                      | Test-App-1.1.0.dmg         | dmg      | darwin   | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.1                      | Test-App-1.1.1.dmg         | dmg      | darwin   | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.2                      | Test-App-1.1.2.dmg         | dmg      | darwin   | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.2.0                      | Test-App-1.2.0.dmg         | dmg      | darwin   | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.3.0                      | Test-App-1.3.0.dmg         | dmg      | darwin   | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.4.0-beta.1               | Test-App-1.4.0-beta.1.dmg  | dmg      | darwin   | beta     |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.4.0-beta.2               | Test-App-1.4.0-beta.2.dmg  | dmg      | darwin   | beta     |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.4.0-beta.3               | Test-App-1.4.0-beta.3.dmg  | dmg      | darwin   | beta     |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.4.0                      | Test-App-1.4.0.dmg         | dmg      | darwin   | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.5.0                      | Test-App-1.5.0.dmg         | dmg      | darwin   | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.6.0                      | Test-App-1.6.0.dmg         | dmg      | darwin   | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.7.0-dev+build.1624653614 | Test-App-1624653614.dmg    | dmg      | darwin   | dev      |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.7.0                      | Test-App-1.7.0.dmg         | dmg      | darwin   | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0-dev+build.1624653627 | Test-App-1624653627.dmg    | dmg      | darwin   | dev      |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0-dev+build.1624653693 | Test-App-1624653693.dmg    | dmg      | darwin   | dev      |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0-dev+build.1624653702 | Test-App-1624653702.dmg    | dmg      | darwin   | dev      |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0-dev+build.1624653708 | Test-App-1624653708.dmg    | dmg      | darwin   | dev      |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0-dev+build.1624653716 | Test-App-1624653716.dmg    | dmg      | darwin   | dev      |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0-alpha.1              | Test-App-2.0.0-alpha.1.dmg | dmg      | darwin   | alpha    |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0-alpha.2              | Test-App-2.0.0-alpha.2.dmg | dmg      | darwin   | alpha    |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0-beta.1               | Test-App-2.0.0-beta.1.dmg  | dmg      | darwin   | beta     |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0-beta.2               | Test-App-2.0.0-beta.2.dmg  | dmg      | darwin   | beta     |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0-beta.3               | Test-App-2.0.0-beta.3.dmg  | dmg      | darwin   | beta     |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0-rc.1                 | Test-App-2.0.0-rc.1.dmg    | dmg      | darwin   | rc       |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0                      | Test-App-2.0.0.dmg         | dmg      | darwin   | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.1-dev+build.1624653735 | Test-App-1624653735.dmg    | dmg      | darwin   | dev      |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.1-dev+build.1624653760 | Test-App-1624653760.dmg    | dmg      | darwin   | dev      |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.1-rc.1                 | Test-App-2.0.1-rc.1.dmg    | dmg      | darwin   | rc       |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.1                      | Test-App-2.0.1.dmg         | dmg      | darwin   | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.2-dev+build.1624653771 | Test-App-1624653771.dmg    | dmg      | darwin   | dev      |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.2-alpha.1              | Test-App-2.0.2-alpha.1.dmg | dmg      | darwin   | alpha    |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.2-beta.1               | Test-App-2.0.2-beta.1.dmg  | dmg      | darwin   | beta     |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.3-alpha.1              | Test-App-2.0.3-alpha.1.dmg | dmg      | darwin   | alpha    |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.1.0-dev+build.1624654615 | Test-App-1624654615.dmg    | dmg      | darwin   | dev      |
    And all "releases" have artifacts that are uploaded
    And the current account has 1 "policy" for the first "product"
    And the current account has 1 "license" for the first "policy"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/actions/upgrade?version=2.0.0&channel=beta&platform=darwin&filetype=dmg&product=6198261a-48b5-4445-a045-9fed4afc7735"
    Then the response status should be "303"
    And the JSON response should be an "artifact"
    And the JSON response should contain meta which includes the following:
      """
      {
        "current": "2.0.0",
        "next": "2.0.2-beta.1"
      }
      """

  Scenario: License retrieves an upgrade for a product release (alpha channel)
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name     |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test App |
    And the current account has the following "release" rows:
      | product_id                           | version                    | filename                   | filetype | platform | channel  |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0-alpha.1              | Test-App-1.0.0-alpha.1.dmg | dmg      | darwin   | alpha    |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0                      | Test-App-1.0.0.dmg         | dmg      | darwin   | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.1                      | Test-App-1.0.1.dmg         | dmg      | darwin   | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.2                      | Test-App-1.0.2.dmg         | dmg      | darwin   | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.3                      | Test-App-1.0.3.dmg         | dmg      | darwin   | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.0                      | Test-App-1.1.0.dmg         | dmg      | darwin   | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.1                      | Test-App-1.1.1.dmg         | dmg      | darwin   | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.2                      | Test-App-1.1.2.dmg         | dmg      | darwin   | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.2.0                      | Test-App-1.2.0.dmg         | dmg      | darwin   | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.3.0                      | Test-App-1.3.0.dmg         | dmg      | darwin   | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.4.0-beta.1               | Test-App-1.4.0-beta.1.dmg  | dmg      | darwin   | beta     |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.4.0-beta.2               | Test-App-1.4.0-beta.2.dmg  | dmg      | darwin   | beta     |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.4.0-beta.3               | Test-App-1.4.0-beta.3.dmg  | dmg      | darwin   | beta     |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.4.0                      | Test-App-1.4.0.dmg         | dmg      | darwin   | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.5.0                      | Test-App-1.5.0.dmg         | dmg      | darwin   | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.6.0                      | Test-App-1.6.0.dmg         | dmg      | darwin   | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.7.0-dev+build.1624653614 | Test-App-1624653614.dmg    | dmg      | darwin   | dev      |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.7.0                      | Test-App-1.7.0.dmg         | dmg      | darwin   | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0-dev+build.1624653627 | Test-App-1624653627.dmg    | dmg      | darwin   | dev      |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0-dev+build.1624653693 | Test-App-1624653693.dmg    | dmg      | darwin   | dev      |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0-dev+build.1624653702 | Test-App-1624653702.dmg    | dmg      | darwin   | dev      |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0-dev+build.1624653708 | Test-App-1624653708.dmg    | dmg      | darwin   | dev      |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0-dev+build.1624653716 | Test-App-1624653716.dmg    | dmg      | darwin   | dev      |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0-alpha.1              | Test-App-2.0.0-alpha.1.dmg | dmg      | darwin   | alpha    |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0-alpha.2              | Test-App-2.0.0-alpha.2.dmg | dmg      | darwin   | alpha    |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0-beta.1               | Test-App-2.0.0-beta.1.dmg  | dmg      | darwin   | beta     |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0-beta.2               | Test-App-2.0.0-beta.2.dmg  | dmg      | darwin   | beta     |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0-beta.3               | Test-App-2.0.0-beta.3.dmg  | dmg      | darwin   | beta     |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0-rc.1                 | Test-App-2.0.0-rc.1.dmg    | dmg      | darwin   | rc       |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0                      | Test-App-2.0.0.dmg         | dmg      | darwin   | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.1-dev+build.1624653735 | Test-App-1624653735.dmg    | dmg      | darwin   | dev      |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.1-dev+build.1624653760 | Test-App-1624653760.dmg    | dmg      | darwin   | dev      |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.1-rc.1                 | Test-App-2.0.1-rc.1.dmg    | dmg      | darwin   | rc       |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.1                      | Test-App-2.0.1.dmg         | dmg      | darwin   | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.2-dev+build.1624653771 | Test-App-1624653771.dmg    | dmg      | darwin   | dev      |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.2-alpha.1              | Test-App-2.0.2-alpha.1.dmg | dmg      | darwin   | alpha    |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.2-beta.1               | Test-App-2.0.2-beta.1.dmg  | dmg      | darwin   | beta     |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.3-alpha.1              | Test-App-2.0.3-alpha.1.dmg | dmg      | darwin   | alpha    |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.1.0-dev+build.1624654615 | Test-App-1624654615.dmg    | dmg      | darwin   | dev      |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.1.0-beta.1               | Test-App-2.1.0-beta.1.dmg  | dmg      | darwin   | beta     |
    And all "releases" have artifacts that are uploaded
    And the current account has 1 "policy" for the first "product"
    And the current account has 1 "license" for the first "policy"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/actions/upgrade?version=1.0.0-alpha.1&channel=alpha&platform=darwin&filetype=dmg&product=6198261a-48b5-4445-a045-9fed4afc7735"
    Then the response status should be "303"
    And the JSON response should be an "artifact"
    And the JSON response should contain meta which includes the following:
      """
      {
        "current": "1.0.0-alpha.1",
        "next": "2.1.0-beta.1"
      }
      """

  Scenario: License retrieves an upgrade for a product release (dev channel)
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name     |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test App |
    And the current account has the following "release" rows:
      | product_id                           | version                    | filename                   | filetype | platform | channel  |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0-alpha.1              | Test-App-1.0.0-alpha.1.dmg | dmg      | darwin   | alpha    |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0                      | Test-App-1.0.0.dmg         | dmg      | darwin   | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.1                      | Test-App-1.0.1.dmg         | dmg      | darwin   | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.2                      | Test-App-1.0.2.dmg         | dmg      | darwin   | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.3                      | Test-App-1.0.3.dmg         | dmg      | darwin   | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.0                      | Test-App-1.1.0.dmg         | dmg      | darwin   | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.1                      | Test-App-1.1.1.dmg         | dmg      | darwin   | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.2                      | Test-App-1.1.2.dmg         | dmg      | darwin   | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.2.0                      | Test-App-1.2.0.dmg         | dmg      | darwin   | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.3.0                      | Test-App-1.3.0.dmg         | dmg      | darwin   | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.4.0-beta.1               | Test-App-1.4.0-beta.1.dmg  | dmg      | darwin   | beta     |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.4.0-beta.2               | Test-App-1.4.0-beta.2.dmg  | dmg      | darwin   | beta     |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.4.0-beta.3               | Test-App-1.4.0-beta.3.dmg  | dmg      | darwin   | beta     |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.4.0                      | Test-App-1.4.0.dmg         | dmg      | darwin   | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.5.0                      | Test-App-1.5.0.dmg         | dmg      | darwin   | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.6.0                      | Test-App-1.6.0.dmg         | dmg      | darwin   | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.7.0-dev+build.1624653614 | Test-App-1624653614.dmg    | dmg      | darwin   | dev      |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.7.0                      | Test-App-1.7.0.dmg         | dmg      | darwin   | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0-dev+build.1624653627 | Test-App-1624653627.dmg    | dmg      | darwin   | dev      |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0-dev+build.1624653693 | Test-App-1624653693.dmg    | dmg      | darwin   | dev      |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0-dev+build.1624653702 | Test-App-1624653702.dmg    | dmg      | darwin   | dev      |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0-dev+build.1624653708 | Test-App-1624653708.dmg    | dmg      | darwin   | dev      |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0-dev+build.1624653716 | Test-App-1624653716.dmg    | dmg      | darwin   | dev      |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0-alpha.1              | Test-App-2.0.0-alpha.1.dmg | dmg      | darwin   | alpha    |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0-alpha.2              | Test-App-2.0.0-alpha.2.dmg | dmg      | darwin   | alpha    |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0-beta.1               | Test-App-2.0.0-beta.1.dmg  | dmg      | darwin   | beta     |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0-beta.2               | Test-App-2.0.0-beta.2.dmg  | dmg      | darwin   | beta     |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0-beta.3               | Test-App-2.0.0-beta.3.dmg  | dmg      | darwin   | beta     |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0-rc.1                 | Test-App-2.0.0-rc.1.dmg    | dmg      | darwin   | rc       |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0                      | Test-App-2.0.0.dmg         | dmg      | darwin   | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.1-dev+build.1624653735 | Test-App-1624653735.dmg    | dmg      | darwin   | dev      |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.1-dev+build.1624653760 | Test-App-1624653760.dmg    | dmg      | darwin   | dev      |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.1-rc.1                 | Test-App-2.0.1-rc.1.dmg    | dmg      | darwin   | rc       |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.1                      | Test-App-2.0.1.dmg         | dmg      | darwin   | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.2-dev+build.1624653771 | Test-App-1624653771.dmg    | dmg      | darwin   | dev      |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.2-alpha.1              | Test-App-2.0.2-alpha.1.dmg | dmg      | darwin   | alpha    |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.2-beta.1               | Test-App-2.0.2-beta.1.dmg  | dmg      | darwin   | beta     |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.3-alpha.1              | Test-App-2.0.3-alpha.1.dmg | dmg      | darwin   | alpha    |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.1.0-dev+build.1624654615 | Test-App-1624654615.dmg    | dmg      | darwin   | dev      |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.1.0-beta.1               | Test-App-2.1.0-beta.1.dmg  | dmg      | darwin   | beta     |
    And all "releases" have artifacts that are uploaded
    And the current account has 1 "policy" for the first "product"
    And the current account has 1 "license" for the first "policy"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/actions/upgrade?version=1.7.0-dev%2bbuild.1624653614&channel=dev&platform=darwin&filetype=dmg&product=6198261a-48b5-4445-a045-9fed4afc7735"
    Then the response status should be "303"
    And the JSON response should be an "artifact"
    And the JSON response should contain meta which includes the following:
      """
      {
        "current": "1.7.0-dev+build.1624653614",
        "next": "2.1.0-dev+build.1624654615"
      }
      """

  # Licensed distribution strategy
  Scenario: License retrieves an upgrade for a product release (LICENSED distribution strategy)
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name     | distributionStrategy |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test App | LICENSED             |
    And the current account has the following "release" rows:
      | product_id                           | version | filename           | filetype | platform | channel |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0   | Test-App-1.0.0.dmg | dmg      | darwin   | stable  |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.1   | Test-App-1.0.1.dmg | dmg      | darwin   | stable  |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.2   | Test-App-1.0.2.dmg | dmg      | darwin   | stable  |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.3   | Test-App-1.0.3.dmg | dmg      | darwin   | stable  |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.0   | Test-App-1.1.0.dmg | dmg      | darwin   | stable  |
    And all "releases" have artifacts that are uploaded
    And the current account has 1 "policy" for the first "product"
    And the current account has 1 "license" for the first "policy"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/actions/upgrade?version=1.0.2&channel=stable&platform=darwin&filetype=dmg&product=6198261a-48b5-4445-a045-9fed4afc7735"
    Then the response status should be "303"
    And the JSON response should be an "artifact"
    And the JSON response should contain meta which includes the following:
      """
      {
        "current": "1.0.2",
        "next": "1.1.0"
      }
      """

  Scenario: User retrieves an upgrade for a product release (LICENSED distribution strategy)
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name     | distributionStrategy |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test App | LICENSED             |
    And the current account has the following "release" rows:
      | product_id                           | version | filename           | filetype | platform | channel |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0   | Test-App-1.0.0.dmg | dmg      | darwin   | stable  |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.1   | Test-App-1.0.1.dmg | dmg      | darwin   | stable  |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.2   | Test-App-1.0.2.dmg | dmg      | darwin   | stable  |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.3   | Test-App-1.0.3.dmg | dmg      | darwin   | stable  |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.0   | Test-App-1.1.0.dmg | dmg      | darwin   | stable  |
    And all "releases" have artifacts that are uploaded
    And the current account has 1 "policy" for an existing "product"
    And the current account has 1 "license" for an existing "policy"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    And the current user has 1 "license"
    When I send a GET request to "/accounts/test1/releases/actions/upgrade?version=1.0.2&channel=stable&platform=darwin&filetype=dmg&product=6198261a-48b5-4445-a045-9fed4afc7735"
    Then the response status should be "303"
    And the JSON response should be an "artifact"
    And the JSON response should contain meta which includes the following:
      """
      {
        "current": "1.0.2",
        "next": "1.1.0"
      }
      """

  Scenario: Anonymous retrieves an upgrade for a product release (LICENSED distribution strategy)
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name     | distributionStrategy |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test App | LICENSED             |
    And the current account has the following "release" rows:
      | product_id                           | version | filename           | filetype | platform | channel |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0   | Test-App-1.0.0.dmg | dmg      | darwin   | stable  |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.1   | Test-App-1.0.1.dmg | dmg      | darwin   | stable  |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.2   | Test-App-1.0.2.dmg | dmg      | darwin   | stable  |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.3   | Test-App-1.0.3.dmg | dmg      | darwin   | stable  |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.0   | Test-App-1.1.0.dmg | dmg      | darwin   | stable  |
    And all "releases" have artifacts that are uploaded
    When I send a GET request to "/accounts/test1/releases/actions/upgrade?version=1.0.2&channel=stable&platform=darwin&filetype=dmg&product=6198261a-48b5-4445-a045-9fed4afc7735"
    Then the response status should be "204"

  # Open distribution strategy
  Scenario: License retrieves an upgrade for a product release (OPEN distribution strategy)
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name     | distributionStrategy |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test App | OPEN                 |
    And the current account has the following "release" rows:
      | product_id                           | version | filename           | filetype | platform | channel |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0   | Test-App-1.0.0.dmg | dmg      | darwin   | stable  |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.1   | Test-App-1.0.1.dmg | dmg      | darwin   | stable  |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.2   | Test-App-1.0.2.dmg | dmg      | darwin   | stable  |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.3   | Test-App-1.0.3.dmg | dmg      | darwin   | stable  |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.0   | Test-App-1.1.0.dmg | dmg      | darwin   | stable  |
    And all "releases" have artifacts that are uploaded
    And the current account has 1 "policy" for the first "product"
    And the current account has 1 "license" for the first "policy"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/actions/upgrade?version=1.0.2&channel=stable&platform=darwin&filetype=dmg&product=6198261a-48b5-4445-a045-9fed4afc7735"
    Then the response status should be "303"
    And the JSON response should be an "artifact"
    And the JSON response should contain meta which includes the following:
      """
      {
        "current": "1.0.2",
        "next": "1.1.0"
      }
      """

  Scenario: License retrieves an upgrade for a product release (OPEN distribution strategy, missing entitlement)
    Given the current account is "test1"
    And the current account has the following "entitlement" rows:
      | id                                   | code      |
      | 8cdf47c8-9cdc-44c9-a752-1e137355ecaf | TEST_ENTL |
    And the current account has the following "product" rows:
      | id                                   | name     | distributionStrategy |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test App | OPEN                 |
    And the current account has the following "release" rows:
      | product_id                           | version | filename           | filetype | platform | channel | entitlements |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0   | Test-App-1.0.0.dmg | dmg      | darwin   | stable  | TEST_ENTL    |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.1   | Test-App-1.0.1.dmg | dmg      | darwin   | stable  | TEST_ENTL    |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.2   | Test-App-1.0.2.dmg | dmg      | darwin   | stable  | TEST_ENTL    |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.3   | Test-App-1.0.3.dmg | dmg      | darwin   | stable  | TEST_ENTL    |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.0   | Test-App-1.1.0.dmg | dmg      | darwin   | stable  | TEST_ENTL    |
    And all "releases" have artifacts that are uploaded
    And the current account has 1 "policy" for the first "product"
    And the current account has 1 "license" for the first "policy"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/actions/upgrade?version=1.0.2&channel=stable&platform=darwin&filetype=dmg&product=6198261a-48b5-4445-a045-9fed4afc7735"
    Then the response status should be "204"

  Scenario: License retrieves an upgrade for a product release (OPEN distribution strategy, has entitlement)
    Given the current account is "test1"
    And the current account has the following "entitlement" rows:
      | id                                   | code      |
      | 8cdf47c8-9cdc-44c9-a752-1e137355ecaf | TEST_ENTL |
    And the current account has the following "product" rows:
      | id                                   | name     | distributionStrategy |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test App | OPEN                 |
    And the current account has the following "release" rows:
      | product_id                           | version | filename           | filetype | platform | channel | entitlements |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0   | Test-App-1.0.0.dmg | dmg      | darwin   | stable  | TEST_ENTL    |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.1   | Test-App-1.0.1.dmg | dmg      | darwin   | stable  | TEST_ENTL    |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.2   | Test-App-1.0.2.dmg | dmg      | darwin   | stable  | TEST_ENTL    |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.3   | Test-App-1.0.3.dmg | dmg      | darwin   | stable  | TEST_ENTL    |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.0   | Test-App-1.1.0.dmg | dmg      | darwin   | stable  | TEST_ENTL    |
    And all "releases" have artifacts that are uploaded
    And the current account has 1 "policy" for the first "product"
    And the current account has 1 "license" for the first "policy"
    And the current account has 1 "license-entitlement" with the following:
      """
      {
        "entitlementId": "8cdf47c8-9cdc-44c9-a752-1e137355ecaf",
        "licenseId": "$licenses[0]"
      }
      """
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/actions/upgrade?version=1.0.2&channel=stable&platform=darwin&filetype=dmg&product=6198261a-48b5-4445-a045-9fed4afc7735"
    Then the response status should be "303"
    And the JSON response should be an "artifact"
    And the JSON response should contain meta which includes the following:
      """
      {
        "current": "1.0.2",
        "next": "1.1.0"
      }
      """

  Scenario: User retrieves an upgrade for a product release (OPEN distribution strategy)
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name     | distributionStrategy |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test App | OPEN                 |
    And the current account has the following "release" rows:
      | product_id                           | version | filename           | filetype | platform | channel |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0   | Test-App-1.0.0.dmg | dmg      | darwin   | stable  |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.1   | Test-App-1.0.1.dmg | dmg      | darwin   | stable  |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.2   | Test-App-1.0.2.dmg | dmg      | darwin   | stable  |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.3   | Test-App-1.0.3.dmg | dmg      | darwin   | stable  |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.0   | Test-App-1.1.0.dmg | dmg      | darwin   | stable  |
    And all "releases" have artifacts that are uploaded
    And the current account has 1 "policy" for an existing "product"
    And the current account has 1 "license" for an existing "policy"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    And the current user has 1 "license"
    When I send a GET request to "/accounts/test1/releases/actions/upgrade?version=1.0.2&channel=stable&platform=darwin&filetype=dmg&product=6198261a-48b5-4445-a045-9fed4afc7735"
    Then the response status should be "303"
    And the JSON response should be an "artifact"
    And the JSON response should contain meta which includes the following:
      """
      {
        "current": "1.0.2",
        "next": "1.1.0"
      }
      """

  Scenario: Anonymous retrieves an upgrade for a product release (OPEN distribution strategy)
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name     | distributionStrategy |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test App | OPEN                 |
    And the current account has the following "release" rows:
      | product_id                           | version | filename           | filetype | platform | channel |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0   | Test-App-1.0.0.dmg | dmg      | darwin   | stable  |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.1   | Test-App-1.0.1.dmg | dmg      | darwin   | stable  |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.2   | Test-App-1.0.2.dmg | dmg      | darwin   | stable  |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.3   | Test-App-1.0.3.dmg | dmg      | darwin   | stable  |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.0   | Test-App-1.1.0.dmg | dmg      | darwin   | stable  |
    And all "releases" have artifacts that are uploaded
    When I send a GET request to "/accounts/test1/releases/actions/upgrade?version=1.0.2&channel=stable&platform=darwin&filetype=dmg&product=6198261a-48b5-4445-a045-9fed4afc7735"
    Then the response status should be "303"
    And the JSON response should be an "artifact"
    And the JSON response should contain meta which includes the following:
      """
      {
        "current": "1.0.2",
        "next": "1.1.0"
      }
      """

  # Closed distribution strategy
  Scenario: Anonymous retrieves an upgrade for a product release (CLOSED distribution strategy)
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name     | distributionStrategy |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test App | CLOSED               |
    And the current account has the following "release" rows:
      | product_id                           | version | filename           | filetype | platform | channel |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0   | Test-App-1.0.0.dmg | dmg      | darwin   | stable  |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.1   | Test-App-1.0.1.dmg | dmg      | darwin   | stable  |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.2   | Test-App-1.0.2.dmg | dmg      | darwin   | stable  |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.3   | Test-App-1.0.3.dmg | dmg      | darwin   | stable  |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.0   | Test-App-1.1.0.dmg | dmg      | darwin   | stable  |
    And all "releases" have artifacts that are uploaded
    When I send a GET request to "/accounts/test1/releases/actions/upgrade?version=1.0.2&channel=stable&platform=darwin&filetype=dmg&product=6198261a-48b5-4445-a045-9fed4afc7735"
    Then the response status should be "204"

  Scenario: License retrieves an upgrade for a product release (CLOSED distribution strategy)
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name     | distributionStrategy |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test App | CLOSED               |
    And the current account has the following "release" rows:
      | product_id                           | version | filename           | filetype | platform | channel |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0   | Test-App-1.0.0.dmg | dmg      | darwin   | stable  |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.1   | Test-App-1.0.1.dmg | dmg      | darwin   | stable  |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.2   | Test-App-1.0.2.dmg | dmg      | darwin   | stable  |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.3   | Test-App-1.0.3.dmg | dmg      | darwin   | stable  |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.0   | Test-App-1.1.0.dmg | dmg      | darwin   | stable  |
    And all "releases" have artifacts that are uploaded
    And the current account has 1 "policy" for the first "product"
    And the current account has 1 "license" for the first "policy"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/actions/upgrade?version=1.0.2&channel=stable&platform=darwin&filetype=dmg&product=6198261a-48b5-4445-a045-9fed4afc7735"
    Then the response status should be "204"

  Scenario: User retrieves an upgrade for a product release (CLOSED distribution strategy)
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name     | distributionStrategy |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test App | CLOSED               |
    And the current account has the following "release" rows:
      | product_id                           | version | filename           | filetype | platform | channel |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0   | Test-App-1.0.0.dmg | dmg      | darwin   | stable  |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.1   | Test-App-1.0.1.dmg | dmg      | darwin   | stable  |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.2   | Test-App-1.0.2.dmg | dmg      | darwin   | stable  |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.3   | Test-App-1.0.3.dmg | dmg      | darwin   | stable  |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.0   | Test-App-1.1.0.dmg | dmg      | darwin   | stable  |
    And all "releases" have artifacts that are uploaded
    And the current account has 1 "policy" for an existing "product"
    And the current account has 1 "license" for an existing "policy"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    And the current user has 1 "license"
    When I send a GET request to "/accounts/test1/releases/actions/upgrade?version=1.0.2&channel=stable&platform=darwin&filetype=dmg&product=6198261a-48b5-4445-a045-9fed4afc7735"
    Then the response status should be "204"

  Scenario: Admin retrieves an upgrade for a product release (CLOSED distribution strategy)
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name     | distributionStrategy |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test App | CLOSED               |
    And the current account has the following "release" rows:
      | product_id                           | version | filename           | filetype | platform | channel |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0   | Test-App-1.0.0.dmg | dmg      | darwin   | stable  |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.1   | Test-App-1.0.1.dmg | dmg      | darwin   | stable  |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.2   | Test-App-1.0.2.dmg | dmg      | darwin   | stable  |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.3   | Test-App-1.0.3.dmg | dmg      | darwin   | stable  |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.0   | Test-App-1.1.0.dmg | dmg      | darwin   | stable  |
    And all "releases" have artifacts that are uploaded
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/actions/upgrade?version=1.0.2&channel=stable&platform=darwin&filetype=dmg&product=6198261a-48b5-4445-a045-9fed4afc7735"
    Then the response status should be "303"
    And the JSON response should be an "artifact"
    And the JSON response should contain meta which includes the following:
      """
      {
        "current": "1.0.2",
        "next": "1.1.0"
      }
      """

  Scenario: Product retrieves an upgrade for their release (CLOSED distribution strategy)
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name     | distributionStrategy |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test App | CLOSED               |
    And the current account has the following "release" rows:
      | product_id                           | version | filename           | filetype | platform | channel |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0   | Test-App-1.0.0.dmg | dmg      | darwin   | stable  |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.1   | Test-App-1.0.1.dmg | dmg      | darwin   | stable  |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.2   | Test-App-1.0.2.dmg | dmg      | darwin   | stable  |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.3   | Test-App-1.0.3.dmg | dmg      | darwin   | stable  |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.0   | Test-App-1.1.0.dmg | dmg      | darwin   | stable  |
    And all "releases" have artifacts that are uploaded
    And I am a product of account "test1"
    And I use an authentication token
    And the current user has 1 "license"
    When I send a GET request to "/accounts/test1/releases/actions/upgrade?version=1.0.2&channel=stable&platform=darwin&filetype=dmg&product=6198261a-48b5-4445-a045-9fed4afc7735"
    Then the response status should be "303"
    And the JSON response should be an "artifact"
    And the JSON response should contain meta which includes the following:
      """
      {
        "current": "1.0.2",
        "next": "1.1.0"
      }
      """

  Scenario: Product retrieves an upgrade for another product release (CLOSED distribution strategy)
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name       | distributionStrategy |
      | 6ac37cee-0027-4cdb-ba25-ac98fa0d29b4 | Test App A | CLOSED               |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test App B | CLOSED               |
    And the current account has the following "release" rows:
      | product_id                           | version | filename           | filetype | platform | channel |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0   | Test-App-1.0.0.dmg | dmg      | darwin   | stable  |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.1   | Test-App-1.0.1.dmg | dmg      | darwin   | stable  |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.2   | Test-App-1.0.2.dmg | dmg      | darwin   | stable  |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.3   | Test-App-1.0.3.dmg | dmg      | darwin   | stable  |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.0   | Test-App-1.1.0.dmg | dmg      | darwin   | stable  |
    And all "releases" have artifacts that are uploaded
    And I am a product of account "test1"
    And I use an authentication token
    And the current user has 1 "license"
    When I send a GET request to "/accounts/test1/releases/actions/upgrade?version=1.0.2&channel=stable&platform=darwin&filetype=dmg&product=6198261a-48b5-4445-a045-9fed4afc7735"
    Then the response status should be "204"
