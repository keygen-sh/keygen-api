@api/v1
Feature: Electron upgrade application
  Background:
    Given the following "accounts" exist:
      | name   | slug  |
      | Test 1 | test1 |
      | Test 2 | test2 |
    And the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test |
    And the current account has the following "package" rows:
      | id                                   | product_id                           | engine   | key  |
      | 46e034fe-2312-40f8-bbeb-7d9957fb6fcf | 6198261a-48b5-4445-a045-9fed4afc7735 | electron | app1 |
      | 2f8af04a-2424-4ca2-8480-6efe24318d1a | 6198261a-48b5-4445-a045-9fed4afc7735 | electron | app2 |
      | 7b113ac2-ae81-406a-b44e-f356126e2faa | 6198261a-48b5-4445-a045-9fed4afc7735 | pypi     | pkg1 |
      | 5666d47e-936e-4d48-8dd7-382d32462b4e | 6198261a-48b5-4445-a045-9fed4afc7735 |          | pkg2 |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | release_package_id                   | version      | channel  | description |
      | 757e0a41-835e-42ad-bad8-84cabd29c72a | 6198261a-48b5-4445-a045-9fed4afc7735 | 46e034fe-2312-40f8-bbeb-7d9957fb6fcf | 1.0.0        | stable   | foo         |
      | 028a38a2-0d17-4871-acb8-c5e6f040fc12 | 6198261a-48b5-4445-a045-9fed4afc7735 | 46e034fe-2312-40f8-bbeb-7d9957fb6fcf | 1.1.0        | stable   | bar         |
      | 2bbb14ae-bb6b-4c57-b6ab-26f7982c967d | 6198261a-48b5-4445-a045-9fed4afc7735 | 46e034fe-2312-40f8-bbeb-7d9957fb6fcf | 1.2.0-beta.1 | beta     |             |
      | c77ba874-de62-4a17-8368-fc10db1e1c80 | 6198261a-48b5-4445-a045-9fed4afc7735 | 2f8af04a-2424-4ca2-8480-6efe24318d1a | 1.0.0-beta.1 | beta     | baz         |
      | 29f74047-265f-452c-9d64-779621682857 | 6198261a-48b5-4445-a045-9fed4afc7735 | 2f8af04a-2424-4ca2-8480-6efe24318d1a | 1.0.1-beta.1 | beta     | baz         |
      | 972aa5b8-b12c-49f4-8ba4-7c9ae053dfa2 | 6198261a-48b5-4445-a045-9fed4afc7735 | 2f8af04a-2424-4ca2-8480-6efe24318d1a | 2.0.0-beta.1 | beta     | qux         |
    And the current account has the following "artifact" rows:
      | id                                   | release_id                           | filename                             | filetype | platform | arch  |
      # app1 1.0.0
      | 1f63d6ec-8147-4bf0-bcd2-5d4f0e5eab8f | 757e0a41-835e-42ad-bad8-84cabd29c72a | myapp-1.0.0-darwin-x64.zip           | zip      | darwin   | x64   |
      | fa773c2b-1c3a-4bd8-83fe-546480e92098 | 757e0a41-835e-42ad-bad8-84cabd29c72a | myapp-1.0.0-win32-x64-setup.exe      | exe      | win32    | x64   |
      | ab3f9749-3ea7-4057-92ec-d647784ff097 | 757e0a41-835e-42ad-bad8-84cabd29c72a | myapp-1.0.0-full.nupkg               | nupkg    | win32    | x64   |
      # app1 1.1.0
      | 00aeec65-165c-487c-8e22-7ab454319b0f | 028a38a2-0d17-4871-acb8-c5e6f040fc12 | myapp-1.1.0-darwin-x64.zip           | zip      | darwin   | x64   |
      | 2133955c-137f-4422-9290-9a364b1a40a0 | 028a38a2-0d17-4871-acb8-c5e6f040fc12 | myapp-1.1.0-win32-x64-setup.exe      | exe      | win32    | x64   |
      | eaa67d65-f596-427a-8f64-80a7125ae299 | 028a38a2-0d17-4871-acb8-c5e6f040fc12 | myapp-1.1.0-full.nupkg               | nupkg    | win32    | x64   |
      # app1 1.2.0-beta.1
      | 05f8a823-b80b-4453-a524-82332fc50792 | 2bbb14ae-bb6b-4c57-b6ab-26f7982c967d | myapp-1.2.0-beta.1-darwin-x64.zip    | zip      | darwin   | x64   |
      | d5405732-577f-42eb-bd53-3bbc524072f0 | 2bbb14ae-bb6b-4c57-b6ab-26f7982c967d | myapp-1.2.0-beta.1-win32-x64.exe     | exe      | win32    | x64   |
      # app2 1.0.0-beta.1
      | 699a9b1e-6d57-428a-b039-cb387de7d6ff | c77ba874-de62-4a17-8368-fc10db1e1c80 | myapp-1.0.0-beta.1-win32-ia32.exe    | exe      | win32    | ia32  |
      # app2 1.0.1-beta.1
      | 05b82ab6-ad64-46d4-9885-97a23347eb1c | 29f74047-265f-452c-9d64-779621682857 | myapp-1.0.1-beta.1-win32-ia32.exe    | exe      | win32    | ia32  |
      # app2 2.0.0-beta.1
      | 16b9a3fa-6b12-4d86-b81e-be2757392bae | 972aa5b8-b12c-49f4-8ba4-7c9ae053dfa2 | myapp-2.0.0-beta.1-win32-ia32.exe    | exe      | win32    | ia32  |
    And I send the following raw headers:
      """
      Accept: application/json
      """

  Scenario: Endpoint should be inaccessible when account is disabled
    Given the account "test1" is canceled
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/engines/electron/app1/darwin-x64/1.0.0"
    Then the response status should be "403"
    And the response should contain the following headers:
      """
      { "Content-Type": "application/json; charset=utf-8" }
      """

  @mp
  Scenario: Endpoint should be accessible from subdomain
    Given the current account has 1 "webhook-endpoint"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "//electron.pkg.keygen.sh/test1/app1/darwin-x64/1.0.0"
    Then the response status should be "200"
    And the response body should include the following:
      """
      {
        "url": "https://electron.pkg.keygen.sh/v1/accounts/$account/artifacts/00aeec65-165c-487c-8e22-7ab454319b0f/myapp-1.1.0-darwin-x64.zip",
        "name": "1.1.0"
      }
      """

  @sp
  Scenario: Endpoint should be accessible from subdomain
    Given the current account has 1 "webhook-endpoint"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "//electron.pkg.keygen.sh/app1/darwin-x64/1.0.0"
    Then the response status should be "200"
    And the response body should include the following:
      """
      {
        "url": "https://electron.pkg.keygen.sh/v1/accounts/$account/artifacts/00aeec65-165c-487c-8e22-7ab454319b0f/myapp-1.1.0-darwin-x64.zip",
        "name": "1.1.0"
      }
      """

  Scenario: Endpoint should not return an upgrade when an upgrade is not available
    Given the current account has 1 "webhook-endpoint"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/engines/electron/app1/darwin-x64/1.1.0"
    Then the response status should be "204"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Endpoint should not return an upgrade when a version does not exist
    Given the current account has 1 "webhook-endpoint"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/engines/electron/app1/darwin-x64/3.0.0"
    Then the response status should be "204"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Endpoint should return an upgrade for macOS when an upgrade is available
    Given the current account has 1 "webhook-endpoint"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/engines/electron/app1/darwin-x64/1.0.0"
    Then the response status should be "200"
    And the response body should include the following:
      """
      {
        "url": "https://api.keygen.sh/v1/accounts/$account/artifacts/00aeec65-165c-487c-8e22-7ab454319b0f/myapp-1.1.0-darwin-x64.zip",
        "name": "1.1.0"
      }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  Scenario: Endpoint should return an upgrade for Windows when an upgrade is available
    Given the current account has 1 "webhook-endpoint"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/engines/electron/app1/win32-x64/1.0.0"
    Then the response status should be "200"
    And the response body should include the following:
      """
      {
        "url": "https://api.keygen.sh/v1/accounts/$account/artifacts/2133955c-137f-4422-9290-9a364b1a40a0/myapp-1.1.0-win32-x64-setup.exe",
        "name": "1.1.0"
      }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  Scenario: Endpoint should include release notes when available
    Given I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/engines/electron/app1/darwin-x64/1.0.0"
    Then the response status should be "200"
    And the response body should include the following:
      """
      { "notes": "bar" }
      """

  Scenario: Endpoint should include publish date when available
    Given the second "release" has the following attributes:
      """
      { "createdAt": "2023-08-15T00:00:00.000Z" }
      """
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/engines/electron/app1/darwin-x64/1.0.0"
    Then the response status should be "200"
    And the response body should include the following:
      """
      { "pub_date": "2023-08-15T00:00:00.000Z" }
      """

  Scenario: Endpoint should constrain to a semver constraint
    Given I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/engines/electron/app2/win32-ia32/1.0.0-beta.1?constraint=1.0"
    Then the response status should be "200"
    And the response body should include the following:
      """
      {
        "url": "https://api.keygen.sh/v1/accounts/$account/artifacts/05b82ab6-ad64-46d4-9885-97a23347eb1c/myapp-1.0.1-beta.1-win32-ia32.exe",
        "name": "1.0.1-beta.1"
      }
      """

  Scenario: Endpoint should upgrade from stable to beta
    Given I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/engines/electron/app1/darwin-x64/1.1.0?channel=beta"
    Then the response status should be "200"
    And the response body should include the following:
      """
      {
        "url": "https://api.keygen.sh/v1/accounts/$account/artifacts/05f8a823-b80b-4453-a524-82332fc50792/myapp-1.2.0-beta.1-darwin-x64.zip",
        "name": "1.2.0-beta.1"
      }
      """

  Scenario: Endpoint should return error for non-Electron packages
    Given I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/engines/electron/pkg1/darwin-x64/1.0.0"
    Then the response status should be "404"

  Scenario: Product retrieves an upgrade when an upgrade is available
    Given I am the first product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/engines/electron/app1/win32-x64/1.0.0"
    Then the response status should be "200"
    And the response body should include the following:
      """
      {
        "url": "https://api.keygen.sh/v1/accounts/$account/artifacts/2133955c-137f-4422-9290-9a364b1a40a0/myapp-1.1.0-win32-x64-setup.exe",
        "name": "1.1.0"
      }
      """

  Scenario: License retrieves an upgrade when an upgrade is available
    Given the current account has 1 "policy" for the last "product" with the following:
      """
      { "authenticationStrategy": "LICENSE" }
      """
    And the current account has 1 "license" for the last "policy"
    And I am a license of account "test1"
    And I authenticate with my key
    When I send a GET request to "/accounts/test1/engines/electron/app1/darwin-x64/1.0.0"
    Then the response status should be "200"
    And the response body should include the following:
      """
      {
        "url": "https://api.keygen.sh/v1/accounts/$account/artifacts/00aeec65-165c-487c-8e22-7ab454319b0f/myapp-1.1.0-darwin-x64.zip",
        "name": "1.1.0"
      }
      """

  Scenario: License retrieves an upgrade for a release that has entitlement constraints (no entitlements)
    Given the current account has 3 "entitlements"
    And the current account has 1 "release-entitlement-constraint" for the first "release" with the following:
      """
      { "entitlementId": "$entitlements[0]" }
      """
    And the current account has 1 "policy" for the first "product" with the following:
      """
      { "authenticationStrategy": "LICENSE" }
      """
    And the current account has 1 "license" for the last "policy"
    And I am a license of account "test1"
    And I authenticate with my key
    When I send a GET request to "/accounts/test1/engines/electron/app1/darwin-x64/1.0.0"
    Then the response status should be "204"

  Scenario: License retrieves an upgrade that has entitlement constraints (no entitlements)
    Given the current account has 3 "entitlements"
    And the current account has 1 "release-entitlement-constraint" for the second "release" with the following:
      """
      { "entitlementId": "$entitlements[0]" }
      """
    And the current account has 1 "policy" for the first "product" with the following:
      """
      { "authenticationStrategy": "LICENSE" }
      """
    And the current account has 1 "license" for the last "policy"
    And I am a license of account "test1"
    And I authenticate with my key
    When I send a GET request to "/accounts/test1/engines/electron/app1/darwin-x64/1.0.0"
    Then the response status should be "204"

  Scenario: License retrieves an upgrade that has entitlement constraints (has entitlements)
    Given the current account has 3 "entitlements"
    And the current account has 1 "release-entitlement-constraint" for the second "release" with the following:
      """
      { "entitlementId": "$entitlements[0]" }
      """
    And the current account has 1 "policy" for the last "product" with the following:
      """
      { "authenticationStrategy": "LICENSE" }
      """
    And the current account has 1 "license" for the last "policy"
    And the current account has 1 "license-entitlement" for the first "license" with the following:
      """
      { "entitlementId": "$entitlements[0]" }
      """
    And I am a license of account "test1"
    And I authenticate with my key
    When I send a GET request to "/accounts/test1/engines/electron/app1/darwin-x64/1.0.0"
    Then the response status should be "200"
    And the response body should include the following:
      """
      {
        "url": "https://api.keygen.sh/v1/accounts/$account/artifacts/00aeec65-165c-487c-8e22-7ab454319b0f/myapp-1.1.0-darwin-x64.zip",
        "name": "1.1.0"
      }
      """

  Scenario: User retrieves an upgrade when an upgrade is available (license owner)
    Given the current account has 1 "policy" for the last "product"
    And the current account has 1 "license" for the last "policy"
    And the current account has 1 "user"
    And the last "license" belongs to the last "user" through "owner"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/engines/electron/app1/darwin-x64/1.0.0"
    Then the response status should be "200"
    And the response body should include the following:
      """
      {
        "url": "https://api.keygen.sh/v1/accounts/$account/artifacts/00aeec65-165c-487c-8e22-7ab454319b0f/myapp-1.1.0-darwin-x64.zip",
        "name": "1.1.0"
      }
      """

  Scenario: User retrieves an upgrade when an upgrade is available (license user)
    Given the current account has 1 "policy" for the last "product"
    And the current account has 1 "license" for the last "policy"
    And the current account has 1 "user"
    And the current account has 1 "license-user" for the last "license" and the last "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/engines/electron/app1/darwin-x64/1.0.0"
    Then the response status should be "200"
    And the response body should include the following:
      """
      {
        "url": "https://api.keygen.sh/v1/accounts/$account/artifacts/00aeec65-165c-487c-8e22-7ab454319b0f/myapp-1.1.0-darwin-x64.zip",
        "name": "1.1.0"
      }
      """

  Scenario: Anonymous retrieves an upgrade for a licensed product
    Given the last "product" has the following attributes:
      """
      { "distributionStrategy": "LICENSED" }
      """
    When I send a GET request to "/accounts/test1/engines/electron/app1/darwin-x64/1.0.0"
    Then the response status should be "404"

  Scenario: Anonymous retrieves an upgrade for a closed product
    Given the last "product" has the following attributes:
      """
      { "distributionStrategy": "CLOSED" }
      """
    When I send a GET request to "/accounts/test1/engines/electron/app1/darwin-x64/1.0.0"
    Then the response status should be "404"

  Scenario: Anonymous retrieves an upgrade for an open product
    Given the last "product" has the following attributes:
      """
      { "distributionStrategy": "OPEN" }
      """
    When I send a GET request to "/accounts/test1/engines/electron/app1/darwin-x64/1.0.0"
    Then the response status should be "200"
    And the response body should include the following:
      """
      {
        "url": "https://api.keygen.sh/v1/accounts/$account/artifacts/00aeec65-165c-487c-8e22-7ab454319b0f/myapp-1.1.0-darwin-x64.zip",
        "name": "1.1.0"
      }
      """
