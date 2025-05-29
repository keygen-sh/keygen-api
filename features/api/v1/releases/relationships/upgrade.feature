@api/v1
Feature: Upgrade release

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
    When I send a GET request to "/accounts/test1/releases/$0/upgrade"
    Then the response status should be "403"

  Scenario: Admin retrieves an upgrade for a product release (upgrade available)
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name     |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test App |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | version | channel  |
      | fffa0764-3a19-48ea-beb3-8950563c7357 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0   | stable   |
      | 165d5389-e535-4f36-9232-ed59c67375d1 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.1   | stable   |
      | e4fa628e-593d-48bc-8e3e-5e4dda1f2c3a | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.2   | stable   |
      | fd10ab0c-c52a-412f-b34f-180eebd7325d | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.3   | stable   |
      | f98d8c17-5fad-4361-ad89-43b0c6f6fa00 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.0   | stable   |
      | 077ca1f2-6125-4a77-bdf0-3161a0fc278e | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.1   | stable   |
      | 0a027f00-0860-4fa7-bd37-5900c8866818 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.2   | stable   |
      | 6344460b-b43c-4aa8-a76c-2086f9f526cc | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.2.0   | stable   |
      | cf72bfd4-771d-4889-8132-dc6ba8b66fa9 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.3.0   | stable   |
      | e314ba5d-c760-4e54-81c4-fa01af68ff66 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.4.0   | stable   |
      | e26e9fef-d1ce-43d3-a15c-c8fc94429709 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.5.0   | stable   |
      | ff04d1c4-cc04-4d19-985a-cb113827b821 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.6.0   | stable   |
      | c8b55f91-e66f-4093-ae4d-7f3d390eae8d | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.7.0   | stable   |
      | dde54ea8-731d-4375-9d57-186ef01f3fcb | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0   | stable   |
      | a7fad100-04eb-418f-8af9-e5eac497ad5a | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.1   | stable   |
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$0/upgrade"
    Then the response status should be "200"
    And the response body should be a "release" with the following attributes:
      """
      { "version": "2.0.1" }
      """
    And the response body should contain meta which includes the following:
      """
      {
        "current": "1.0.0",
        "next": "2.0.1"
      }
      """

  Scenario: Admin retrieves an upgrade for a product release (up-to-date)
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name     |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test App |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | version | channel  |
      | fffa0764-3a19-48ea-beb3-8950563c7357 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0   | stable   |
      | 165d5389-e535-4f36-9232-ed59c67375d1 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.1   | stable   |
      | e4fa628e-593d-48bc-8e3e-5e4dda1f2c3a | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.2   | stable   |
      | fd10ab0c-c52a-412f-b34f-180eebd7325d | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.3   | stable   |
      | f98d8c17-5fad-4361-ad89-43b0c6f6fa00 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.0   | stable   |
      | 077ca1f2-6125-4a77-bdf0-3161a0fc278e | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.1   | stable   |
      | 0a027f00-0860-4fa7-bd37-5900c8866818 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.2   | stable   |
      | 6344460b-b43c-4aa8-a76c-2086f9f526cc | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.2.0   | stable   |
      | cf72bfd4-771d-4889-8132-dc6ba8b66fa9 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.3.0   | stable   |
      | e314ba5d-c760-4e54-81c4-fa01af68ff66 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.4.0   | stable   |
      | e26e9fef-d1ce-43d3-a15c-c8fc94429709 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.5.0   | stable   |
      | ff04d1c4-cc04-4d19-985a-cb113827b821 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.6.0   | stable   |
      | c8b55f91-e66f-4093-ae4d-7f3d390eae8d | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.7.0   | stable   |
      | dde54ea8-731d-4375-9d57-186ef01f3fcb | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0   | stable   |
      | a7fad100-04eb-418f-8af9-e5eac497ad5a | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.1   | stable   |
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/a7fad100-04eb-418f-8af9-e5eac497ad5a/upgrade"
    Then the response status should be "404"

  Scenario: Admin retrieves an upgrade for a product release (duplicate versions)
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name     |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test App |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | version | channel | api_version|
      | fffa0764-3a19-48ea-beb3-8950563c7357 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0   | stable  | 1.0        |
      | 165d5389-e535-4f36-9232-ed59c67375d1 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0   | stable  | 1.0        |
      | e4fa628e-593d-48bc-8e3e-5e4dda1f2c3a | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0   | stable  | 1.0        |
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$0/upgrade"
    Then the response status should be "404"

  Scenario: Admin retrieves an upgrade for a product release (no upgrade available)
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name     |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test App |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | version | channel |
      | fffa0764-3a19-48ea-beb3-8950563c7357 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0   | stable  |
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$0/upgrade"
    Then the response status should be "404"

  # Environments
  @ee
  Scenario: Environment retrieves an upgrade for an isolated release (upgrade available)
    Given the current account is "test1"
    And the current account has the following "environment" rows:
      | id                                   | name     | code     | isolation_strategy |
      | bf20fe24-351d-47d0-b3c3-2c576a63d22f | Isolated | isolated | ISOLATED           |
      | 60e7f35f-5401-4cc2-abd3-999b2a758ee1 | Shared   | shared   | SHARED             |
    And the current account has the following "product" rows:
      | id                                   | environment_id                       | name         |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | Isolated App |
      | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c |                                      | Mixed App   |
    And the current account has the following "release" rows:
      | id                                   | environment_id                       | product_id                           | version | channel |
      | e26e9fef-d1ce-43d3-a15c-c8fc94429709 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0   | stable  |
      | ff04d1c4-cc04-4d19-985a-cb113827b821 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.2.0   | stable  |
      | c8b55f91-e66f-4093-ae4d-7f3d390eae8d | bf20fe24-351d-47d0-b3c3-2c576a63d22f | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.1   | stable  |
      | dde54ea8-731d-4375-9d57-186ef01f3fcb | bf20fe24-351d-47d0-b3c3-2c576a63d22f | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.0   | stable  |
      | a7fad100-04eb-418f-8af9-e5eac497ad5a | bf20fe24-351d-47d0-b3c3-2c576a63d22f | 6198261a-48b5-4445-a045-9fed4afc7735 | 4.3.0   | stable  |
      | 1c7e3e60-248c-4149-9583-26f4d8f99c78 |                                      | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | 2.0.0   | stable  |
      | d79f5ffb-f772-4232-94d5-c5563c431ff9 | 60e7f35f-5401-4cc2-abd3-999b2a758ee1 | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | 3.0.0   | stable  |
    And I am the first environment of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/c8b55f91-e66f-4093-ae4d-7f3d390eae8d/upgrade?environment=isolated"
    Then the response status should be "200"
    And the response body should be a "release" with the following attributes:
      """
      { "version": "4.3.0" }
      """
    And the response body should contain meta which includes the following:
      """
      {
        "current": "1.0.1",
        "next": "4.3.0"
      }
      """

  @ee
  Scenario: Environment retrieves an upgrade for a shared release (no upgrade available)
    Given the current account is "test1"
    And the current account has the following "environment" rows:
      | id                                   | name     | code     | isolation_strategy |
      | bf20fe24-351d-47d0-b3c3-2c576a63d22f | Isolated | isolated | ISOLATED           |
      | 60e7f35f-5401-4cc2-abd3-999b2a758ee1 | Shared   | shared   | SHARED             |
    And the current account has the following "product" rows:
      | id                                   | environment_id                       | name         |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | Isolated App |
      | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c |                                      | Mixed App   |
    And the current account has the following "release" rows:
      | id                                   | environment_id                       | product_id                           | version | channel |
      | e26e9fef-d1ce-43d3-a15c-c8fc94429709 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0   | stable  |
      | ff04d1c4-cc04-4d19-985a-cb113827b821 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.2.0   | stable  |
      | c8b55f91-e66f-4093-ae4d-7f3d390eae8d | bf20fe24-351d-47d0-b3c3-2c576a63d22f | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.1   | stable  |
      | dde54ea8-731d-4375-9d57-186ef01f3fcb | bf20fe24-351d-47d0-b3c3-2c576a63d22f | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.0   | stable  |
      | a7fad100-04eb-418f-8af9-e5eac497ad5a | bf20fe24-351d-47d0-b3c3-2c576a63d22f | 6198261a-48b5-4445-a045-9fed4afc7735 | 4.3.0   | stable  |
      | 1c7e3e60-248c-4149-9583-26f4d8f99c78 |                                      | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | 2.0.0   | stable  |
      | d79f5ffb-f772-4232-94d5-c5563c431ff9 | 60e7f35f-5401-4cc2-abd3-999b2a758ee1 | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | 3.0.0   | stable  |
    And I am the second environment of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/d79f5ffb-f772-4232-94d5-c5563c431ff9/upgrade?environment=shared"
    Then the response status should be "404"

  # Products
  Scenario: Product retrieves an upgrade for a release (upgrade available)
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name     |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test App |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | version | channel |
      | e26e9fef-d1ce-43d3-a15c-c8fc94429709 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0   | stable  |
      | ff04d1c4-cc04-4d19-985a-cb113827b821 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.2.0   | stable  |
      | c8b55f91-e66f-4093-ae4d-7f3d390eae8d | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.1   | stable  |
      | dde54ea8-731d-4375-9d57-186ef01f3fcb | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.0   | stable  |
      | a7fad100-04eb-418f-8af9-e5eac497ad5a | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.3.0   | stable  |
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$0/upgrade"
    Then the response status should be "200"
    And the response body should be a "release" with the following attributes:
      """
      { "version": "1.3.0" }
      """
    And the response body should contain meta which includes the following:
      """
      {
        "current": "1.0.0",
        "next": "1.3.0"
      }
      """

  Scenario: Product retrieves an upgrade for a release (no upgrade available)
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name     |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test App |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | version | channel |
      | e26e9fef-d1ce-43d3-a15c-c8fc94429709 | 6198261a-48b5-4445-a045-9fed4afc7735 | 0.1.0   | stable  |
      | ff04d1c4-cc04-4d19-985a-cb113827b821 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0   | stable  |
      | c8b55f91-e66f-4093-ae4d-7f3d390eae8d | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0   | stable  |
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$2/upgrade"
    Then the response status should be "404"

  Scenario: Product retrieves an upgrade for a release of a different product
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name       |
      | 6ac37cee-0027-4cdb-ba25-ac98fa0d29b4 | Test App A |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test App B |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | version | channel |
      | e26e9fef-d1ce-43d3-a15c-c8fc94429709 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0   | stable  |
      | ff04d1c4-cc04-4d19-985a-cb113827b821 | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0   | stable  |
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$0/upgrade"
    Then the response status should be "404"

  # Licenses
  Scenario: License retrieves an upgrade for a release of their product (upgrade available)
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name     |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test App |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | version      | channel |
      | e314ba5d-c760-4e54-81c4-fa01af68ff66 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0        | stable  |
      | e26e9fef-d1ce-43d3-a15c-c8fc94429709 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.2.0        | stable  |
      | ff04d1c4-cc04-4d19-985a-cb113827b821 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.1        | stable  |
      | c8b55f91-e66f-4093-ae4d-7f3d390eae8d | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.0        | stable  |
      | dde54ea8-731d-4375-9d57-186ef01f3fcb | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.3.0        | stable  |
      | a7fad100-04eb-418f-8af9-e5eac497ad5a | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0-beta.1 | beta    |
    And the current account has 1 "policy" for the first "product"
    And the current account has 1 "license" for the first "policy"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$2/upgrade"
    Then the response status should be "200"
    And the response body should be a "release" with the following attributes:
      """
      { "version": "1.3.0" }
      """
    And the response body should contain meta which includes the following:
      """
      {
        "current": "1.0.1",
        "next": "1.3.0"
      }
      """

  Scenario: License retrieves an upgrade for a release of their product (expired, but access revoked)
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name     |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test App |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | created_at           | version      | channel |
      | e314ba5d-c760-4e54-81c4-fa01af68ff66 | 6198261a-48b5-4445-a045-9fed4afc7735 | 2024-01-01T00:00:00Z | 1.0.0        | stable  |
      | e26e9fef-d1ce-43d3-a15c-c8fc94429709 | 6198261a-48b5-4445-a045-9fed4afc7735 | 2024-03-01T00:00:00Z | 1.2.0        | stable  |
      | ff04d1c4-cc04-4d19-985a-cb113827b821 | 6198261a-48b5-4445-a045-9fed4afc7735 | 2024-01-02T00:00:00Z | 1.0.1        | stable  |
      | c8b55f91-e66f-4093-ae4d-7f3d390eae8d | 6198261a-48b5-4445-a045-9fed4afc7735 | 2024-02-01T00:00:00Z | 1.1.0        | stable  |
      | dde54ea8-731d-4375-9d57-186ef01f3fcb | 6198261a-48b5-4445-a045-9fed4afc7735 | 2024-04-01T00:00:00Z | 1.3.0        | stable  |
      | a7fad100-04eb-418f-8af9-e5eac497ad5a | 6198261a-48b5-4445-a045-9fed4afc7735 | 2024-05-01T00:00:00Z | 2.0.0-beta.1 | beta    |
    And the current account has 1 "policy" for the first "product"
    And the first "policy" has the following attributes:
      """
      { "expirationStrategy": "REVOKE_ACCESS" }
      """
    And the current account has 1 "license" for the first "policy"
    And the first "license" has the following attributes:
      """
      { "expiry": "2024-03-02T00:00:00Z" }
      """
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/1.0.0/upgrade"
    Then the response status should be "404"

  Scenario: License retrieves an upgrade for a release of their product (expired, out of date, but access restricted)
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name     |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test App |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | created_at           | version      | channel |
      | e314ba5d-c760-4e54-81c4-fa01af68ff66 | 6198261a-48b5-4445-a045-9fed4afc7735 | 2024-01-01T00:00:00Z | 1.0.0        | stable  |
      | e26e9fef-d1ce-43d3-a15c-c8fc94429709 | 6198261a-48b5-4445-a045-9fed4afc7735 | 2024-03-01T00:00:00Z | 1.2.0        | stable  |
      | ff04d1c4-cc04-4d19-985a-cb113827b821 | 6198261a-48b5-4445-a045-9fed4afc7735 | 2024-01-02T00:00:00Z | 1.0.1        | stable  |
      | c8b55f91-e66f-4093-ae4d-7f3d390eae8d | 6198261a-48b5-4445-a045-9fed4afc7735 | 2024-02-01T00:00:00Z | 1.1.0        | stable  |
      | dde54ea8-731d-4375-9d57-186ef01f3fcb | 6198261a-48b5-4445-a045-9fed4afc7735 | 2024-04-01T00:00:00Z | 1.3.0        | stable  |
      | a7fad100-04eb-418f-8af9-e5eac497ad5a | 6198261a-48b5-4445-a045-9fed4afc7735 | 2024-05-01T00:00:00Z | 2.0.0-beta.1 | beta    |
    And the current account has 1 "policy" for the first "product"
    And the first "policy" has the following attributes:
      """
      { "expirationStrategy": "RESTRICT_ACCESS" }
      """
    And the current account has 1 "license" for the first "policy"
    And the first "license" has the following attributes:
      """
      { "expiry": "2024-03-02T00:00:00Z" }
      """
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/1.1.0/upgrade"
    Then the response status should be "200"
    And the response body should be a "release" with the following attributes:
      """
      { "version": "1.2.0" }
      """
    And the response body should contain meta which includes the following:
      """
      {
        "current": "1.1.0",
        "next": "1.2.0"
      }
      """

  Scenario: License retrieves an upgrade for a release of their product (expired, out of date, backdated, but access restricted)
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name     |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test App |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | created_at           | version      | channel | backdated_to         |
      | e314ba5d-c760-4e54-81c4-fa01af68ff66 | 6198261a-48b5-4445-a045-9fed4afc7735 | 2024-01-01T00:00:00Z | 1.0.0        | stable  |                      |
      | e26e9fef-d1ce-43d3-a15c-c8fc94429709 | 6198261a-48b5-4445-a045-9fed4afc7735 | 2024-03-01T00:00:00Z | 1.2.0        | stable  |                      |
      | ff04d1c4-cc04-4d19-985a-cb113827b821 | 6198261a-48b5-4445-a045-9fed4afc7735 | 2024-01-02T00:00:00Z | 1.0.1        | stable  |                      |
      | c8b55f91-e66f-4093-ae4d-7f3d390eae8d | 6198261a-48b5-4445-a045-9fed4afc7735 | 2024-02-01T00:00:00Z | 1.1.0        | stable  |                      |
      | dde54ea8-731d-4375-9d57-186ef01f3fcb | 6198261a-48b5-4445-a045-9fed4afc7735 | 2024-04-01T00:00:00Z | 1.3.0        | stable  |                      |
      | a7fad100-04eb-418f-8af9-e5eac497ad5a | 6198261a-48b5-4445-a045-9fed4afc7735 | 2024-05-01T00:00:00Z | 2.0.0-beta.1 | beta    |                      |
      | 40432355-6af5-4978-a509-b8c24f879844 | 6198261a-48b5-4445-a045-9fed4afc7735 | 2024-06-01T00:00:00Z | 1.2.1        | stable  | 2024-01-01T00:00:00Z |
    And the current account has 1 "policy" for the first "product"
    And the first "policy" has the following attributes:
      """
      { "expirationStrategy": "RESTRICT_ACCESS" }
      """
    And the current account has 1 "license" for the first "policy"
    And the first "license" has the following attributes:
      """
      { "expiry": "2024-03-02T00:00:00Z" }
      """
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/1.1.0/upgrade"
    Then the response status should be "200"
    And the response body should be a "release" with the following attributes:
      """
      { "version": "1.2.1" }
      """
    And the response body should contain meta which includes the following:
      """
      {
        "current": "1.1.0",
        "next": "1.2.1"
      }
      """

  Scenario: License retrieves an upgrade for a release of their product (expired, up to date, but access restricted)
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name     |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test App |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | created_at           | version      | channel |
      | e314ba5d-c760-4e54-81c4-fa01af68ff66 | 6198261a-48b5-4445-a045-9fed4afc7735 | 2024-01-01T00:00:00Z | 1.0.0        | stable  |
      | e26e9fef-d1ce-43d3-a15c-c8fc94429709 | 6198261a-48b5-4445-a045-9fed4afc7735 | 2024-03-01T00:00:00Z | 1.2.0        | stable  |
      | ff04d1c4-cc04-4d19-985a-cb113827b821 | 6198261a-48b5-4445-a045-9fed4afc7735 | 2024-01-02T00:00:00Z | 1.0.1        | stable  |
      | c8b55f91-e66f-4093-ae4d-7f3d390eae8d | 6198261a-48b5-4445-a045-9fed4afc7735 | 2024-02-01T00:00:00Z | 1.1.0        | stable  |
      | dde54ea8-731d-4375-9d57-186ef01f3fcb | 6198261a-48b5-4445-a045-9fed4afc7735 | 2024-04-01T00:00:00Z | 1.3.0        | stable  |
      | a7fad100-04eb-418f-8af9-e5eac497ad5a | 6198261a-48b5-4445-a045-9fed4afc7735 | 2024-05-01T00:00:00Z | 2.0.0-beta.1 | beta    |
    And the current account has 1 "policy" for the first "product"
    And the first "policy" has the following attributes:
      """
      { "expirationStrategy": "RESTRICT_ACCESS" }
      """
    And the current account has 1 "license" for the first "policy"
    And the first "license" has the following attributes:
      """
      { "expiry": "2024-03-02T00:00:00Z" }
      """
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/1.2.0/upgrade"
    Then the response status should be "404"

  Scenario: License retrieves an upgrade for a release of their product (expired, out of date, but access maintained)
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name     |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test App |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | created_at           | version      | channel |
      | e314ba5d-c760-4e54-81c4-fa01af68ff66 | 6198261a-48b5-4445-a045-9fed4afc7735 | 2024-01-01T00:00:00Z | 1.0.0        | stable  |
      | e26e9fef-d1ce-43d3-a15c-c8fc94429709 | 6198261a-48b5-4445-a045-9fed4afc7735 | 2024-03-01T00:00:00Z | 1.2.0        | stable  |
      | ff04d1c4-cc04-4d19-985a-cb113827b821 | 6198261a-48b5-4445-a045-9fed4afc7735 | 2024-01-02T00:00:00Z | 1.0.1        | stable  |
      | c8b55f91-e66f-4093-ae4d-7f3d390eae8d | 6198261a-48b5-4445-a045-9fed4afc7735 | 2024-02-01T00:00:00Z | 1.1.0        | stable  |
      | dde54ea8-731d-4375-9d57-186ef01f3fcb | 6198261a-48b5-4445-a045-9fed4afc7735 | 2024-04-01T00:00:00Z | 1.3.0        | stable  |
      | a7fad100-04eb-418f-8af9-e5eac497ad5a | 6198261a-48b5-4445-a045-9fed4afc7735 | 2024-05-01T00:00:00Z | 2.0.0-beta.1 | beta    |
    And the current account has 1 "policy" for the first "product"
    And the first "policy" has the following attributes:
      """
      { "expirationStrategy": "MAINTAIN_ACCESS" }
      """
    And the current account has 1 "license" for the first "policy"
    And the first "license" has the following attributes:
      """
      { "expiry": "2024-03-01T00:00:00Z" }
      """
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/1.0.1/upgrade"
    Then the response status should be "200"
    And the response body should contain meta which includes the following:
      """
      {
        "current": "1.0.1",
        "next": "1.2.0"
      }
      """

  Scenario: License retrieves an upgrade for a release of their product (expired, out of date, backdated, but access maintained)
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name     |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test App |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | created_at           | version      | channel | backdated_to         |
      | e314ba5d-c760-4e54-81c4-fa01af68ff66 | 6198261a-48b5-4445-a045-9fed4afc7735 | 2024-01-01T00:00:00Z | 1.0.0        | stable  |                      |
      | e26e9fef-d1ce-43d3-a15c-c8fc94429709 | 6198261a-48b5-4445-a045-9fed4afc7735 | 2024-03-01T00:00:00Z | 1.2.0        | stable  |                      |
      | ff04d1c4-cc04-4d19-985a-cb113827b821 | 6198261a-48b5-4445-a045-9fed4afc7735 | 2024-01-02T00:00:00Z | 1.0.1        | stable  |                      |
      | c8b55f91-e66f-4093-ae4d-7f3d390eae8d | 6198261a-48b5-4445-a045-9fed4afc7735 | 2024-02-01T00:00:00Z | 1.1.0        | stable  |                      |
      | dde54ea8-731d-4375-9d57-186ef01f3fcb | 6198261a-48b5-4445-a045-9fed4afc7735 | 2024-04-01T00:00:00Z | 1.3.0        | stable  |                      |
      | a7fad100-04eb-418f-8af9-e5eac497ad5a | 6198261a-48b5-4445-a045-9fed4afc7735 | 2024-05-01T00:00:00Z | 2.0.0-beta.1 | beta    |                      |
      | 40432355-6af5-4978-a509-b8c24f879844 | 6198261a-48b5-4445-a045-9fed4afc7735 | 2024-06-01T00:00:00Z | 1.2.1        | stable  | 2024-01-01T00:00:00Z |
    And the current account has 1 "policy" for the first "product"
    And the first "policy" has the following attributes:
      """
      { "expirationStrategy": "MAINTAIN_ACCESS" }
      """
    And the current account has 1 "license" for the first "policy"
    And the first "license" has the following attributes:
      """
      { "expiry": "2024-03-01T00:00:00Z" }
      """
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/1.0.1/upgrade"
    Then the response status should be "200"
    And the response body should be a "release" with the following attributes:
      """
      { "version": "1.2.1" }
      """
    And the response body should contain meta which includes the following:
      """
      {
        "current": "1.0.1",
        "next": "1.2.1"
      }
      """

  Scenario: License retrieves an upgrade for a release of their product (expired, up to date, but access maintained)
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name     |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test App |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | created_at           | version      | channel |
      | e314ba5d-c760-4e54-81c4-fa01af68ff66 | 6198261a-48b5-4445-a045-9fed4afc7735 | 2024-01-01T00:00:00Z | 1.0.0        | stable  |
      | e26e9fef-d1ce-43d3-a15c-c8fc94429709 | 6198261a-48b5-4445-a045-9fed4afc7735 | 2024-03-01T00:00:00Z | 1.2.0        | stable  |
      | ff04d1c4-cc04-4d19-985a-cb113827b821 | 6198261a-48b5-4445-a045-9fed4afc7735 | 2024-01-02T00:00:00Z | 1.0.1        | stable  |
      | c8b55f91-e66f-4093-ae4d-7f3d390eae8d | 6198261a-48b5-4445-a045-9fed4afc7735 | 2024-02-01T00:00:00Z | 1.1.0        | stable  |
      | dde54ea8-731d-4375-9d57-186ef01f3fcb | 6198261a-48b5-4445-a045-9fed4afc7735 | 2024-04-01T00:00:00Z | 1.3.0        | stable  |
      | a7fad100-04eb-418f-8af9-e5eac497ad5a | 6198261a-48b5-4445-a045-9fed4afc7735 | 2024-05-01T00:00:00Z | 2.0.0-beta.1 | beta    |
    And the current account has 1 "policy" for the first "product"
    And the first "policy" has the following attributes:
      """
      { "expirationStrategy": "MAINTAIN_ACCESS" }
      """
    And the current account has 1 "license" for the first "policy"
    And the first "license" has the following attributes:
      """
      { "expiry": "2024-03-01T00:00:00Z" }
      """
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/1.2.0/upgrade"
    Then the response status should be "404"

  Scenario: License retrieves an upgrade for a release of their product (valid, but access maintained)
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name     |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test App |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | created_at           | version      | channel |
      | e314ba5d-c760-4e54-81c4-fa01af68ff66 | 6198261a-48b5-4445-a045-9fed4afc7735 | 2024-01-01T00:00:00Z | 1.0.0        | stable  |
      | e26e9fef-d1ce-43d3-a15c-c8fc94429709 | 6198261a-48b5-4445-a045-9fed4afc7735 | 2024-03-01T00:00:00Z | 1.2.0        | stable  |
      | ff04d1c4-cc04-4d19-985a-cb113827b821 | 6198261a-48b5-4445-a045-9fed4afc7735 | 2024-01-02T00:00:00Z | 1.0.1        | stable  |
      | c8b55f91-e66f-4093-ae4d-7f3d390eae8d | 6198261a-48b5-4445-a045-9fed4afc7735 | 2024-02-01T00:00:00Z | 1.1.0        | stable  |
      | dde54ea8-731d-4375-9d57-186ef01f3fcb | 6198261a-48b5-4445-a045-9fed4afc7735 | 2024-04-01T00:00:00Z | 1.3.0        | stable  |
      | a7fad100-04eb-418f-8af9-e5eac497ad5a | 6198261a-48b5-4445-a045-9fed4afc7735 | 2024-05-01T00:00:00Z | 2.0.0-beta.1 | beta    |
    And the current account has 1 "policy" for the first "product"
    And the first "policy" has the following attributes:
      """
      { "expirationStrategy": "MAINTAIN_ACCESS" }
      """
    And the current account has 1 "license" for the first "policy"
    And the first "license" has the following attributes:
      """
      { "expiry": "2025-01-01T00:00:00Z" }
      """
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/1.0.1/upgrade"
    Then the response status should be "200"
    And the response body should contain meta which includes the following:
      """
      {
        "current": "1.0.1",
        "next": "1.3.0"
      }
      """

  Scenario: License retrieves an upgrade for a release of their product (expired, access allowed)
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name     |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test App |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | created_at           | version      | channel |
      | e314ba5d-c760-4e54-81c4-fa01af68ff66 | 6198261a-48b5-4445-a045-9fed4afc7735 | 2024-01-01T00:00:00Z | 1.0.0        | stable  |
      | e26e9fef-d1ce-43d3-a15c-c8fc94429709 | 6198261a-48b5-4445-a045-9fed4afc7735 | 2024-03-01T00:00:00Z | 1.2.0        | stable  |
      | ff04d1c4-cc04-4d19-985a-cb113827b821 | 6198261a-48b5-4445-a045-9fed4afc7735 | 2024-01-02T00:00:00Z | 1.0.1        | stable  |
      | c8b55f91-e66f-4093-ae4d-7f3d390eae8d | 6198261a-48b5-4445-a045-9fed4afc7735 | 2024-02-01T00:00:00Z | 1.1.0        | stable  |
      | dde54ea8-731d-4375-9d57-186ef01f3fcb | 6198261a-48b5-4445-a045-9fed4afc7735 | 2024-04-01T00:00:00Z | 1.3.0        | stable  |
      | a7fad100-04eb-418f-8af9-e5eac497ad5a | 6198261a-48b5-4445-a045-9fed4afc7735 | 2024-05-01T00:00:00Z | 2.0.0-beta.1 | beta    |
    And the current account has 1 "policy" for the first "product"
    And the first "policy" has the following attributes:
      """
      { "expirationStrategy": "ALLOW_ACCESS" }
      """
    And the current account has 1 "license" for the first "policy"
    And the first "license" has the following attributes:
      """
      { "expiry": "2024-01-01T00:00:00Z" }
      """
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/1.0.1/upgrade"
    Then the response status should be "200"
    And the response body should contain meta which includes the following:
      """
      {
        "current": "1.0.1",
        "next": "1.3.0"
      }
      """

  Scenario: License retrieves an upgrade for a release of their product (suspended)
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name     |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test App |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | version      | channel |
      | e314ba5d-c760-4e54-81c4-fa01af68ff66 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0        | stable  |
      | e26e9fef-d1ce-43d3-a15c-c8fc94429709 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.2.0        | stable  |
      | ff04d1c4-cc04-4d19-985a-cb113827b821 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.1        | stable  |
      | c8b55f91-e66f-4093-ae4d-7f3d390eae8d | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.0        | stable  |
      | dde54ea8-731d-4375-9d57-186ef01f3fcb | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.3.0        | stable  |
      | a7fad100-04eb-418f-8af9-e5eac497ad5a | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0-beta.1 | beta    |
    And the current account has 1 "policy" for the first "product"
    And the current account has 1 "license" for the first "policy"
    And the first "license" has the following attributes:
      """
      { "suspended": true }
      """
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$2/upgrade"
    Then the response status should be "403"

  Scenario: License retrieves an upgrade for a release of their product (key auth, expired, but access restricted)
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name     |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test App |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | created_at           | version      | channel |
      | e314ba5d-c760-4e54-81c4-fa01af68ff66 | 6198261a-48b5-4445-a045-9fed4afc7735 | 2024-01-01T00:00:00Z | 1.0.0        | stable  |
      | e26e9fef-d1ce-43d3-a15c-c8fc94429709 | 6198261a-48b5-4445-a045-9fed4afc7735 | 2024-03-01T00:00:00Z | 1.2.0        | stable  |
      | ff04d1c4-cc04-4d19-985a-cb113827b821 | 6198261a-48b5-4445-a045-9fed4afc7735 | 2024-01-02T00:00:00Z | 1.0.1        | stable  |
      | c8b55f91-e66f-4093-ae4d-7f3d390eae8d | 6198261a-48b5-4445-a045-9fed4afc7735 | 2024-02-01T00:00:00Z | 1.1.0        | stable  |
      | dde54ea8-731d-4375-9d57-186ef01f3fcb | 6198261a-48b5-4445-a045-9fed4afc7735 | 2024-04-01T00:00:00Z | 1.3.0        | stable  |
      | a7fad100-04eb-418f-8af9-e5eac497ad5a | 6198261a-48b5-4445-a045-9fed4afc7735 | 2024-05-01T00:00:00Z | 2.0.0-beta.1 | beta    |
    And the current account has 1 "policy" for the first "product"
    And the first "policy" has the following attributes:
      """
      {
        "expirationStrategy": "RESTRICT_ACCESS",
        "authenticationStrategy": "LICENSE"
      }
      """
    And the current account has 1 "license" for the first "policy"
    And the first "license" has the following attributes:
      """
      { "expiry": "2024-02-01T00:00:00Z" }
      """
    And I am a license of account "test1"
    And I authenticate with my key
    When I send a GET request to "/accounts/test1/releases/1.0.1/upgrade"
    Then the response status should be "200"
    And the response body should contain meta which includes the following:
      """
      {
        "current": "1.0.1",
        "next": "1.1.0"
      }
      """

  Scenario: License retrieves an upgrade for a release of their product (key auth, expired, but access allowed)
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name     |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test App |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | created_at           | version      | channel |
      | e314ba5d-c760-4e54-81c4-fa01af68ff66 | 6198261a-48b5-4445-a045-9fed4afc7735 | 2024-01-01T00:00:00Z | 1.0.0        | stable  |
      | e26e9fef-d1ce-43d3-a15c-c8fc94429709 | 6198261a-48b5-4445-a045-9fed4afc7735 | 2024-03-01T00:00:00Z | 1.2.0        | stable  |
      | ff04d1c4-cc04-4d19-985a-cb113827b821 | 6198261a-48b5-4445-a045-9fed4afc7735 | 2024-01-02T00:00:00Z | 1.0.1        | stable  |
      | c8b55f91-e66f-4093-ae4d-7f3d390eae8d | 6198261a-48b5-4445-a045-9fed4afc7735 | 2024-02-01T00:00:00Z | 1.1.0        | stable  |
      | dde54ea8-731d-4375-9d57-186ef01f3fcb | 6198261a-48b5-4445-a045-9fed4afc7735 | 2024-04-01T00:00:00Z | 1.3.0        | stable  |
      | a7fad100-04eb-418f-8af9-e5eac497ad5a | 6198261a-48b5-4445-a045-9fed4afc7735 | 2024-05-01T00:00:00Z | 2.0.0-beta.1 | beta    |
    And the current account has 1 "policy" for the first "product"
    And the first "policy" has the following attributes:
      """
      {
        "expirationStrategy": "ALLOW_ACCESS",
        "authenticationStrategy": "LICENSE"
      }
      """
    And the current account has 1 "license" for the first "policy"
    And the first "license" has the following attributes:
      """
      { "expiry": "2024-02-01T00:00:00Z" }
      """
    And I am a license of account "test1"
    And I authenticate with my key
    When I send a GET request to "/accounts/test1/releases/1.2.0/upgrade"
    Then the response status should be "200"
    And the response body should contain meta which includes the following:
      """
      {
        "current": "1.2.0",
        "next": "1.3.0"
      }
      """

  Scenario: License retrieves an upgrade for a release of their product (key auth, expired, but access revoked)
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name     |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test App |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | created_at           | version      | channel |
      | e314ba5d-c760-4e54-81c4-fa01af68ff66 | 6198261a-48b5-4445-a045-9fed4afc7735 | 2024-01-01T00:00:00Z | 1.0.0        | stable  |
      | e26e9fef-d1ce-43d3-a15c-c8fc94429709 | 6198261a-48b5-4445-a045-9fed4afc7735 | 2024-03-01T00:00:00Z | 1.2.0        | stable  |
      | ff04d1c4-cc04-4d19-985a-cb113827b821 | 6198261a-48b5-4445-a045-9fed4afc7735 | 2024-01-02T00:00:00Z | 1.0.1        | stable  |
      | c8b55f91-e66f-4093-ae4d-7f3d390eae8d | 6198261a-48b5-4445-a045-9fed4afc7735 | 2024-02-01T00:00:00Z | 1.1.0        | stable  |
      | dde54ea8-731d-4375-9d57-186ef01f3fcb | 6198261a-48b5-4445-a045-9fed4afc7735 | 2024-04-01T00:00:00Z | 1.3.0        | stable  |
      | a7fad100-04eb-418f-8af9-e5eac497ad5a | 6198261a-48b5-4445-a045-9fed4afc7735 | 2024-05-01T00:00:00Z | 2.0.0-beta.1 | beta    |
    And the current account has 1 "policy" for the first "product"
    And the first "policy" has the following attributes:
      """
      {
        "expirationStrategy": "REVOKE_ACCESS",
        "authenticationStrategy": "LICENSE"
      }
      """
    And the current account has 1 "license" for the first "policy"
    And the first "license" has the following attributes:
      """
      { "expiry": "2024-02-01T00:00:00Z" }
      """
    And I am a license of account "test1"
    And I authenticate with my key
    When I send a GET request to "/accounts/test1/releases/$2/upgrade"
    Then the response status should be "403"
    And the first error should have the following properties:
      """
      {
        "title": "Access denied",
        "detail": "License is expired",
        "code": "LICENSE_EXPIRED"
      }
      """

  Scenario: License retrieves an upgrade for a release of their product (key auth, suspended)
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name     |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test App |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | version      | channel |
      | e314ba5d-c760-4e54-81c4-fa01af68ff66 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0        | stable  |
      | e26e9fef-d1ce-43d3-a15c-c8fc94429709 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.2.0        | stable  |
      | ff04d1c4-cc04-4d19-985a-cb113827b821 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.1        | stable  |
      | c8b55f91-e66f-4093-ae4d-7f3d390eae8d | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.0        | stable  |
      | dde54ea8-731d-4375-9d57-186ef01f3fcb | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.3.0        | stable  |
      | a7fad100-04eb-418f-8af9-e5eac497ad5a | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0-beta.1 | beta    |
    And the current account has 1 "policy" for the first "product"
    And the first "policy" has the following attributes:
      """
      { "authenticationStrategy": "LICENSE" }
      """
    And the current account has 1 "license" for the first "policy"
    And the first "license" has the following attributes:
      """
      { "suspended": true }
      """
    And I am a license of account "test1"
    And I authenticate with my key
    When I send a GET request to "/accounts/test1/releases/$2/upgrade"
    Then the response status should be "403"
    And the first error should have the following properties:
      """
      {
        "title": "Access denied",
        "detail": "License is suspended",
        "code": "LICENSE_SUSPENDED"
      }
      """

  Scenario: License retrieves an upgrade for a release of a different product
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name     |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test App |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | version      | channel |
      | e314ba5d-c760-4e54-81c4-fa01af68ff66 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0        | stable  |
      | e26e9fef-d1ce-43d3-a15c-c8fc94429709 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.2.0        | stable  |
      | ff04d1c4-cc04-4d19-985a-cb113827b821 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.1        | stable  |
      | c8b55f91-e66f-4093-ae4d-7f3d390eae8d | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.0        | stable  |
      | dde54ea8-731d-4375-9d57-186ef01f3fcb | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.3.0        | stable  |
      | a7fad100-04eb-418f-8af9-e5eac497ad5a | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0-beta.1 | beta    |
    And the current account has 1 "license"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$2/upgrade"
    Then the response status should be "404"

  Scenario: License retrieves an upgrade for a release of their product (has single entitlement)
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name     |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test App |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | version | channel |
      | e314ba5d-c760-4e54-81c4-fa01af68ff66 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0   | stable  |
      | e26e9fef-d1ce-43d3-a15c-c8fc94429709 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.0   | stable  |
      | ff04d1c4-cc04-4d19-985a-cb113827b821 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.2.0   | stable  |
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
    When I send a GET request to "/accounts/test1/releases/$0/upgrade"
    Then the response status should be "200"
    And the response body should be a "release" with the following attributes:
      """
      { "version": "1.2.0" }
      """
    And the response body should contain meta which includes the following:
      """
      {
        "current": "1.0.0",
        "next": "1.2.0"
      }
      """

  Scenario: License retrieves an upgrade for a release of their product (has multiple entitlements)
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name     |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test App |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | version       | channel |
      | e314ba5d-c760-4e54-81c4-fa01af68ff66 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0-alpha.1 | alpha   |
      | e26e9fef-d1ce-43d3-a15c-c8fc94429709 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0         | stable  |
      | ff04d1c4-cc04-4d19-985a-cb113827b821 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.1-alpha.1 | stable  |
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
    When I send a GET request to "/accounts/test1/releases/$0/upgrade"
    Then the response status should be "200"
    And the response body should be a "release" with the following attributes:
      """
      { "version": "1.0.1-alpha.1" }
      """
    And the response body should contain meta which includes the following:
      """
      {
        "current": "1.0.0-alpha.1",
        "next": "1.0.1-alpha.1"
      }
      """

  Scenario: License retrieves an upgrade for a release of their product (missing some entitlements)
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name     |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test App |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | version       | channel |
      | e314ba5d-c760-4e54-81c4-fa01af68ff66 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0-alpha.1 | alpha   |
      | e26e9fef-d1ce-43d3-a15c-c8fc94429709 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0         | stable  |
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
    When I send a GET request to "/accounts/test1/releases/$0/upgrade"
    Then the response status should be "404"

  Scenario: License retrieves an upgrade for a release of their product (missing all entitlements)
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name     |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test App |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | version       | channel |
      | e314ba5d-c760-4e54-81c4-fa01af68ff66 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0-alpha.1 | alpha   |
      | e26e9fef-d1ce-43d3-a15c-c8fc94429709 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0         | stable  |
    And the current account has 1 "policy" for an existing "product"
    And the current account has 1 "license" for an existing "policy"
    And the current account has 2 "release-entitlement-constraints" for the first "release"
    And the current account has 2 "release-entitlement-constraints" for the second "release"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$0/upgrade"
    Then the response status should be "404"

  @ce
  Scenario: License retrieves an upgrade for a shared release
    Given the current account is "test1"
    And the current account has the following "environment" rows:
      | id                                   | name   | code   | isolation_strategy |
      | 19e494c9-42b3-463d-b29e-8212049c2e79 | Shared | shared | SHARED             |
    And the current account has the following "product" rows:
      | id                                   | name     |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test App |
    And the current account has the following "release" rows:
      | id                                   | environment_id                       | product_id                           | version      | channel |
      | e314ba5d-c760-4e54-81c4-fa01af68ff66 | 19e494c9-42b3-463d-b29e-8212049c2e79 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0        | stable  |
      | e26e9fef-d1ce-43d3-a15c-c8fc94429709 | 19e494c9-42b3-463d-b29e-8212049c2e79 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.2.0        | stable  |
      | ff04d1c4-cc04-4d19-985a-cb113827b821 | 19e494c9-42b3-463d-b29e-8212049c2e79 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.1        | stable  |
      | c8b55f91-e66f-4093-ae4d-7f3d390eae8d | 19e494c9-42b3-463d-b29e-8212049c2e79 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.0        | stable  |
      | dde54ea8-731d-4375-9d57-186ef01f3fcb | 19e494c9-42b3-463d-b29e-8212049c2e79 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.3.0        | stable  |
      | a7fad100-04eb-418f-8af9-e5eac497ad5a | 19e494c9-42b3-463d-b29e-8212049c2e79 | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0-beta.1 | beta    |
    And the current account has the following "policy" rows:
      | id                                   | product_id                           | authentication_strategy |
      | f5336a25-89a4-45b8-ad3a-6ccaa6477ef0 | 6198261a-48b5-4445-a045-9fed4afc7735 | LICENSE                 |
    And the current account has the following "license" rows:
      | id                                   | environment_id                       | policy_id                            |
      | a2fde824-2f58-4a89-b01b-75ed9a648ed7 | 19e494c9-42b3-463d-b29e-8212049c2e79 | f5336a25-89a4-45b8-ad3a-6ccaa6477ef0 |
    And I am a license of account "test1"
    And I authenticate with my key
    And I send the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
    When I send a GET request to "/accounts/test1/releases/1.1.0/upgrade"
    Then the response status should be "400"
    And the response body should be an array of 1 error
    And the first error should have the following properties:
      """
      {
        "title": "Bad request",
        "detail": "is unsupported",
        "code": "ENVIRONMENT_NOT_SUPPORTED",
        "source": {
          "header": "Keygen-Environment"
        }
      }
      """
    And the response should contain a valid signature header for "test1"
    And the response should contain the following headers:
      """
      { "Keygen-Environment": null }
      """

  @ee
  Scenario: Isolated license retrieves an upgrade for a isolated release
    Given the current account is "test1"
    And the current account has the following "environment" rows:
      | id                                   | name     | code     | isolation_strategy |
      | 19e494c9-42b3-463d-b29e-8212049c2e79 | Isolated | isolated | ISOLATED           |
    And the current account has the following "product" rows:
      | id                                   | environment_id                       | name     |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 19e494c9-42b3-463d-b29e-8212049c2e79 | Test App |
    And the current account has the following "release" rows:
      | id                                   | environment_id                       | product_id                           | version      | channel |
      | e314ba5d-c760-4e54-81c4-fa01af68ff66 | 19e494c9-42b3-463d-b29e-8212049c2e79 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0        | stable  |
      | e26e9fef-d1ce-43d3-a15c-c8fc94429709 | 19e494c9-42b3-463d-b29e-8212049c2e79 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.2.0        | stable  |
      | ff04d1c4-cc04-4d19-985a-cb113827b821 | 19e494c9-42b3-463d-b29e-8212049c2e79 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.1        | stable  |
      | c8b55f91-e66f-4093-ae4d-7f3d390eae8d | 19e494c9-42b3-463d-b29e-8212049c2e79 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.0        | stable  |
      | dde54ea8-731d-4375-9d57-186ef01f3fcb | 19e494c9-42b3-463d-b29e-8212049c2e79 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.3.0        | stable  |
      | a7fad100-04eb-418f-8af9-e5eac497ad5a | 19e494c9-42b3-463d-b29e-8212049c2e79 | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0-beta.1 | beta    |
    And the current account has the following "policy" rows:
      | id                                   | environment_id                       | product_id                           | authentication_strategy |
      | f5336a25-89a4-45b8-ad3a-6ccaa6477ef0 | 19e494c9-42b3-463d-b29e-8212049c2e79 | 6198261a-48b5-4445-a045-9fed4afc7735 | LICENSE                 |
    And the current account has the following "license" rows:
      | id                                   | environment_id                       | policy_id                            |
      | a2fde824-2f58-4a89-b01b-75ed9a648ed7 | 19e494c9-42b3-463d-b29e-8212049c2e79 | f5336a25-89a4-45b8-ad3a-6ccaa6477ef0 |
    And I am a license of account "test1"
    And I authenticate with my key
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    When I send a GET request to "/accounts/test1/releases/1.1.0/upgrade"
    Then the response status should be "200"
    And the response body should be a "release" with the following attributes:
      """
      { "version": "1.3.0" }
      """
    And the response body should contain meta which includes the following:
      """
      {
        "current": "1.1.0",
        "next": "1.3.0"
      }
      """
    And the response should contain a valid signature header for "test1"
    And the response should contain the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """

  @ee
  Scenario: Shared license retrieves an upgrade for a shared release
    Given the current account is "test1"
    And the current account has the following "environment" rows:
      | id                                   | name   | code   | isolation_strategy |
      | 19e494c9-42b3-463d-b29e-8212049c2e79 | Shared | shared | SHARED             |
    And the current account has the following "product" rows:
      | id                                   | name     |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test App |
    And the current account has the following "release" rows:
      | id                                   | environment_id                       | product_id                           | version      | channel |
      | e314ba5d-c760-4e54-81c4-fa01af68ff66 | 19e494c9-42b3-463d-b29e-8212049c2e79 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0        | stable  |
      | e26e9fef-d1ce-43d3-a15c-c8fc94429709 | 19e494c9-42b3-463d-b29e-8212049c2e79 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.2.0        | stable  |
      | ff04d1c4-cc04-4d19-985a-cb113827b821 | 19e494c9-42b3-463d-b29e-8212049c2e79 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.1        | stable  |
      | c8b55f91-e66f-4093-ae4d-7f3d390eae8d | 19e494c9-42b3-463d-b29e-8212049c2e79 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.0        | stable  |
      | dde54ea8-731d-4375-9d57-186ef01f3fcb | 19e494c9-42b3-463d-b29e-8212049c2e79 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.3.0        | stable  |
      | a7fad100-04eb-418f-8af9-e5eac497ad5a | 19e494c9-42b3-463d-b29e-8212049c2e79 | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0-beta.1 | beta    |
    And the current account has the following "policy" rows:
      | id                                   | product_id                           | authentication_strategy |
      | f5336a25-89a4-45b8-ad3a-6ccaa6477ef0 | 6198261a-48b5-4445-a045-9fed4afc7735 | LICENSE                 |
    And the current account has the following "license" rows:
      | id                                   | environment_id                       | policy_id                            |
      | a2fde824-2f58-4a89-b01b-75ed9a648ed7 | 19e494c9-42b3-463d-b29e-8212049c2e79 | f5336a25-89a4-45b8-ad3a-6ccaa6477ef0 |
    And I am a license of account "test1"
    And I authenticate with my key
    And I send the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
    When I send a GET request to "/accounts/test1/releases/1.1.0/upgrade"
    Then the response status should be "200"
    And the response body should be a "release" with the following attributes:
      """
      { "version": "1.3.0" }
      """
    And the response body should contain meta which includes the following:
      """
      {
        "current": "1.1.0",
        "next": "1.3.0"
      }
      """
    And the response should contain a valid signature header for "test1"
    And the response should contain the following headers:
      """
      { "Keygen-Environment": "shared" }
      """

  @ee
  Scenario: Shared license retrieves an upgrade for a global release
    Given the current account is "test1"
    And the current account has the following "environment" rows:
      | id                                   | name   | code   | isolation_strategy |
      | 19e494c9-42b3-463d-b29e-8212049c2e79 | Shared | shared | SHARED             |
    And the current account has the following "product" rows:
      | id                                   | name     |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test App |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | version      | channel |
      | e314ba5d-c760-4e54-81c4-fa01af68ff66 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0        | stable  |
      | e26e9fef-d1ce-43d3-a15c-c8fc94429709 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.2.0        | stable  |
      | ff04d1c4-cc04-4d19-985a-cb113827b821 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.1        | stable  |
      | c8b55f91-e66f-4093-ae4d-7f3d390eae8d | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.0        | stable  |
      | dde54ea8-731d-4375-9d57-186ef01f3fcb | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.3.0        | stable  |
      | a7fad100-04eb-418f-8af9-e5eac497ad5a | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0-beta.1 | beta    |
    And the current account has the following "policy" rows:
      | id                                   | product_id                           | authentication_strategy |
      | f5336a25-89a4-45b8-ad3a-6ccaa6477ef0 | 6198261a-48b5-4445-a045-9fed4afc7735 | LICENSE                 |
    And the current account has the following "license" rows:
      | id                                   | environment_id                       | policy_id                            |
      | a2fde824-2f58-4a89-b01b-75ed9a648ed7 | 19e494c9-42b3-463d-b29e-8212049c2e79 | f5336a25-89a4-45b8-ad3a-6ccaa6477ef0 |
    And I am a license of account "test1"
    And I authenticate with my key
    And I send the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
    When I send a GET request to "/accounts/test1/releases/1.1.0/upgrade"
    Then the response status should be "200"
    And the response body should be a "release" with the following attributes:
      """
      { "version": "1.3.0" }
      """
    And the response body should contain meta which includes the following:
      """
      {
        "current": "1.1.0",
        "next": "1.3.0"
      }
      """
    And the response should contain a valid signature header for "test1"
    And the response should contain the following headers:
      """
      { "Keygen-Environment": "shared" }
      """

  @ee
  Scenario: Isolated license retrieves an upgrade for an open release (conflicts with shared open release)
    Given the current account is "test1"
    And the current account has the following "environment" rows:
      | id                                   | name     | code     | isolation_strategy |
      | 19e494c9-42b3-463d-b29e-8212049c2e79 | Isolated | isolated | ISOLATED           |
      | 62eb12c9-68eb-4e7e-ba59-d0575b69c3e7 | Shared   | shared   | SHARED             |
    And the current account has the following "product" rows:
      | id                                   | environment_id                       | name         | distribution_strategy |
      | 93bd02ef-4aba-44ac-ab8b-356a4a1d7a4e | 19e494c9-42b3-463d-b29e-8212049c2e79 | Isolated App | OPEN                  |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 62eb12c9-68eb-4e7e-ba59-d0575b69c3e7 | Shared App   | OPEN                  |
    And the current account has the following "release" rows:
      | id                                   | environment_id                       | product_id                           | version      | channel |
      | 85969670-d172-4202-b664-9001b443d1c6 | 19e494c9-42b3-463d-b29e-8212049c2e79 | 93bd02ef-4aba-44ac-ab8b-356a4a1d7a4e | 1.0.0        | stable  |
      | 9ed86386-23d9-4fe5-9057-c66dbb3b9b76 | 19e494c9-42b3-463d-b29e-8212049c2e79 | 93bd02ef-4aba-44ac-ab8b-356a4a1d7a4e | 1.0.1        | stable  |
      | e314ba5d-c760-4e54-81c4-fa01af68ff66 | 62eb12c9-68eb-4e7e-ba59-d0575b69c3e7 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0        | stable  |
      | e26e9fef-d1ce-43d3-a15c-c8fc94429709 | 62eb12c9-68eb-4e7e-ba59-d0575b69c3e7 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.2.0        | stable  |
      | ff04d1c4-cc04-4d19-985a-cb113827b821 | 62eb12c9-68eb-4e7e-ba59-d0575b69c3e7 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.1        | stable  |
      | c8b55f91-e66f-4093-ae4d-7f3d390eae8d | 62eb12c9-68eb-4e7e-ba59-d0575b69c3e7 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.0        | stable  |
      | dde54ea8-731d-4375-9d57-186ef01f3fcb | 62eb12c9-68eb-4e7e-ba59-d0575b69c3e7 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.3.0        | stable  |
      | a7fad100-04eb-418f-8af9-e5eac497ad5a | 62eb12c9-68eb-4e7e-ba59-d0575b69c3e7 | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0-beta.1 | beta    |
    And the current account has the following "policy" rows:
      | id                                   | environment_id                       | product_id                           | authentication_strategy |
      | f5336a25-89a4-45b8-ad3a-6ccaa6477ef0 | 19e494c9-42b3-463d-b29e-8212049c2e79 | 93bd02ef-4aba-44ac-ab8b-356a4a1d7a4e | LICENSE                 |
    And the current account has the following "license" rows:
      | id                                   | environment_id                       | policy_id                            |
      | a2fde824-2f58-4a89-b01b-75ed9a648ed7 | 19e494c9-42b3-463d-b29e-8212049c2e79 | f5336a25-89a4-45b8-ad3a-6ccaa6477ef0 |
    And I am a license of account "test1"
    And I authenticate with my key
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    When I send a GET request to "/accounts/test1/releases/1.0.0/upgrade"
    And the response body should be a "release" with the following attributes:
      """
      { "version": "1.0.1" }
      """
    And the response body should contain meta which includes the following:
      """
      {
        "current": "1.0.0",
        "next": "1.0.1"
      }
      """
    And the response should contain a valid signature header for "test1"
    And the response should contain the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """

  @ee
  Scenario: Anonymous retrieves an upgrade for a shared open release (shared env)
    Given the current account is "test1"
    And the current account has the following "environment" rows:
      | id                                   | name   | code   | isolation_strategy |
      | 19e494c9-42b3-463d-b29e-8212049c2e79 | Shared | shared | SHARED             |
    And the current account has the following "product" rows:
      | id                                   | name     | distribution_strategy |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test App | OPEN                  |
    And the current account has the following "release" rows:
      | id                                   | environment_id                       | product_id                           | version      | channel |
      | e314ba5d-c760-4e54-81c4-fa01af68ff66 | 19e494c9-42b3-463d-b29e-8212049c2e79 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0        | stable  |
      | e26e9fef-d1ce-43d3-a15c-c8fc94429709 | 19e494c9-42b3-463d-b29e-8212049c2e79 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.2.0        | stable  |
      | ff04d1c4-cc04-4d19-985a-cb113827b821 | 19e494c9-42b3-463d-b29e-8212049c2e79 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.1        | stable  |
      | c8b55f91-e66f-4093-ae4d-7f3d390eae8d | 19e494c9-42b3-463d-b29e-8212049c2e79 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.0        | stable  |
      | dde54ea8-731d-4375-9d57-186ef01f3fcb | 19e494c9-42b3-463d-b29e-8212049c2e79 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.3.0        | stable  |
      | a7fad100-04eb-418f-8af9-e5eac497ad5a | 19e494c9-42b3-463d-b29e-8212049c2e79 | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0-beta.1 | beta    |
    And I send the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
    When I send a GET request to "/accounts/test1/releases/1.1.0/upgrade"
    Then the response status should be "200"
    And the response body should be a "release" with the following attributes:
      """
      { "version": "1.3.0" }
      """
    And the response body should contain meta which includes the following:
      """
      {
        "current": "1.1.0",
        "next": "1.3.0"
      }
      """
    And the response should contain a valid signature header for "test1"
    And the response should contain the following headers:
      """
      { "Keygen-Environment": "shared" }
      """

  @ee
  Scenario: Anonymous retrieves an upgrade for a shared open release (nil env)
    Given the current account is "test1"
    And the current account has the following "environment" rows:
      | id                                   | name   | code   | isolation_strategy |
      | 19e494c9-42b3-463d-b29e-8212049c2e79 | Shared | shared | SHARED             |
    And the current account has the following "product" rows:
      | id                                   | name     | distribution_strategy |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test App | OPEN                  |
    And the current account has the following "release" rows:
      | id                                   | environment_id                       | product_id                           | version      | channel |
      | e314ba5d-c760-4e54-81c4-fa01af68ff66 | 19e494c9-42b3-463d-b29e-8212049c2e79 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0        | stable  |
      | e26e9fef-d1ce-43d3-a15c-c8fc94429709 | 19e494c9-42b3-463d-b29e-8212049c2e79 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.2.0        | stable  |
      | ff04d1c4-cc04-4d19-985a-cb113827b821 | 19e494c9-42b3-463d-b29e-8212049c2e79 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.1        | stable  |
      | c8b55f91-e66f-4093-ae4d-7f3d390eae8d | 19e494c9-42b3-463d-b29e-8212049c2e79 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.0        | stable  |
      | dde54ea8-731d-4375-9d57-186ef01f3fcb | 19e494c9-42b3-463d-b29e-8212049c2e79 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.3.0        | stable  |
      | a7fad100-04eb-418f-8af9-e5eac497ad5a | 19e494c9-42b3-463d-b29e-8212049c2e79 | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0-beta.1 | beta    |
    When I send a GET request to "/accounts/test1/releases/1.1.0/upgrade"
    Then the response status should be "404"

  # Upgrade by version
  Scenario: Admin retrieves an upgrade by version
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name       |
      | 6ac37cee-0027-4cdb-ba25-ac98fa0d29b4 | Test App A |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test App B |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | version       | channel |
      | e314ba5d-c760-4e54-81c4-fa01af68ff66 | 6ac37cee-0027-4cdb-ba25-ac98fa0d29b4 | 1.0.0-alpha.1 | alpha   |
      | dde54ea8-731d-4375-9d57-186ef01f3fcb | 6ac37cee-0027-4cdb-ba25-ac98fa0d29b4 | 1.0.0         | stable  |
      | e26e9fef-d1ce-43d3-a15c-c8fc94429709 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0-alpha.1 | alpha   |
      | a7fad100-04eb-418f-8af9-e5eac497ad5a | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0         | stable  |
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/1.0.0-alpha.1/upgrade"
    Then the response status should be "200"
    And the response body should be a "release" with the following relationships:
      """
      {
        "product": {
          "data": {
            "type": "products",
            "id": "6ac37cee-0027-4cdb-ba25-ac98fa0d29b4"
          },
          "links": {
            "related": "/v1/accounts/$account/releases/dde54ea8-731d-4375-9d57-186ef01f3fcb/product"
          }
        }
      }
      """
    And the response body should be a "release" with the following attributes:
      """
      { "version": "1.0.0" }
      """
    And the response body should contain meta which includes the following:
      """
      {
        "current": "1.0.0-alpha.1",
        "next": "1.0.0"
      }
      """

  Scenario: Admin retrieves an upgrade by an invalid version
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name       |
      | 6ac37cee-0027-4cdb-ba25-ac98fa0d29b4 | Test App A |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test App B |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | version       | channel |
      | e314ba5d-c760-4e54-81c4-fa01af68ff66 | 6ac37cee-0027-4cdb-ba25-ac98fa0d29b4 | 1.0.0-alpha.1 | alpha   |
      | dde54ea8-731d-4375-9d57-186ef01f3fcb | 6ac37cee-0027-4cdb-ba25-ac98fa0d29b4 | 1.0.0         | stable  |
      | e26e9fef-d1ce-43d3-a15c-c8fc94429709 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0-alpha.1 | alpha   |
      | a7fad100-04eb-418f-8af9-e5eac497ad5a | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0         | stable  |
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/%3Cnot%20set%3E/upgrade"
    And the response should contain a valid signature header for "test1"
    Then the response status should be "404"

  # Upgrade by tag
  Scenario: Admin retrieves an upgrade by tag
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name       |
      | 6ac37cee-0027-4cdb-ba25-ac98fa0d29b4 | Test App A |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test App B |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | version | tag       | channel |
      | e314ba5d-c760-4e54-81c4-fa01af68ff66 | 6ac37cee-0027-4cdb-ba25-ac98fa0d29b4 | 1.0.0   | cli@1.0.0 | stable  |
      | dde54ea8-731d-4375-9d57-186ef01f3fcb | 6ac37cee-0027-4cdb-ba25-ac98fa0d29b4 | 2.0.0   | cli@2.0.0 | stable  |
      | e26e9fef-d1ce-43d3-a15c-c8fc94429709 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0   | app@1.0.0 | stable  |
      | a7fad100-04eb-418f-8af9-e5eac497ad5a | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0   | app@2.0.0 | stable  |
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/app@1.0.0/upgrade"
    Then the response status should be "200"
    And the response body should be a "release" with the following relationships:
      """
      {
        "product": {
          "data": {
            "type": "products",
            "id": "6198261a-48b5-4445-a045-9fed4afc7735"
          },
          "links": {
            "related": "/v1/accounts/$account/releases/a7fad100-04eb-418f-8af9-e5eac497ad5a/product"
          }
        }
      }
      """
    And the response body should be a "release" with the following attributes:
      """
      {
        "tag": "app@2.0.0",
        "version": "2.0.0"
      }
      """
    And the response body should contain meta which includes the following:
      """
      {
        "current": "1.0.0",
        "next": "2.0.0"
      }
      """

  # Users
  Scenario: User retrieves an upgrade for a release of their product (license owner, upgrade available)
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name     |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test App |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | version      | channel |
      | e26e9fef-d1ce-43d3-a15c-c8fc94429709 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0        | stable  |
      | e314ba5d-c760-4e54-81c4-fa01af68ff66 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.1-beta.1 | beta  |
      | ff04d1c4-cc04-4d19-985a-cb113827b821 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.1        | stable  |
      | c8b55f91-e66f-4093-ae4d-7f3d390eae8d | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.0        | stable  |
      | dde54ea8-731d-4375-9d57-186ef01f3fcb | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.3.0        | stable  |
      | a7fad100-04eb-418f-8af9-e5eac497ad5a | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0-beta.1 | beta    |
    And the current account has 1 "user"
    And the current account has 1 "policy" for the first "product"
    And the current account has 1 "license" for the first "policy"
    And the first "license" has the following attributes:
      """
      { "userId": "$users[1]" }
      """
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$1/upgrade"
    Then the response status should be "200"
    And the response body should be a "release" with the following attributes:
      """
      { "version": "2.0.0-beta.1" }
      """
    And the response body should contain meta which includes the following:
      """
      {
        "current": "1.0.1-beta.1",
        "next": "2.0.0-beta.1"
      }
      """

  Scenario: User retrieves an upgrade for a release of their product (license user, upgrade available)
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name     |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test App |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | version      | channel |
      | e26e9fef-d1ce-43d3-a15c-c8fc94429709 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0        | stable  |
      | e314ba5d-c760-4e54-81c4-fa01af68ff66 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.1-beta.1 | beta  |
      | ff04d1c4-cc04-4d19-985a-cb113827b821 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.1        | stable  |
      | c8b55f91-e66f-4093-ae4d-7f3d390eae8d | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.0        | stable  |
      | dde54ea8-731d-4375-9d57-186ef01f3fcb | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.3.0        | stable  |
      | a7fad100-04eb-418f-8af9-e5eac497ad5a | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0-beta.1 | beta    |
    And the current account has 1 "policy" for the first "product"
    And the current account has 1 "license" for the first "policy"
    And the current account has 1 "user"
    And the current account has 1 "license-user" for the last "license" and the last "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$1/upgrade"
    Then the response status should be "200"
    And the response body should be a "release" with the following attributes:
      """
      { "version": "2.0.0-beta.1" }
      """
    And the response body should contain meta which includes the following:
      """
      {
        "current": "1.0.1-beta.1",
        "next": "2.0.0-beta.1"
      }
      """

  Scenario: User retrieves an upgrade for a release of their product (expired)
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name     |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test App |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | version | channel |
      | e314ba5d-c760-4e54-81c4-fa01af68ff66 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0   | stable  |
      | e26e9fef-d1ce-43d3-a15c-c8fc94429709 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.2.0   | stable  |
      | ff04d1c4-cc04-4d19-985a-cb113827b821 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.1   | stable  |
    And the current account has 1 "user"
    And the current account has 1 "policy" for the first "product"
    And the current account has 1 "license" for the first "policy"
    And the first "license" has the following attributes:
      """
      {
        "expiry": "$time.2.months.ago",
        "userId": "$users[1]"
      }
      """
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$0/upgrade"
    Then the response status should be "404"

  Scenario: User retrieves an upgrade for a release of their product (suspended)
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name     |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test App |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | version | channel |
      | e314ba5d-c760-4e54-81c4-fa01af68ff66 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0   | stable  |
      | e26e9fef-d1ce-43d3-a15c-c8fc94429709 | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0   | stable  |
    And the current account has 1 "user"
    And the current account has 1 "policy" for the first "product"
    And the current account has 1 "license" for the first "policy"
    And the first "license" has the following attributes:
      """
      {
        "userId": "$users[1]",
        "suspended": true
      }
      """
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$0/upgrade"
    Then the response status should be "403"

  Scenario: License retrieves an upgrade for a release of a different product
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name     |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test App |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | version | channel |
      | e314ba5d-c760-4e54-81c4-fa01af68ff66 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0   | stable  |
      | e26e9fef-d1ce-43d3-a15c-c8fc94429709 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.0   | stable  |
    And the current account has 1 "user"
    And the current account has 1 "license" for the last "user" as "owner"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$0/upgrade"
    Then the response status should be "404"

  Scenario: User retrieves an upgrade for a release of their product (has single entitlement)
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name     |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test App |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | version | channel |
      | e314ba5d-c760-4e54-81c4-fa01af68ff66 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0   | stable  |
      | e26e9fef-d1ce-43d3-a15c-c8fc94429709 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.0   | stable  |
      | ff04d1c4-cc04-4d19-985a-cb113827b821 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.2.0   | stable  |
    And the current account has 1 "entitlement"
    And the current account has 1 "user"
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "license" for the last "policy"
    And the last "license" has the following attributes:
      """
      { "userId": "$users[1]" }
      """
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
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$0/upgrade"
    Then the response status should be "200"
    And the response body should be a "release" with the following attributes:
      """
      { "version": "1.2.0" }
      """
    And the response body should contain meta which includes the following:
      """
      {
        "current": "1.0.0",
        "next": "1.2.0"
      }
      """

  Scenario: User retrieves an upgrade for a release of their product (has multiple entitlements)
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name     |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test App |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | version       | channel |
      | e314ba5d-c760-4e54-81c4-fa01af68ff66 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0-alpha.1 | alpha   |
      | e26e9fef-d1ce-43d3-a15c-c8fc94429709 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0         | stable  |
    And the current account has 2 "entitlements"
    And the current account has 1 "user"
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "license" for the last "policy"
    And the last "license" has the following attributes:
      """
      { "userId": "$users[1]" }
      """
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
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$0/upgrade"
    Then the response status should be "200"
    And the response body should be a "release" with the following attributes:
      """
      { "version": "1.0.0" }
      """
    And the response body should contain meta which includes the following:
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
      | id                                   | product_id                           | version       | channel |
      | e314ba5d-c760-4e54-81c4-fa01af68ff66 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0-alpha.1 | alpha   |
      | e26e9fef-d1ce-43d3-a15c-c8fc94429709 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0         | stable  |
    And the current account has 2 "entitlements"
    And the current account has 1 "user"
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "license" for the last "policy"
    And the last "license" has the following attributes:
      """
      { "userId": "$users[1]" }
      """
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
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$0/upgrade"
    Then the response status should be "404"

  Scenario: User retrieves an upgrade for a release of their product (missing all entitlements)
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name     |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test App |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | version       | channel |
      | e314ba5d-c760-4e54-81c4-fa01af68ff66 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0-alpha.1 | alpha   |
      | e26e9fef-d1ce-43d3-a15c-c8fc94429709 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0         | stable  |
    And the current account has 1 "user"
    And the current account has 1 "policy" for the first "product"
    And the current account has 1 "license" for the first "policy"
    And the first "license" has the following attributes:
      """
      { "userId": "$users[1]" }
      """
    And the current account has 2 "release-entitlement-constraints" for the first "release"
    And the current account has 2 "release-entitlement-constraints" for the second "release"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$0/upgrade"
    Then the response status should be "404"

  # Open distribution strategy
  Scenario: License retrieves an upgrade for a product release (OPEN distribution strategy)
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name     | distribution_strategy |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test App | OPEN                  |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | version | channel |
      | f53f57cb-dc3f-4b18-9d90-534038214b49 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0   | stable  |
      | 80e20324-c578-4763-bbef-c9698bf0023a | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.1   | stable  |
      | d34846b1-fdfe-46aa-9194-7d1a08e2d0cb | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.2   | stable  |
      | f517903b-5126-4405-9793-bf95a287b1f9 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.3   | stable  |
      | 21088509-2dfc-4459-a8a2-3404136ad1df | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.0   | stable  |
    And the current account has 1 "policy" for the first "product"
    And the current account has 1 "license" for the first "policy"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$0/upgrade"
    Then the response status should be "200"
    And the response body should be a "release" with the following attributes:
      """
      { "version": "1.1.0" }
      """
    And the response body should contain meta which includes the following:
      """
      {
        "current": "1.0.0",
        "next": "1.1.0"
      }
      """

  Scenario: License retrieves an upgrade for a product release (OPEN distribution strategy, missing entitlement)
    Given the current account is "test1"
    And the current account has the following "entitlement" rows:
      | id                                   | code      |
      | 8cdf47c8-9cdc-44c9-a752-1e137355ecaf | TEST_ENTL |
    And the current account has the following "product" rows:
      | id                                   | name     | distribution_strategy |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test App | OPEN                  |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | version | channel | entitlements |
      | f53f57cb-dc3f-4b18-9d90-534038214b49 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0   | stable  | TEST_ENTL    |
      | 80e20324-c578-4763-bbef-c9698bf0023a | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.1   | stable  | TEST_ENTL    |
      | d34846b1-fdfe-46aa-9194-7d1a08e2d0cb | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.2   | stable  | TEST_ENTL    |
      | f517903b-5126-4405-9793-bf95a287b1f9 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.3   | stable  | TEST_ENTL    |
      | 21088509-2dfc-4459-a8a2-3404136ad1df | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.0   | stable  | TEST_ENTL    |
    And the current account has 1 "policy" for the first "product"
    And the current account has 1 "license" for the first "policy"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$0/upgrade"
    Then the response status should be "404"

  Scenario: License retrieves an upgrade for a product release (OPEN distribution strategy, has entitlement)
    Given the current account is "test1"
    And the current account has the following "entitlement" rows:
      | id                                   | code      |
      | 8cdf47c8-9cdc-44c9-a752-1e137355ecaf | TEST_ENTL |
    And the current account has the following "product" rows:
      | id                                   | name     | distribution_strategy |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test App | OPEN                  |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | version | channel | entitlements |
      | f53f57cb-dc3f-4b18-9d90-534038214b49 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0   | stable  | TEST_ENTL    |
      | 80e20324-c578-4763-bbef-c9698bf0023a | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.1   | stable  | TEST_ENTL    |
      | d34846b1-fdfe-46aa-9194-7d1a08e2d0cb | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.2   | stable  | TEST_ENTL    |
      | f517903b-5126-4405-9793-bf95a287b1f9 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.3   | stable  | TEST_ENTL    |
      | 21088509-2dfc-4459-a8a2-3404136ad1df | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.0   | stable  | TEST_ENTL    |
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
    When I send a GET request to "/accounts/test1/releases/$1/upgrade"
    Then the response status should be "200"
    And the response body should be a "release" with the following attributes:
      """
      { "version": "1.1.0" }
      """
    And the response body should contain meta which includes the following:
      """
      {
        "current": "1.0.1",
        "next": "1.1.0"
      }
      """

  Scenario: User retrieves an upgrade for a product release (OPEN distribution strategy)
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name     | distribution_strategy |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test App | OPEN                  |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | version | channel |
      | f53f57cb-dc3f-4b18-9d90-534038214b49 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0   | stable  |
      | 80e20324-c578-4763-bbef-c9698bf0023a | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.1   | stable  |
      | d34846b1-fdfe-46aa-9194-7d1a08e2d0cb | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.2   | stable  |
      | f517903b-5126-4405-9793-bf95a287b1f9 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.3   | stable  |
      | 21088509-2dfc-4459-a8a2-3404136ad1df | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.0   | stable  |
    And the current account has 1 "user"
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "license" for the last "policy"
    And the last "license" has the following attributes:
      """
      { "userId": "$users[1]" }
      """
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$2/upgrade"
    Then the response status should be "200"
    And the response body should be a "release" with the following attributes:
      """
      { "version": "1.1.0" }
      """
    And the response body should contain meta which includes the following:
      """
      {
        "current": "1.0.2",
        "next": "1.1.0"
      }
      """

  Scenario: Anonymous retrieves an upgrade for a product release (OPEN distribution strategy)
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name     | distribution_strategy |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test App | OPEN                  |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | version | channel |
      | f53f57cb-dc3f-4b18-9d90-534038214b49 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0   | stable  |
      | 80e20324-c578-4763-bbef-c9698bf0023a | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.1   | stable  |
      | d34846b1-fdfe-46aa-9194-7d1a08e2d0cb | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.2   | stable  |
      | f517903b-5126-4405-9793-bf95a287b1f9 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.3   | stable  |
      | 21088509-2dfc-4459-a8a2-3404136ad1df | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.0   | stable  |
    When I send a GET request to "/accounts/test1/releases/$0/upgrade"
    Then the response status should be "200"
    And the response body should be a "release" with the following attributes:
      """
      { "version": "1.1.0" }
      """
    And the response body should contain meta which includes the following:
      """
      {
        "current": "1.0.0",
        "next": "1.1.0"
      }
      """

  # Closed distribution strategy
  Scenario: Anonymous retrieves an upgrade for a product release (CLOSED distribution strategy)
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name     | distribution_strategy |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test App | CLOSED                |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | version | channel |
      | f53f57cb-dc3f-4b18-9d90-534038214b49 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0   | stable  |
      | 80e20324-c578-4763-bbef-c9698bf0023a | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.1   | stable  |
      | d34846b1-fdfe-46aa-9194-7d1a08e2d0cb | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.2   | stable  |
      | f517903b-5126-4405-9793-bf95a287b1f9 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.3   | stable  |
      | 21088509-2dfc-4459-a8a2-3404136ad1df | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.0   | stable  |
    When I send a GET request to "/accounts/test1/releases/$0/upgrade"
    Then the response status should be "404"

  Scenario: License retrieves an upgrade for a product release (CLOSED distribution strategy)
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name     | distribution_strategy |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test App | CLOSED                |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | version | channel |
      | f53f57cb-dc3f-4b18-9d90-534038214b49 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0   | stable  |
      | 80e20324-c578-4763-bbef-c9698bf0023a | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.1   | stable  |
      | d34846b1-fdfe-46aa-9194-7d1a08e2d0cb | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.2   | stable  |
      | f517903b-5126-4405-9793-bf95a287b1f9 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.3   | stable  |
      | 21088509-2dfc-4459-a8a2-3404136ad1df | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.0   | stable  |
    And the current account has 1 "policy" for the first "product"
    And the current account has 1 "license" for the first "policy"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$0/upgrade"
    Then the response status should be "404"

  Scenario: User retrieves an upgrade for a product release (CLOSED distribution strategy)
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name     | distribution_strategy |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test App | CLOSED                |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | version | channel |
      | f53f57cb-dc3f-4b18-9d90-534038214b49 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0   | stable  |
      | 80e20324-c578-4763-bbef-c9698bf0023a | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.1   | stable  |
      | d34846b1-fdfe-46aa-9194-7d1a08e2d0cb | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.2   | stable  |
      | f517903b-5126-4405-9793-bf95a287b1f9 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.3   | stable  |
      | 21088509-2dfc-4459-a8a2-3404136ad1df | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.0   | stable  |
    And the current account has 1 "policy" for an existing "product"
    And the current account has 1 "license" for an existing "policy"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$0/upgrade"
    Then the response status should be "404"

  Scenario: Admin retrieves an upgrade for a product release (CLOSED distribution strategy)
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name     | distribution_strategy |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test App | CLOSED                |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | version | channel |
      | f53f57cb-dc3f-4b18-9d90-534038214b49 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0   | stable  |
      | 80e20324-c578-4763-bbef-c9698bf0023a | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.1   | stable  |
      | d34846b1-fdfe-46aa-9194-7d1a08e2d0cb | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.2   | stable  |
      | f517903b-5126-4405-9793-bf95a287b1f9 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.3   | stable  |
      | 21088509-2dfc-4459-a8a2-3404136ad1df | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.0   | stable  |
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$2/upgrade"
    Then the response status should be "200"
    And the response body should be a "release" with the following attributes:
      """
      { "version": "1.1.0" }
      """
    And the response body should contain meta which includes the following:
      """
      {
        "current": "1.0.2",
        "next": "1.1.0"
      }
      """

  Scenario: Product retrieves an upgrade for their release (CLOSED distribution strategy)
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name     | distribution_strategy |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test App | CLOSED                |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | version | channel |
      | f53f57cb-dc3f-4b18-9d90-534038214b49 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0   | stable  |
      | 80e20324-c578-4763-bbef-c9698bf0023a | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.1   | stable  |
      | d34846b1-fdfe-46aa-9194-7d1a08e2d0cb | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.2   | stable  |
      | f517903b-5126-4405-9793-bf95a287b1f9 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.3   | stable  |
      | 21088509-2dfc-4459-a8a2-3404136ad1df | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.0   | stable  |
    And the current account has the following "artifact" rows:
      | release_id                           | filename           | filetype | platform |
      | f53f57cb-dc3f-4b18-9d90-534038214b49 | Test-App-1.0.0.dmg | dmg      | darwin   |
      | 80e20324-c578-4763-bbef-c9698bf0023a | Test-App-1.0.1.dmg | dmg      | darwin   |
      | d34846b1-fdfe-46aa-9194-7d1a08e2d0cb | Test-App-1.0.2.dmg | dmg      | darwin   |
      | f517903b-5126-4405-9793-bf95a287b1f9 | Test-App-1.0.3.dmg | dmg      | darwin   |
      | 21088509-2dfc-4459-a8a2-3404136ad1df | Test-App-1.1.0.dmg | dmg      | darwin   |
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$0/upgrade"
    Then the response status should be "200"
    And the response body should be a "release" with the following attributes:
      """
      { "version": "1.1.0" }
      """
    And the response body should contain meta which includes the following:
      """
      {
        "current": "1.0.0",
        "next": "1.1.0"
      }
      """

  Scenario: Product retrieves an upgrade for another product release (CLOSED distribution strategy)
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name       | distribution_strategy |
      | 6ac37cee-0027-4cdb-ba25-ac98fa0d29b4 | Test App A | CLOSED                |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test App B | CLOSED                |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | version | channel |
      | f53f57cb-dc3f-4b18-9d90-534038214b49 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0   | stable  |
      | 80e20324-c578-4763-bbef-c9698bf0023a | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.1   | stable  |
      | d34846b1-fdfe-46aa-9194-7d1a08e2d0cb | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.2   | stable  |
      | f517903b-5126-4405-9793-bf95a287b1f9 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.3   | stable  |
      | 21088509-2dfc-4459-a8a2-3404136ad1df | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.0   | stable  |
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$0/upgrade"
    Then the response status should be "404"

  # Expiration basis
  Scenario: License upgrades a release with a download expiration basis (not set)
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name       |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test App A |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | version | channel |
      | f53f57cb-dc3f-4b18-9d90-534038214b49 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0   | stable  |
      | 80e20324-c578-4763-bbef-c9698bf0023a | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.1   | stable  |
      | d34846b1-fdfe-46aa-9194-7d1a08e2d0cb | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.2   | stable  |
      | f517903b-5126-4405-9793-bf95a287b1f9 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.3   | stable  |
      | 21088509-2dfc-4459-a8a2-3404136ad1df | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.0   | stable  |
    And the current account has 1 "policy" for an existing "product"
    And the first "policy" has the following attributes:
      """
      {
        "expirationBasis": "FROM_FIRST_DOWNLOAD",
        "duration": $time.1.year
      }
      """
    And the current account has 1 "license" for an existing "policy"
    And the first "license" has the following attributes:
      """
      {
        "policyId": "$policies[0]",
        "expiry": null
      }
      """
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$0/upgrade"
    Then the response status should be "200"
    And the response body should be a "release" with the following attributes:
      """
      { "version": "1.1.0" }
      """
    And the response body should contain meta which includes the following:
      """
      {
        "current": "1.0.0",
        "next": "1.1.0"
      }
      """
    And sidekiq should process 1 "event-log" job
    And sidekiq should process 1 "event-notification" job
    And the first "license" should have a 1 year expiry

  Scenario: License upgrades a release with a download expiration basis (set)
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name       |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test App A |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | version | channel |
      | f53f57cb-dc3f-4b18-9d90-534038214b49 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0   | stable  |
      | 80e20324-c578-4763-bbef-c9698bf0023a | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.1   | stable  |
      | d34846b1-fdfe-46aa-9194-7d1a08e2d0cb | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.2   | stable  |
      | f517903b-5126-4405-9793-bf95a287b1f9 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.3   | stable  |
      | 21088509-2dfc-4459-a8a2-3404136ad1df | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.0   | stable  |
    And the current account has 1 "policy" for an existing "product"
    And the first "policy" has the following attributes:
      """
      {
        "expirationBasis": "FROM_FIRST_DOWNLOAD",
        "duration": $time.1.year
      }
      """
    And the current account has 1 "license" for an existing "policy"
    And the first "license" has the following attributes:
      """
      {
        "policyId": "$policies[0]",
        "expiry": "4042-01-03T14:18:02.743Z"
      }
      """
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$0/upgrade"
    Then the response status should be "200"
    And the response body should be a "release" with the following attributes:
      """
      { "version": "1.1.0" }
      """
    And the response body should contain meta which includes the following:
      """
      {
        "current": "1.0.0",
        "next": "1.1.0"
      }
      """
    And sidekiq should process 1 "event-log" job
    And sidekiq should process 1 "event-notification" job
    And the first "license" should have the expiry "4042-01-03T14:18:02.743Z"

  # Channels
  Scenario: License retrieves an upgrade for a product release with a explicit channel (no match)
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name     |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test App |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | version       | channel  |
      | fffa0764-3a19-48ea-beb3-8950563c7357 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0         | stable   |
      | 165d5389-e535-4f36-9232-ed59c67375d1 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.1         | stable   |
      | e4fa628e-593d-48bc-8e3e-5e4dda1f2c3a | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.2         | stable   |
      | fd10ab0c-c52a-412f-b34f-180eebd7325d | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.3         | stable   |
      | f98d8c17-5fad-4361-ad89-43b0c6f6fa00 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.0         | stable   |
      | 077ca1f2-6125-4a77-bdf0-3161a0fc278e | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.1         | stable   |
      | 0a027f00-0860-4fa7-bd37-5900c8866818 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.2         | stable   |
      | 6344460b-b43c-4aa8-a76c-2086f9f526cc | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.2.0         | stable   |
      | cf72bfd4-771d-4889-8132-dc6ba8b66fa9 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.3.0         | stable   |
      | e314ba5d-c760-4e54-81c4-fa01af68ff66 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.4.0         | stable   |
      | e26e9fef-d1ce-43d3-a15c-c8fc94429709 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.5.0         | stable   |
      | ff04d1c4-cc04-4d19-985a-cb113827b821 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.6.0         | stable   |
      | c8b55f91-e66f-4093-ae4d-7f3d390eae8d | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.7.0         | stable   |
      | dde54ea8-731d-4375-9d57-186ef01f3fcb | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0-alpha.1 | alpha    |
    And the current account has 1 "policy" for the first "product"
    And the current account has 1 "license" for the first "policy"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$0/upgrade?channel=beta"
    Then the response status should be "200"
    And the response body should be a "release" with the following attributes:
      """
      { "version": "1.7.0" }
      """
    And the response body should contain meta which includes the following:
      """
      {
        "current": "1.0.0",
        "next": "1.7.0"
      }
      """

  Scenario: License retrieves an upgrade for a product release with a explicit channel (rc)
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name     |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test App |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | version       | channel  |
      | fffa0764-3a19-48ea-beb3-8950563c7357 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0         | stable   |
      | 165d5389-e535-4f36-9232-ed59c67375d1 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.1         | stable   |
      | e4fa628e-593d-48bc-8e3e-5e4dda1f2c3a | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.2         | stable   |
      | fd10ab0c-c52a-412f-b34f-180eebd7325d | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.3         | stable   |
      | f98d8c17-5fad-4361-ad89-43b0c6f6fa00 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.0         | stable   |
      | 077ca1f2-6125-4a77-bdf0-3161a0fc278e | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.1         | stable   |
      | 0a027f00-0860-4fa7-bd37-5900c8866818 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.2         | stable   |
      | 6344460b-b43c-4aa8-a76c-2086f9f526cc | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.2.0         | stable   |
      | cf72bfd4-771d-4889-8132-dc6ba8b66fa9 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.3.0         | stable   |
      | e314ba5d-c760-4e54-81c4-fa01af68ff66 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.4.0         | stable   |
      | e26e9fef-d1ce-43d3-a15c-c8fc94429709 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.5.0         | stable   |
      | ff04d1c4-cc04-4d19-985a-cb113827b821 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.6.0         | stable   |
      | c8b55f91-e66f-4093-ae4d-7f3d390eae8d | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.7.0         | stable   |
      | 4a744db3-e9af-45b2-b5b1-7baf33656747 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.8.0-alpha.1 | alpha    |
      | b913d283-f1a0-44cf-95c9-b32b992ca451 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.8.0-alpha.2 | alpha    |
      | 5a7207c2-8ca5-4abe-8046-8061431ec6a8 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.8.0-beta.1  | beta     |
      | 432a3978-bbce-4a42-b928-f973b554fd60 | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0-alpha.1 | alpha    |
    And the current account has 1 "policy" for the first "product"
    And the current account has 1 "license" for the first "policy"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$3/upgrade?channel=rc"
    Then the response status should be "200"
    And the response body should be a "release" with the following attributes:
      """
      { "version": "1.7.0" }
      """
    And the response body should contain meta which includes the following:
      """
      {
        "current": "1.0.3",
        "next": "1.7.0"
      }
      """

  Scenario: License retrieves an upgrade for a product release with a explicit channel (beta)
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name     |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test App |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | version       | channel  |
      | fffa0764-3a19-48ea-beb3-8950563c7357 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0         | stable   |
      | 165d5389-e535-4f36-9232-ed59c67375d1 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.1         | stable   |
      | e4fa628e-593d-48bc-8e3e-5e4dda1f2c3a | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.2         | stable   |
      | fd10ab0c-c52a-412f-b34f-180eebd7325d | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.3         | stable   |
      | f98d8c17-5fad-4361-ad89-43b0c6f6fa00 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.0         | stable   |
      | 077ca1f2-6125-4a77-bdf0-3161a0fc278e | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.1         | stable   |
      | 0a027f00-0860-4fa7-bd37-5900c8866818 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.2         | stable   |
      | 6344460b-b43c-4aa8-a76c-2086f9f526cc | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.2.0         | stable   |
      | cf72bfd4-771d-4889-8132-dc6ba8b66fa9 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.3.0         | stable   |
      | e314ba5d-c760-4e54-81c4-fa01af68ff66 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.4.0         | stable   |
      | e26e9fef-d1ce-43d3-a15c-c8fc94429709 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.5.0         | stable   |
      | ff04d1c4-cc04-4d19-985a-cb113827b821 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.6.0         | stable   |
      | c8b55f91-e66f-4093-ae4d-7f3d390eae8d | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.7.0         | stable   |
      | 4a744db3-e9af-45b2-b5b1-7baf33656747 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.8.0-alpha.1 | alpha    |
      | b913d283-f1a0-44cf-95c9-b32b992ca451 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.8.0-alpha.2 | alpha    |
      | 5a7207c2-8ca5-4abe-8046-8061431ec6a8 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.8.0-beta.1  | beta     |
      | 432a3978-bbce-4a42-b928-f973b554fd60 | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0-alpha.1 | alpha    |
    And the current account has 1 "policy" for the first "product"
    And the current account has 1 "license" for the first "policy"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$14/upgrade?channel=beta"
    Then the response status should be "200"
    And the response body should be a "release" with the following attributes:
      """
      { "version": "1.8.0-beta.1" }
      """
    And the response body should contain meta which includes the following:
      """
      {
        "current": "1.8.0-alpha.2",
        "next": "1.8.0-beta.1"
      }
      """

  Scenario: License retrieves an upgrade for a product release with a explicit channel (alpha)
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name     |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test App |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | version       | channel  |
      | fffa0764-3a19-48ea-beb3-8950563c7357 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0         | stable   |
      | 165d5389-e535-4f36-9232-ed59c67375d1 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.1         | stable   |
      | e4fa628e-593d-48bc-8e3e-5e4dda1f2c3a | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.2         | stable   |
      | fd10ab0c-c52a-412f-b34f-180eebd7325d | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.3         | stable   |
      | f98d8c17-5fad-4361-ad89-43b0c6f6fa00 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.0         | stable   |
      | 077ca1f2-6125-4a77-bdf0-3161a0fc278e | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.1         | stable   |
      | 0a027f00-0860-4fa7-bd37-5900c8866818 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.2         | stable   |
      | 6344460b-b43c-4aa8-a76c-2086f9f526cc | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.2.0         | stable   |
      | cf72bfd4-771d-4889-8132-dc6ba8b66fa9 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.3.0         | stable   |
      | e314ba5d-c760-4e54-81c4-fa01af68ff66 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.4.0         | stable   |
      | e26e9fef-d1ce-43d3-a15c-c8fc94429709 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.5.0         | stable   |
      | ff04d1c4-cc04-4d19-985a-cb113827b821 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.6.0         | stable   |
      | c8b55f91-e66f-4093-ae4d-7f3d390eae8d | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.7.0         | stable   |
      | dde54ea8-731d-4375-9d57-186ef01f3fcb | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0-alpha.1 | alpha    |
    And the current account has 1 "policy" for the first "product"
    And the current account has 1 "license" for the first "policy"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$0/upgrade?channel=alpha"
    Then the response status should be "200"
    And the response body should be a "release" with the following attributes:
      """
      { "version": "2.0.0-alpha.1" }
      """
    And the response body should contain meta which includes the following:
      """
      {
        "current": "1.0.0",
        "next": "2.0.0-alpha.1"
      }
      """

  Scenario: License retrieves an upgrade for a product release using an invalid channel
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name     |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test App |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | version | channel  |
      | fffa0764-3a19-48ea-beb3-8950563c7357 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0   | stable   |
      | 165d5389-e535-4f36-9232-ed59c67375d1 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.1   | stable   |
      | e4fa628e-593d-48bc-8e3e-5e4dda1f2c3a | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.2   | stable   |
      | fd10ab0c-c52a-412f-b34f-180eebd7325d | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.3   | stable   |
      | f98d8c17-5fad-4361-ad89-43b0c6f6fa00 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.0   | stable   |
      | 077ca1f2-6125-4a77-bdf0-3161a0fc278e | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.1   | stable   |
      | 0a027f00-0860-4fa7-bd37-5900c8866818 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.2   | stable   |
      | 6344460b-b43c-4aa8-a76c-2086f9f526cc | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.2.0   | stable   |
      | cf72bfd4-771d-4889-8132-dc6ba8b66fa9 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.3.0   | stable   |
      | e314ba5d-c760-4e54-81c4-fa01af68ff66 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.4.0   | stable   |
      | e26e9fef-d1ce-43d3-a15c-c8fc94429709 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.5.0   | stable   |
      | ff04d1c4-cc04-4d19-985a-cb113827b821 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.6.0   | stable   |
      | c8b55f91-e66f-4093-ae4d-7f3d390eae8d | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.7.0   | stable   |
      | dde54ea8-731d-4375-9d57-186ef01f3fcb | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0   | stable   |
      | a7fad100-04eb-418f-8af9-e5eac497ad5a | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.1   | stable   |
    And the current account has 1 "policy" for the first "product"
    And the current account has 1 "license" for the first "policy"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$10/upgrade?channel=edge"
    Then the response status should be "404"

  # Constraints
  Scenario: License retrieves an upgrade for a product release using a constraint
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name     |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test App |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | version | channel  |
      | fffa0764-3a19-48ea-beb3-8950563c7357 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0   | stable   |
      | 165d5389-e535-4f36-9232-ed59c67375d1 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.1   | stable   |
      | e4fa628e-593d-48bc-8e3e-5e4dda1f2c3a | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.2   | stable   |
      | fd10ab0c-c52a-412f-b34f-180eebd7325d | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.3   | stable   |
      | f98d8c17-5fad-4361-ad89-43b0c6f6fa00 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.0   | stable   |
      | 077ca1f2-6125-4a77-bdf0-3161a0fc278e | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.1   | stable   |
      | 0a027f00-0860-4fa7-bd37-5900c8866818 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.2   | stable   |
      | 6344460b-b43c-4aa8-a76c-2086f9f526cc | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.2.0   | stable   |
      | cf72bfd4-771d-4889-8132-dc6ba8b66fa9 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.3.0   | stable   |
      | e314ba5d-c760-4e54-81c4-fa01af68ff66 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.4.0   | stable   |
      | e26e9fef-d1ce-43d3-a15c-c8fc94429709 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.5.0   | stable   |
      | ff04d1c4-cc04-4d19-985a-cb113827b821 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.6.0   | stable   |
      | c8b55f91-e66f-4093-ae4d-7f3d390eae8d | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.7.0   | stable   |
      | dde54ea8-731d-4375-9d57-186ef01f3fcb | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0   | stable   |
      | a7fad100-04eb-418f-8af9-e5eac497ad5a | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.1   | stable   |
    And the current account has 1 "policy" for the first "product"
    And the current account has 1 "license" for the first "policy"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$10/upgrade?constraint=1.0"
    Then the response status should be "200"
    And the response body should be a "release" with the following attributes:
      """
      { "version": "1.7.0" }
      """
    And the response body should contain meta which includes the following:
      """
      {
        "current": "1.5.0",
        "next": "1.7.0"
      }
      """

  Scenario: License retrieves an upgrade for a product release using an invalid constraint
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name     |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test App |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | version | channel  |
      | fffa0764-3a19-48ea-beb3-8950563c7357 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0   | stable   |
      | 165d5389-e535-4f36-9232-ed59c67375d1 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.1   | stable   |
      | e4fa628e-593d-48bc-8e3e-5e4dda1f2c3a | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.2   | stable   |
      | fd10ab0c-c52a-412f-b34f-180eebd7325d | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.3   | stable   |
      | f98d8c17-5fad-4361-ad89-43b0c6f6fa00 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.0   | stable   |
      | 077ca1f2-6125-4a77-bdf0-3161a0fc278e | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.1   | stable   |
      | 0a027f00-0860-4fa7-bd37-5900c8866818 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.2   | stable   |
      | 6344460b-b43c-4aa8-a76c-2086f9f526cc | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.2.0   | stable   |
      | cf72bfd4-771d-4889-8132-dc6ba8b66fa9 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.3.0   | stable   |
      | e314ba5d-c760-4e54-81c4-fa01af68ff66 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.4.0   | stable   |
      | e26e9fef-d1ce-43d3-a15c-c8fc94429709 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.5.0   | stable   |
      | ff04d1c4-cc04-4d19-985a-cb113827b821 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.6.0   | stable   |
      | c8b55f91-e66f-4093-ae4d-7f3d390eae8d | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.7.0   | stable   |
      | dde54ea8-731d-4375-9d57-186ef01f3fcb | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0   | stable   |
      | a7fad100-04eb-418f-8af9-e5eac497ad5a | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.1   | stable   |
    And the current account has 1 "policy" for the first "product"
    And the current account has 1 "license" for the first "policy"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/$10/upgrade?constraint=A"
    Then the response status should be "400"
    And the response body should be an array of 1 error
    And the first error should have the following properties:
      """
      {
        "title": "Bad request",
        "detail": "invalid constraint format",
        "source": {
          "parameter": "constraint"
        }
      }
      """

  Scenario: Admin retrieves an upgrade for a product release conflicting with another product release (without scope)
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name       | distribution_strategy |
      | 6ac37cee-0027-4cdb-ba25-ac98fa0d29b4 | Test App A | CLOSED                |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test App B | CLOSED                |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | version | channel |
      | f53f57cb-dc3f-4b18-9d90-534038214b49 | 6ac37cee-0027-4cdb-ba25-ac98fa0d29b4 | 1.0.0   | stable  |
      | e26e9fef-d1ce-43d3-a15c-c8fc94429709 | 6ac37cee-0027-4cdb-ba25-ac98fa0d29b4 | 1.0.1   | stable  |
      | 80e20324-c578-4763-bbef-c9698bf0023a | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0   | stable  |
      | ff04d1c4-cc04-4d19-985a-cb113827b821 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.1   | stable  |
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/1.0.0/upgrade"
    Then the response status should be "200"
    And the response body should be a "release" with the following relationships:
      """
      {
        "product": {
          "data": {
            "type": "products",
            "id": "6ac37cee-0027-4cdb-ba25-ac98fa0d29b4"
          },
          "links": {
            "related": "/v1/accounts/$account/releases/e26e9fef-d1ce-43d3-a15c-c8fc94429709/product"
          }
        }
      }
      """
    And the response body should be a "release" with the following attributes:
      """
      { "version": "1.0.1" }
      """
    And the response body should contain meta which includes the following:
      """
      {
        "current": "1.0.0",
        "next": "1.0.1"
      }
      """

  Scenario: Admin retrieves an upgrade for a product release conflicting with another product release (with scope)
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name       | distribution_strategy |
      | 6ac37cee-0027-4cdb-ba25-ac98fa0d29b4 | Test App A | CLOSED                |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test App B | CLOSED                |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | version | channel |
      | f53f57cb-dc3f-4b18-9d90-534038214b49 | 6ac37cee-0027-4cdb-ba25-ac98fa0d29b4 | 1.0.0   | stable  |
      | e26e9fef-d1ce-43d3-a15c-c8fc94429709 | 6ac37cee-0027-4cdb-ba25-ac98fa0d29b4 | 1.0.1   | stable  |
      | 80e20324-c578-4763-bbef-c9698bf0023a | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0   | stable  |
      | ff04d1c4-cc04-4d19-985a-cb113827b821 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.1   | stable  |
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/1.0.0/upgrade?product=6198261a-48b5-4445-a045-9fed4afc7735"
    Then the response status should be "200"
    And the response body should be a "release" with the following relationships:
      """
      {
        "product": {
          "data": {
            "type": "products",
            "id": "6198261a-48b5-4445-a045-9fed4afc7735"
          },
          "links": {
            "related": "/v1/accounts/$account/releases/ff04d1c4-cc04-4d19-985a-cb113827b821/product"
          }
        }
      }
      """
    And the response body should be a "release" with the following attributes:
      """
      { "version": "1.0.1" }
      """
    And the response body should contain meta which includes the following:
      """
      {
        "current": "1.0.0",
        "next": "1.0.1"
      }
      """

  Scenario: License retrieves an upgrade for a product release conflicting with another product release (without scope)
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name       | distribution_strategy |
      | 6ac37cee-0027-4cdb-ba25-ac98fa0d29b4 | Test App A | LICENSED              |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test App B | LICENSED              |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | version | channel |
      | f53f57cb-dc3f-4b18-9d90-534038214b49 | 6ac37cee-0027-4cdb-ba25-ac98fa0d29b4 | 1.0.0   | stable  |
      | e26e9fef-d1ce-43d3-a15c-c8fc94429709 | 6ac37cee-0027-4cdb-ba25-ac98fa0d29b4 | 1.0.1   | stable  |
      | 80e20324-c578-4763-bbef-c9698bf0023a | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0   | stable  |
      | ff04d1c4-cc04-4d19-985a-cb113827b821 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.1   | stable  |
    And the current account has 1 "policy" for the first "product"
    And the current account has 1 "license" for the first "policy"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/1.0.0/upgrade"
    Then the response status should be "200"
    And the response body should be a "release" with the following relationships:
      """
      {
        "product": {
          "data": {
            "type": "products",
            "id": "6ac37cee-0027-4cdb-ba25-ac98fa0d29b4"
          },
          "links": {
            "related": "/v1/accounts/$account/releases/e26e9fef-d1ce-43d3-a15c-c8fc94429709/product"
          }
        }
      }
      """
    And the response body should be a "release" with the following attributes:
      """
      { "version": "1.0.1" }
      """
    And the response body should contain meta which includes the following:
      """
      {
        "current": "1.0.0",
        "next": "1.0.1"
      }
      """

  Scenario: License retrieves an upgrade for a product release conflicting with another product release (with scope)
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name       | distribution_strategy |
      | 6ac37cee-0027-4cdb-ba25-ac98fa0d29b4 | Test App A | LICENSED              |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test App B | LICENSED              |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | version | channel |
      | f53f57cb-dc3f-4b18-9d90-534038214b49 | 6ac37cee-0027-4cdb-ba25-ac98fa0d29b4 | 1.0.0   | stable  |
      | e26e9fef-d1ce-43d3-a15c-c8fc94429709 | 6ac37cee-0027-4cdb-ba25-ac98fa0d29b4 | 1.0.1   | stable  |
      | 80e20324-c578-4763-bbef-c9698bf0023a | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0   | stable  |
      | ff04d1c4-cc04-4d19-985a-cb113827b821 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.1   | stable  |
    And the current account has 1 "policy" for the first "product"
    And the current account has 1 "license" for the first "policy"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/1.0.0/upgrade?product=6198261a-48b5-4445-a045-9fed4afc7735"
    Then the response status should be "404"

  Scenario: License retrieves an upgrade for a product release with build tag constraint
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name       | distribution_strategy |
      | 6ac37cee-0027-4cdb-ba25-ac98fa0d29b4 | Test App A | LICENSED              |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test App B | LICENSED              |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | version  | channel |
      | f53f57cb-dc3f-4b18-9d90-534038214b49 | 6ac37cee-0027-4cdb-ba25-ac98fa0d29b4 | 1.0.0+p1 | stable  |
      | e26e9fef-d1ce-43d3-a15c-c8fc94429709 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0+p2 | stable  |
      | ff04d1c4-cc04-4d19-985a-cb113827b821 | 6ac37cee-0027-4cdb-ba25-ac98fa0d29b4 | 1.0.1+p1 | stable  |
      | 80e20324-c578-4763-bbef-c9698bf0023a | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.0+p2 | stable  |
      | cf72bfd4-771d-4889-8132-dc6ba8b66fa9 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.2.0+p2 | stable   |
      | e314ba5d-c760-4e54-81c4-fa01af68ff66 | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0+p2 | stable   |
    And the current account has 1 "policy" for the first "product"
    And the current account has 1 "license" for the first "policy"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/1.0.0%2Bp1/upgrade?constraint=1%2Bp1"
    Then the response status should be "200"
    And the response body should be a "release" with the following relationships:
      """
      {
        "product": {
          "data": {
            "type": "products",
            "id": "6ac37cee-0027-4cdb-ba25-ac98fa0d29b4"
          },
          "links": {
            "related": "/v1/accounts/$account/releases/ff04d1c4-cc04-4d19-985a-cb113827b821/product"
          }
        }
      }
      """
    And the response body should be a "release" with the following attributes:
      """
      { "version": "1.0.1+p1" }
      """
    And the response body should contain meta which includes the following:
      """
      {
        "current": "1.0.0+p1",
        "next": "1.0.1+p1"
      }
      """

  Scenario: License retrieves an upgrade for a product release with pre tag constraint
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name       | distribution_strategy |
      | 6ac37cee-0027-4cdb-ba25-ac98fa0d29b4 | Test App A | LICENSED              |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test App B | LICENSED              |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | version      | channel |
      | f53f57cb-dc3f-4b18-9d90-534038214b49 | 6ac37cee-0027-4cdb-ba25-ac98fa0d29b4 | 1.0.0-beta.1 | beta    |
      | e26e9fef-d1ce-43d3-a15c-c8fc94429709 | 6ac37cee-0027-4cdb-ba25-ac98fa0d29b4 | 1.0.0-beta.2 | beta    |
      | ff04d1c4-cc04-4d19-985a-cb113827b821 | 6ac37cee-0027-4cdb-ba25-ac98fa0d29b4 | 1.0.0-beta.3 | beta    |
      | c8b55f91-e66f-4093-ae4d-7f3d390eae8d | 6ac37cee-0027-4cdb-ba25-ac98fa0d29b4 | 1.0.0        | stable  |
      | 077ca1f2-6125-4a77-bdf0-3161a0fc278e | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0        | stable  |
      | a7fad100-04eb-418f-8af9-e5eac497ad5a | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.1        | stable  |
      | 80e20324-c578-4763-bbef-c9698bf0023a | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.0-beta.1 | beta    |
      | cf72bfd4-771d-4889-8132-dc6ba8b66fa9 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.0-beta.2 | beta    |
      | e314ba5d-c760-4e54-81c4-fa01af68ff66 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.0        | stable  |
    And the current account has 1 "policy" for the first "product"
    And the current account has 1 "license" for the first "policy"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/1.0.0-beta.1/upgrade?constraint=1-beta"
    Then the response status should be "200"
    And the response body should be a "release" with the following relationships:
      """
      {
        "product": {
          "data": {
            "type": "products",
            "id": "6ac37cee-0027-4cdb-ba25-ac98fa0d29b4"
          },
          "links": {
            "related": "/v1/accounts/$account/releases/ff04d1c4-cc04-4d19-985a-cb113827b821/product"
          }
        }
      }
      """
    And the response body should be a "release" with the following attributes:
      """
      { "version": "1.0.0-beta.3" }
      """
    And the response body should contain meta which includes the following:
      """
      {
        "current": "1.0.0-beta.1",
        "next": "1.0.0-beta.3"
      }
      """

  Scenario: Admin retrieves an upgrade for a release conflicting with another package (with scope)
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name       | distribution_strategy |
      | 6ac37cee-0027-4cdb-ba25-ac98fa0d29b4 | Test App A | CLOSED                |
    And the current account has the following "package" rows:
      | id                                   | product_id                           | name      | key      |
      | 615f641a-2825-40d7-9689-8c82e3cadd58 | 6ac37cee-0027-4cdb-ba25-ac98fa0d29b4 | Package 1 | package1 |
      | 8fec17e8-17f1-4869-aeb1-19e050cf4dea | 6ac37cee-0027-4cdb-ba25-ac98fa0d29b4 | Package 2 | package2 |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | package_id | version | channel |
      | f53f57cb-dc3f-4b18-9d90-534038214b49 | 6ac37cee-0027-4cdb-ba25-ac98fa0d29b4 | 615f641a-2825-40d7-9689-8c82e3cadd58 | 1.0.0   | stable  |
      | e26e9fef-d1ce-43d3-a15c-c8fc94429709 | 6ac37cee-0027-4cdb-ba25-ac98fa0d29b4 | 615f641a-2825-40d7-9689-8c82e3cadd58 | 1.0.1   | stable  |
      | 80e20324-c578-4763-bbef-c9698bf0023a | 6ac37cee-0027-4cdb-ba25-ac98fa0d29b4 |                                      | 1.0.0   | stable  |
      | 2033c3ef-7093-4554-95e2-20572f27663f | 6ac37cee-0027-4cdb-ba25-ac98fa0d29b4 |                                      | 1.0.1   | stable  |
      | 25a7ee6b-b660-4e27-a2cd-bf541f6c17f5 | 6ac37cee-0027-4cdb-ba25-ac98fa0d29b4 | 8fec17e8-17f1-4869-aeb1-19e050cf4dea | 1.0.0   | stable  |
      | ff04d1c4-cc04-4d19-985a-cb113827b821 | 6ac37cee-0027-4cdb-ba25-ac98fa0d29b4 | 8fec17e8-17f1-4869-aeb1-19e050cf4dea | 1.0.1   | stable  |
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/1.0.0/upgrade?package=8fec17e8-17f1-4869-aeb1-19e050cf4dea"
    Then the response status should be "200"
    And the response body should be a "release" with the following relationships:
      """
      {
        "product": {
          "data": {
            "type": "products",
            "id": "6ac37cee-0027-4cdb-ba25-ac98fa0d29b4"
          },
          "links": {
            "related": "/v1/accounts/$account/releases/ff04d1c4-cc04-4d19-985a-cb113827b821/product"
          }
        }
      }
      """
    And the response body should be a "release" with the following attributes:
      """
      { "version": "1.0.1" }
      """
    And the response body should contain meta which includes the following:
      """
      {
        "current": "1.0.0",
        "next": "1.0.1"
      }
      """

  Scenario: Admin retrieves an upgrade for a release conflicting with another package (nil scope)
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name       | distribution_strategy |
      | 6ac37cee-0027-4cdb-ba25-ac98fa0d29b4 | Test App A | CLOSED                |
    And the current account has the following "package" rows:
      | id                                   | product_id                           | name      | key      |
      | 615f641a-2825-40d7-9689-8c82e3cadd58 | 6ac37cee-0027-4cdb-ba25-ac98fa0d29b4 | Package 1 | package1 |
      | 8fec17e8-17f1-4869-aeb1-19e050cf4dea | 6ac37cee-0027-4cdb-ba25-ac98fa0d29b4 | Package 2 | package2 |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | package_id | version | channel |
      | f53f57cb-dc3f-4b18-9d90-534038214b49 | 6ac37cee-0027-4cdb-ba25-ac98fa0d29b4 | 615f641a-2825-40d7-9689-8c82e3cadd58 | 1.0.0   | stable  |
      | e26e9fef-d1ce-43d3-a15c-c8fc94429709 | 6ac37cee-0027-4cdb-ba25-ac98fa0d29b4 | 615f641a-2825-40d7-9689-8c82e3cadd58 | 1.0.1   | stable  |
      | 80e20324-c578-4763-bbef-c9698bf0023a | 6ac37cee-0027-4cdb-ba25-ac98fa0d29b4 |                                      | 1.0.0   | stable  |
      | 2033c3ef-7093-4554-95e2-20572f27663f | 6ac37cee-0027-4cdb-ba25-ac98fa0d29b4 |                                      | 1.0.1   | stable  |
      | 25a7ee6b-b660-4e27-a2cd-bf541f6c17f5 | 6ac37cee-0027-4cdb-ba25-ac98fa0d29b4 | 8fec17e8-17f1-4869-aeb1-19e050cf4dea | 1.0.0   | stable  |
      | ff04d1c4-cc04-4d19-985a-cb113827b821 | 6ac37cee-0027-4cdb-ba25-ac98fa0d29b4 | 8fec17e8-17f1-4869-aeb1-19e050cf4dea | 1.0.1   | stable  |
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/1.0.0/upgrade?package="
    Then the response status should be "200"
    And the response body should be a "release" with the following relationships:
      """
      {
        "product": {
          "data": {
            "type": "products",
            "id": "6ac37cee-0027-4cdb-ba25-ac98fa0d29b4"
          },
          "links": {
            "related": "/v1/accounts/$account/releases/2033c3ef-7093-4554-95e2-20572f27663f/product"
          }
        }
      }
      """
    And the response body should be a "release" with the following attributes:
      """
      { "version": "1.0.1" }
      """
    And the response body should contain meta which includes the following:
      """
      {
        "current": "1.0.0",
        "next": "1.0.1"
      }
      """

  Scenario: Admin retrieves an upgrade for a release conflicting with another package (no scope)
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name       | distribution_strategy |
      | 6ac37cee-0027-4cdb-ba25-ac98fa0d29b4 | Test App A | CLOSED                |
    And the current account has the following "package" rows:
      | id                                   | product_id                           | name      | key      |
      | 615f641a-2825-40d7-9689-8c82e3cadd58 | 6ac37cee-0027-4cdb-ba25-ac98fa0d29b4 | Package 1 | package1 |
      | 8fec17e8-17f1-4869-aeb1-19e050cf4dea | 6ac37cee-0027-4cdb-ba25-ac98fa0d29b4 | Package 2 | package2 |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | package_id | version | channel |
      | f53f57cb-dc3f-4b18-9d90-534038214b49 | 6ac37cee-0027-4cdb-ba25-ac98fa0d29b4 | 615f641a-2825-40d7-9689-8c82e3cadd58 | 1.0.0   | stable  |
      | e26e9fef-d1ce-43d3-a15c-c8fc94429709 | 6ac37cee-0027-4cdb-ba25-ac98fa0d29b4 | 615f641a-2825-40d7-9689-8c82e3cadd58 | 1.0.1   | stable  |
      | 80e20324-c578-4763-bbef-c9698bf0023a | 6ac37cee-0027-4cdb-ba25-ac98fa0d29b4 |                                      | 1.0.0   | stable  |
      | 2033c3ef-7093-4554-95e2-20572f27663f | 6ac37cee-0027-4cdb-ba25-ac98fa0d29b4 |                                      | 1.0.1   | stable  |
      | 25a7ee6b-b660-4e27-a2cd-bf541f6c17f5 | 6ac37cee-0027-4cdb-ba25-ac98fa0d29b4 | 8fec17e8-17f1-4869-aeb1-19e050cf4dea | 1.0.0   | stable  |
      | ff04d1c4-cc04-4d19-985a-cb113827b821 | 6ac37cee-0027-4cdb-ba25-ac98fa0d29b4 | 8fec17e8-17f1-4869-aeb1-19e050cf4dea | 1.0.1   | stable  |
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases/25a7ee6b-b660-4e27-a2cd-bf541f6c17f5/upgrade"
    Then the response status should be "200"
    And the response body should be a "release" with the following relationships:
      """
      {
        "product": {
          "data": {
            "type": "products",
            "id": "6ac37cee-0027-4cdb-ba25-ac98fa0d29b4"
          },
          "links": {
            "related": "/v1/accounts/$account/releases/ff04d1c4-cc04-4d19-985a-cb113827b821/product"
          }
        }
      }
      """
    And the response body should be a "release" with the following attributes:
      """
      { "version": "1.0.1" }
      """
    And the response body should contain meta which includes the following:
      """
      {
        "current": "1.0.0",
        "next": "1.0.1"
      }
      """
