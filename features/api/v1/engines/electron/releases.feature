@api/v1
Feature: Electron RELEASES for Squirrel.Windows
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
      | 7b113ac2-ae81-406a-b44e-f356126e2faa | 6198261a-48b5-4445-a045-9fed4afc7735 | pypi     | pkg1 |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | release_package_id                   | version | channel | description |
      | 757e0a41-835e-42ad-bad8-84cabd29c72a | 6198261a-48b5-4445-a045-9fed4afc7735 | 46e034fe-2312-40f8-bbeb-7d9957fb6fcf | 1.0.0   | stable  | foo         |
      | 028a38a2-0d17-4871-acb8-c5e6f040fc12 | 6198261a-48b5-4445-a045-9fed4afc7735 | 46e034fe-2312-40f8-bbeb-7d9957fb6fcf | 1.1.0   | stable  | bar         |
    And the current account has the following "artifact" rows:
      | id                                   | release_id                           | filename                        | filetype | platform | arch |
      # 1.0.0
      | 1f63d6ec-8147-4bf0-bcd2-5d4f0e5eab8f | 757e0a41-835e-42ad-bad8-84cabd29c72a | myapp-1.0.0-darwin-x64.zip      | zip      | darwin   | x64  |
      | fa773c2b-1c3a-4bd8-83fe-546480e92098 | 757e0a41-835e-42ad-bad8-84cabd29c72a | myapp-1.0.0-win32-x64-setup.exe | exe      | win32    | x64  |
      | ab3f9749-3ea7-4057-92ec-d647784ff097 | 757e0a41-835e-42ad-bad8-84cabd29c72a | myapp-1.0.0-full.nupkg          | nupkg    | win32    | x64  |
      | d7e01e53-4f9c-48a5-96cb-13207fc25cfe | 757e0a41-835e-42ad-bad8-84cabd29c72a | RELEASES                        |          | win32    | x64  |
      # 1.1.0
      | 00aeec65-165c-487c-8e22-7ab454319b0f | 028a38a2-0d17-4871-acb8-c5e6f040fc12 | myapp-1.1.0-darwin-x64.zip      | zip      | darwin   | x64  |
      | 2133955c-137f-4422-9290-9a364b1a40a0 | 028a38a2-0d17-4871-acb8-c5e6f040fc12 | myapp-1.1.0-win32-x64-setup.exe | exe      | win32    | x64  |
      | eaa67d65-f596-427a-8f64-80a7125ae299 | 028a38a2-0d17-4871-acb8-c5e6f040fc12 | myapp-1.1.0-full.nupkg          | nupkg    | win32    | x64  |
      | c185d92b-1232-4bdd-9906-fa4d99e259c7 | 028a38a2-0d17-4871-acb8-c5e6f040fc12 | RELEASES                        |          | win32    | x64  |
    And I send the following raw headers:
      """
      Accept: application/octet-stream
      """

  Scenario: Endpoint should be inaccessible when account is disabled
    Given the account "test1" is canceled
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/engines/electron/app1/win32-x64/1.0.0/RELEASES"
    Then the response status should be "403"

  Scenario: Endpoint should redirect to RELEASES artifact when an upgrade is available
    Given the current account has 1 "webhook-endpoint"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/engines/electron/app1/win32-x64/1.0.0/RELEASES"
    Then the response status should be "303"
    And the response should contain the following headers:
      """
      {
        "Location": "https://api.keygen.sh/v1/accounts/$account/artifacts/c185d92b-1232-4bdd-9906-fa4d99e259c7/RELEASES"
      }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  Scenario: Endpoint should not return RELEASES when no upgrade is available
    Given the current account has 1 "webhook-endpoint"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/engines/electron/app1/win32-x64/1.1.0/RELEASES"
    Then the response status should be "204"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Endpoint should return error for non-Electron packages
    Given I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/engines/electron/pkg1/win32-x64/1.0.0/RELEASES"
    Then the response status should be "404"

  @mp
  Scenario: Endpoint should be accessible from subdomain
    Given the current account has 1 "webhook-endpoint"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "//electron.pkg.keygen.sh/test1/app1/win32-x64/1.0.0/RELEASES"
    Then the response status should be "303"
    And the response should contain the following headers:
      """
      {
        "Location": "https://electron.pkg.keygen.sh/v1/accounts/$account/artifacts/c185d92b-1232-4bdd-9906-fa4d99e259c7/RELEASES"
      }
      """

  @sp
  Scenario: Endpoint should be accessible from subdomain
    Given the current account has 1 "webhook-endpoint"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "//electron.pkg.keygen.sh/app1/win32-x64/1.0.0/RELEASES"
    Then the response status should be "303"
    And the response should contain the following headers:
      """
      {
        "Location": "https://electron.pkg.keygen.sh/v1/accounts/$account/artifacts/c185d92b-1232-4bdd-9906-fa4d99e259c7/RELEASES"
      }
      """

  Scenario: License retrieves RELEASES when an upgrade is available
    Given the current account has 1 "policy" for the last "product" with the following:
      """
      { "authenticationStrategy": "LICENSE" }
      """
    And the current account has 1 "license" for the last "policy"
    And I am a license of account "test1"
    And I authenticate with my key
    When I send a GET request to "/accounts/test1/engines/electron/app1/win32-x64/1.0.0/RELEASES"
    Then the response status should be "303"

  Scenario: Anonymous retrieves RELEASES for a licensed product
    Given the last "product" has the following attributes:
      """
      { "distributionStrategy": "LICENSED" }
      """
    When I send a GET request to "/accounts/test1/engines/electron/app1/win32-x64/1.0.0/RELEASES"
    Then the response status should be "404"

  Scenario: Anonymous retrieves RELEASES for an open product
    Given the last "product" has the following attributes:
      """
      { "distributionStrategy": "OPEN" }
      """
    When I send a GET request to "/accounts/test1/engines/electron/app1/win32-x64/1.0.0/RELEASES"
    Then the response status should be "303"
