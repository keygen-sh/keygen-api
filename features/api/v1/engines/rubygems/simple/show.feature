@api/v1
Feature: Rubygems simple package files
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
      | id                                   | product_id                           | engine    | key |
      | 46e034fe-2312-40f8-bbeb-7d9957fb6fcf | 6198261a-48b5-4445-a045-9fed4afc7735 | rubygems  | foo |
      | 2f8af04a-2424-4ca2-8480-6efe24318d1a | 6198261a-48b5-4445-a045-9fed4afc7735 | rubygems  | bar |
      | 7b113ac2-ae81-406a-b44e-f356126e2faa | 6198261a-48b5-4445-a045-9fed4afc7735 | rubygems  | baz |
      | 5666d47e-936e-4d48-8dd7-382d32462b4e | 6198261a-48b5-4445-a045-9fed4afc7735 |           | qux |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | release_package_id                   | version      | channel  | description |
      | 757e0a41-835e-42ad-bad8-84cabd29c72a | 6198261a-48b5-4445-a045-9fed4afc7735 | 46e034fe-2312-40f8-bbeb-7d9957fb6fcf | 1.0.0        | stable   | foo         |
      | 3ff04fc6-9f10-4b84-b548-eb40f92ea331 | 6198261a-48b5-4445-a045-9fed4afc7735 | 46e034fe-2312-40f8-bbeb-7d9957fb6fcf | 1.0.1        | stable   | foo         |
      | 028a38a2-0d17-4871-acb8-c5e6f040fc12 | 6198261a-48b5-4445-a045-9fed4afc7735 | 46e034fe-2312-40f8-bbeb-7d9957fb6fcf | 1.1.0        | stable   | foo         |
      | 972aa5b8-b12c-49f4-8ba4-7c9ae053dfa2 | 6198261a-48b5-4445-a045-9fed4afc7735 | 2f8af04a-2424-4ca2-8480-6efe24318d1a | 1.0.0-beta.1 | beta     | bar         |
      | 28a6e16d-c2a6-4be7-8578-e236182ee5c3 | 6198261a-48b5-4445-a045-9fed4afc7735 | 7b113ac2-ae81-406a-b44e-f356126e2faa | 2.0.0        | stable   |             |
      | 70c40946-4b23-408c-aa1c-fa35421ff46a | 6198261a-48b5-4445-a045-9fed4afc7735 |                                      | 1.1.0        | stable   |             |
    And the current account has the following "artifact" rows:
      | id                                   | release_id                           | filename                    | filetype |
      | 1f63d6ec-8147-4bf0-bcd2-5d4f0e5eab8f | 757e0a41-835e-42ad-bad8-84cabd29c72a | foo-1.0.0.gem               | gem      |
      | c1f8705e-68cd-4312-b2b1-72e19df47bd1 | 3ff04fc6-9f10-4b84-b548-eb40f92ea331 | foo-1.0.1.gem               | gem      |
      | a8e49ea6-17df-4798-937f-e4756e331db5 | 028a38a2-0d17-4871-acb8-c5e6f040fc12 | foo-1.1.0.gem               | gem      |
      | fa773c2b-1c3a-4bd8-83fe-546480e92098 | 972aa5b8-b12c-49f4-8ba4-7c9ae053dfa2 | bar-1.0.0.beta.gem          | gem      |
      | 1cccff81-8b49-40b2-9453-3456f2ca04ac | 28a6e16d-c2a6-4be7-8578-e236182ee5c3 | baz-2.0.0.gem               | gem      |
      | d7e01e53-4f9c-48a5-96cb-13207fc25cfe | 70c40946-4b23-408c-aa1c-fa35421ff46a | qux-1.1.0.gem               | gem      |

  Scenario: Endpoint should be inaccessible when account is disabled
    Given the account "test1" is canceled
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/engines/rubygems/simple/foo?version=1.0.0"
    Then the response status should be "403"
    And the response should contain the following headers:
      """
      { "Content-Type": "application/json; charset=utf-8" }
      """

  Scenario: Endpoint should redirect to Rubygems.org when package does not exist
    Given I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/engines/rubygems/simple/qux"
    Then the response status should be "307"
    And the response should contain the following headers:
      """
      { "Location": "https://rubygems.org/gems/qux" }
      """

  Scenario: Endpoint should return versions when package exists (Rubygems engine)
    Given I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/engines/rubygems/simple/foo?version=1.0.0"
    Then the response status should be "200"
    And the response body should include the following:
      """
      {
        "url":"https://api.keygen.sh/v1/accounts/$account/artifacts/1f63d6ec-8147-4bf0-bcd2-5d4f0e5eab8f/foo-1.0.0.gem",
        "version":"1.0.0",
        "notes":"foo"
      }
      """

  Scenario: Endpoint should include release notes when available
    Given I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/engines/rubygems/simple/foo?version=1.0.0"
    Then the response status should be "200"
    And the response body should include the following:
      """
      {
        "notes":"foo"
      }
      """

  Scenario: Endpoint should include publish date when available
    Given the first "release" has the following attributes:
      """
      { "createdAt": "2024-08-15T00:00:00.000Z" }
      """
    Given I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/engines/rubygems/simple/foo?version=1.0.0"
    Then the response status should be "200"
    And the response body should include the following:
      """
      { "pub_date": "2024-08-15T00:00:00.000Z" }
      """

  Scenario: License requests versions for a licensed product
    Given the last "product" has the following attributes:
      """
      { "distributionStrategy": "LICENSED" }
      """
    And the current account has 1 "policy" for the last "product" with the following:
      """
      { "authenticationStrategy": "LICENSE" }
      """
    And the current account has 1 "license" for the last "policy"
    And I am a license of account "test1"
    And I authenticate with my key
    When I send a GET request to "/accounts/test1/engines/rubygems/simple/foo?version=1.0.0"
    Then the response status should be "200"

  Scenario: License requests versions for a closed product
    Given the last "product" has the following attributes:
      """
      { "distributionStrategy": "CLOSED" }
      """
    And the current account has 1 "policy" for the last "product" with the following:
      """
      { "authenticationStrategy": "LICENSE" }
      """
    And the current account has 1 "license" for the last "policy"
    And I am a license of account "test1"
    And I authenticate with my key
    When I send a GET request to "/accounts/test1/engines/rubygems/simple/foo?version=1.0.0"
    Then the response status should be "307"
    And the response should contain the following headers:
      """
      { "Location": "https://rubygems.org/gems/foo" }
      """

  Scenario: License requests versions for an open product
    Given the last "product" has the following attributes:
      """
      { "distributionStrategy": "OPEN" }
      """
    And the current account has 1 "policy" for the last "product" with the following:
      """
      { "authenticationStrategy": "LICENSE" }
      """
    And the current account has 1 "license" for the last "policy"
    And I am a license of account "test1"
    And I authenticate with my key
    When I send a GET request to "/accounts/test1/engines/rubygems/simple/foo?version=1.0.0"
    Then the response status should be "200"

  Scenario: License requests versions for another licensed product
    Given the last "product" has the following attributes:
      """
      { "distributionStrategy": "LICENSED" }
      """
    And the current account has 1 "policy" with the following:
      """
      { "authenticationStrategy": "LICENSE" }
      """
    And the current account has 1 "license" for the last "policy"
    And I am a license of account "test1"
    And I authenticate with my key
    When I send a GET request to "/accounts/test1/engines/rubygems/simple/foo?version=1.0.0"
    Then the response status should be "307"
    And the response should contain the following headers:
      """
      { "Location": "https://rubygems.org/gems/foo" }
      """

  Scenario: License requests versions for another closed product
    Given the last "product" has the following attributes:
      """
      { "distributionStrategy": "CLOSED" }
      """
    And the current account has 1 "policy" with the following:
      """
      { "authenticationStrategy": "LICENSE" }
      """
    And the current account has 1 "license" for the last "policy"
    And I am a license of account "test1"
    And I authenticate with my key
    When I send a GET request to "/accounts/test1/engines/rubygems/simple/foo?version=1.0.0"
    Then the response status should be "307"
    And the response should contain the following headers:
      """
      { "Location": "https://rubygems.org/gems/foo" }
      """

  Scenario: License requests versions for another open product
    Given the last "product" has the following attributes:
      """
      { "distributionStrategy": "OPEN" }
      """
    And the current account has 1 "policy" with the following:
      """
      { "authenticationStrategy": "LICENSE" }
      """
    And the current account has 1 "license" for the last "policy"
    And I am a license of account "test1"
    And I authenticate with my key
    When I send a GET request to "/accounts/test1/engines/rubygems/simple/foo?version=1.0.0"
    Then the response status should be "200"

  Scenario: Anonymous requests versions for a licensed product
    Given the last "product" has the following attributes:
      """
      { "distributionStrategy": "LICENSED" }
      """
    When I send a GET request to "/accounts/test1/engines/rubygems/simple/foo?version=1.0.0"
    Then the response status should be "307"
    And the response should contain the following headers:
      """
      { "Location": "https://rubygems.org/gems/foo" }
      """

  Scenario: Anonymous requests versions for a closed product
    Given the last "product" has the following attributes:
      """
      { "distributionStrategy": "CLOSED" }
      """
    When I send a GET request to "/accounts/test1/engines/rubygems/simple/foo?version=1.0.0"
    Then the response status should be "307"
    And the response should contain the following headers:
      """
      { "Location": "https://rubygems.org/gems/foo" }
      """

  Scenario: Anonymous requests versions for an open product
    Given the last "product" has the following attributes:
      """
      { "distributionStrategy": "OPEN" }
      """
    When I send a GET request to "/accounts/test1/engines/rubygems/simple/foo?version=1.0.0"
    Then the response status should be "200"

  Scenario: Anonymous requests versions using a previous API version
    Given the last "product" has the following attributes:
      """
      { "distributionStrategy": "OPEN" }
      """
    And I use API version "1.3"
    When I send a GET request to "/accounts/test1/engines/rubygems/simple/foo?version=1.0.0"
    Then the response status should be "200"
