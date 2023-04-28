@api/v1.0 @deprecated
Feature: Release upgrade actions

  Background:
    Given the following "accounts" exist:
      | name    | slug  |
      | Test 1  | test1 |
      | Test 2  | test2 |
    And I send and accept JSON

  Scenario: Endpoint should be inaccessible when account is using >= v1.1
    Given the account "test1" is canceled
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "release"
    And I use an authentication token
    And I use API version "1.1"
    When I send a GET request to "/accounts/test1/releases/$0/actions/upgrade"
    Then the response status should be "404"

  Scenario: Endpoint should be inaccessible when account is disabled
    Given the account "test1" is canceled
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "release"
    And I use an authentication token
    And I use API version "1.0"
    When I send a GET request to "/accounts/test1/releases/$0/actions/upgrade"
    Then the response status should be "403"

  # Upgrade by ID
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
    And the current account has the following "artifact" rows:
      | release_id                           | filename           | filetype | platform |
      | fffa0764-3a19-48ea-beb3-8950563c7357 | Test-App-1.0.0.dmg | dmg      | macos    |
      | 165d5389-e535-4f36-9232-ed59c67375d1 | Test-App-1.0.1.dmg | dmg      | macos    |
      | e4fa628e-593d-48bc-8e3e-5e4dda1f2c3a | Test-App-1.0.2.dmg | dmg      | macos    |
      | fd10ab0c-c52a-412f-b34f-180eebd7325d | Test-App-1.0.3.dmg | dmg      | macos    |
      | f98d8c17-5fad-4361-ad89-43b0c6f6fa00 | Test-App-1.1.0.dmg | dmg      | macos    |
      | 077ca1f2-6125-4a77-bdf0-3161a0fc278e | Test-App-1.1.1.dmg | dmg      | macos    |
      | 0a027f00-0860-4fa7-bd37-5900c8866818 | Test-App-1.1.2.dmg | dmg      | macos    |
      | 6344460b-b43c-4aa8-a76c-2086f9f526cc | Test-App-1.2.0.dmg | dmg      | macos    |
      | cf72bfd4-771d-4889-8132-dc6ba8b66fa9 | Test-App-1.3.0.dmg | dmg      | macos    |
      | e314ba5d-c760-4e54-81c4-fa01af68ff66 | Test-App-1.4.0.dmg | dmg      | macos    |
      | e26e9fef-d1ce-43d3-a15c-c8fc94429709 | Test-App-1.5.0.dmg | dmg      | macos    |
      | ff04d1c4-cc04-4d19-985a-cb113827b821 | Test-App-1.6.0.dmg | dmg      | macos    |
      | c8b55f91-e66f-4093-ae4d-7f3d390eae8d | Test-App-1.7.0.dmg | dmg      | macos    |
      | dde54ea8-731d-4375-9d57-186ef01f3fcb | Test-App-2.0.0.dmg | dmg      | macos    |
      | a7fad100-04eb-418f-8af9-e5eac497ad5a | Test-App-2.0.1.dmg | dmg      | macos    |
    And I am an admin of account "test1"
    And I use an authentication token
    And I use API version "1.0"
    When I send a GET request to "/accounts/test1/releases/$0/actions/upgrade"
    Then the response status should be "303"
    And the response body should be an "artifact" with the following relationships:
      """
      {
        "product": {
          "data": {
            "type": "products",
            "id": "6198261a-48b5-4445-a045-9fed4afc7735"
          },
          "links": {
            "related": "/v1/accounts/$account/products/6198261a-48b5-4445-a045-9fed4afc7735"
          }
        },
        "release": {
          "data": {
            "type": "releases",
            "id": "a7fad100-04eb-418f-8af9-e5eac497ad5a"
          },
          "links": {
            "related": "/v1/accounts/$account/releases/a7fad100-04eb-418f-8af9-e5eac497ad5a"
          }
        }
      }
      """
    And the response body should be an "artifact" with the following attributes:
      """
      { "key": "Test-App-2.0.1.dmg" }
      """
    And the response body should contain meta which includes the following:
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
      | id                                   | product_id                           | version | channel |
      | fffa0764-3a19-48ea-beb3-8950563c7357 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0   | stable  |
    And the current account has the following "artifact" rows:
      | release_id                           | filename           | filetype | platform |
      | fffa0764-3a19-48ea-beb3-8950563c7357 | Test-App-1.0.0.dmg | dmg      | macos    |
    And I am an admin of account "test1"
    And I use an authentication token
    And I use API version "1.0"
    When I send a GET request to "/accounts/test1/releases/$0/actions/upgrade"
    Then the response status should be "204"

  Scenario: Admin retrieves an upgrade for a product release (no artifact available)
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name     |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test App |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | version | channel |
      | fffa0764-3a19-48ea-beb3-8950563c7357 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0   | stable  |
      | 165d5389-e535-4f36-9232-ed59c67375d1 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.1   | stable  |
    And the current account has the following "artifact" rows:
      | release_id                           | filename           | filetype | platform |
      | fffa0764-3a19-48ea-beb3-8950563c7357 | Test-App-1.0.0.dmg | dmg      | macos    |
      | 165d5389-e535-4f36-9232-ed59c67375d1 | Test-App-1.0.1.dmg | dmg      | macos    |
    And AWS S3 is responding with a 404 status
    And I am an admin of account "test1"
    And I use an authentication token
    And I use API version "1.0"
    When I send a GET request to "/accounts/test1/releases/$0/actions/upgrade"
    Then the response status should be "204"

  Scenario: Admin retrieves an upgrade for a product release (artifact timing out)
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name     |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test App |
    And the current account has the following "release" rows:
      | product_id                           | version      | filename           | filetype | platform | channel |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0        | Test-App-1.0.0.dmg | dmg      | macos    | stable  |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.1        | Test-App-1.0.1.dmg | dmg      | macos    | stable  |
    And AWS S3 is timing out
    And I am an admin of account "test1"
    And I use an authentication token
    And I use API version "1.0"
    When I send a GET request to "/accounts/test1/releases/$0/actions/upgrade"
    Then the response status should be "204"

  # Environments
  @ee
  Scenario: Environment retrieves an upgrade for an isolated release
    Given the current account is "test1"
    And the current account has the following "environment" rows:
      | id                                   | name     | code     | isolation_strategy |
      | bf20fe24-351d-47d0-b3c3-2c576a63d22f | Isolated | isolated | ISOLATED           |
      | 60e7f35f-5401-4cc2-abd3-999b2a758ee1 | Shared   | shared   | SHARED             |
    And the current account has the following "product" rows:
      | id                                   | environment_id                       | name         |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | Isolated App |
      | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | 60e7f35f-5401-4cc2-abd3-999b2a758ee1 | Shared App   |
    And the current account has the following "release" rows:
      | id                                   | environment_id                       | product_id                           | version      | channel |
      | e7ac958a-7828-4d8e-8ac3-ef56021ea3c6 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0        | stable  |
      | c09699a3-5cee-4188-8e3c-51483d418a19 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.1        | stable  |
      | f1f7fe53-b502-4ec3-ab70-9ca1d1d0ccbd | bf20fe24-351d-47d0-b3c3-2c576a63d22f | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.0        | stable  |
      | a8b9a69c-5260-441d-9c32-179a0bdbcefe | 60e7f35f-5401-4cc2-abd3-999b2a758ee1 | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | 1.0.0        | stable  |
      | 674bba69-ae0a-41ab-94df-5c4ea65d507e | 60e7f35f-5401-4cc2-abd3-999b2a758ee1 | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | 2.0.0-beta.1 | dev     |
    And the current account has the following "artifact" rows:
      | release_id                           | environment_id                       | filename                  | filetype | platform | arch  |
      | e7ac958a-7828-4d8e-8ac3-ef56021ea3c6 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | Test-App-1.0.0.zip        | zip      | macos    | x86   |
      | c09699a3-5cee-4188-8e3c-51483d418a19 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | Test-App-1.0.1.zip        | zip      | macos    | x86   |
      | f1f7fe53-b502-4ec3-ab70-9ca1d1d0ccbd | bf20fe24-351d-47d0-b3c3-2c576a63d22f | Test-App-1.1.0.zip        | zip      | macos    | x86   |
      | a8b9a69c-5260-441d-9c32-179a0bdbcefe | 60e7f35f-5401-4cc2-abd3-999b2a758ee1 | Test-App-1.0.0.zip        | zip      | win32    | amd64 |
      | 674bba69-ae0a-41ab-94df-5c4ea65d507e | 60e7f35f-5401-4cc2-abd3-999b2a758ee1 | Test-App-2.0.0-beta.1.zip | zip      | win32    | amd64 |
    And I am a product of account "test1"
    And I use an authentication token
    And I use API version "1.0"
    When I send a GET request to "/accounts/test1/releases/$1/actions/upgrade?environment=isolated"
    Then the response status should be "303"
    And the response body should be an "artifact"
    And the response body should contain meta which includes the following:
      """
      {
        "current": "1.0.1",
        "next": "1.1.0"
      }
      """

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
    And the current account has the following "artifact" rows:
      | release_id                           | filename           | filetype | platform |
      | e26e9fef-d1ce-43d3-a15c-c8fc94429709 | Test-App-1.0.0.dmg | dmg      | macos    |
      | ff04d1c4-cc04-4d19-985a-cb113827b821 | Test-App-1.2.0.dmg | dmg      | macos    |
      | c8b55f91-e66f-4093-ae4d-7f3d390eae8d | Test-App-1.0.1.zip | zip      | macos    |
      | dde54ea8-731d-4375-9d57-186ef01f3fcb | Test-App-1.1.0.zip | zip      | macos    |
      | a7fad100-04eb-418f-8af9-e5eac497ad5a | Test-App-1.3.0.zip | zip      | macos    |
    And I am a product of account "test1"
    And I use an authentication token
    And I use API version "1.0"
    When I send a GET request to "/accounts/test1/releases/$0/actions/upgrade"
    Then the response status should be "303"
    And the response body should be an "artifact"
    And the response body should contain meta which includes the following:
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
      | id                                   | product_id                           | version | channel |
      | e26e9fef-d1ce-43d3-a15c-c8fc94429709 | 6198261a-48b5-4445-a045-9fed4afc7735 | 0.1.0   | stable  |
      | ff04d1c4-cc04-4d19-985a-cb113827b821 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0   | stable  |
      | c8b55f91-e66f-4093-ae4d-7f3d390eae8d | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0   | stable  |
    And the current account has the following "artifact" rows:
      | release_id                           | filename           | filetype | platform |
      | e26e9fef-d1ce-43d3-a15c-c8fc94429709 | Test-App-0.1.0.dmg | dmg      | macos    |
      | ff04d1c4-cc04-4d19-985a-cb113827b821 | Test-App-1.0.0.dmg | dmg      | macos    |
      | c8b55f91-e66f-4093-ae4d-7f3d390eae8d | Test-App-2.0.0.exe | exe      | win32    |
    And I am a product of account "test1"
    And I use an authentication token
    And I use API version "1.0"
    When I send a GET request to "/accounts/test1/releases/$1/actions/upgrade"
    Then the response status should be "204"

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
    And the current account has the following "artifact" rows:
      | release_id                           | filename             | filetype | platform |
      | e26e9fef-d1ce-43d3-a15c-c8fc94429709 | Test-App-B-1.0.0.exe | exe      | win32    |
      | ff04d1c4-cc04-4d19-985a-cb113827b821 | Test-App-B-2.0.0.exe | exe      | win32    |
    And I am a product of account "test1"
    And I use an authentication token
    And I use API version "1.0"
    When I send a GET request to "/accounts/test1/releases/$0/actions/upgrade"
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
    And the current account has the following "artifact" rows:
      | release_id                           | filename                  | filetype | platform |
      | e314ba5d-c760-4e54-81c4-fa01af68ff66 | Test-App-1.0.0.dmg        | dmg      | macos    |
      | e26e9fef-d1ce-43d3-a15c-c8fc94429709 | Test-App-1.2.0.dmg        | dmg      | macos    |
      | ff04d1c4-cc04-4d19-985a-cb113827b821 | Test-App-1.0.1.zip        | zip      | macos    |
      | c8b55f91-e66f-4093-ae4d-7f3d390eae8d | Test-App-1.1.0.zip        | zip      | macos    |
      | dde54ea8-731d-4375-9d57-186ef01f3fcb | Test-App-1.3.0.zip        | zip      | macos    |
      | a7fad100-04eb-418f-8af9-e5eac497ad5a | Test-App-2.0.0-beta.1.zip | zip      | macos    |
    And the current account has 1 "policy" for the first "product"
    And the current account has 1 "license" for the first "policy"
    And I am a license of account "test1"
    And I use an authentication token
    And I use API version "1.0"
    When I send a GET request to "/accounts/test1/releases/$2/actions/upgrade"
    Then the response status should be "303"
    And the response body should be an "artifact"
    And the response body should contain meta which includes the following:
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
      | id                                   | product_id                           | version      | channel |
      | e314ba5d-c760-4e54-81c4-fa01af68ff66 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0        | stable  |
      | e26e9fef-d1ce-43d3-a15c-c8fc94429709 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.2.0        | stable  |
      | ff04d1c4-cc04-4d19-985a-cb113827b821 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.1        | stable  |
      | c8b55f91-e66f-4093-ae4d-7f3d390eae8d | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.0        | stable  |
      | dde54ea8-731d-4375-9d57-186ef01f3fcb | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.3.0        | stable  |
      | a7fad100-04eb-418f-8af9-e5eac497ad5a | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0-beta.1 | beta    |
    And the current account has the following "artifact" rows:
      | release_id                           | filename                  | filetype | platform |
      | e314ba5d-c760-4e54-81c4-fa01af68ff66 | Test-App-1.0.0.dmg        | dmg      | macos    |
      | e26e9fef-d1ce-43d3-a15c-c8fc94429709 | Test-App-1.2.0.dmg        | dmg      | macos    |
      | ff04d1c4-cc04-4d19-985a-cb113827b821 | Test-App-1.0.1.zip        | zip      | macos    |
      | c8b55f91-e66f-4093-ae4d-7f3d390eae8d | Test-App-1.1.0.zip        | zip      | macos    |
      | dde54ea8-731d-4375-9d57-186ef01f3fcb | Test-App-1.3.0.zip        | zip      | macos    |
      | a7fad100-04eb-418f-8af9-e5eac497ad5a | Test-App-2.0.0-beta.1.zip | zip      | macos    |
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
    And I use API version "1.0"
    When I send a GET request to "/accounts/test1/releases/$2/actions/upgrade"
    Then the response status should be "204"

  Scenario: License retrieves an upgrade for a release of their product (expired, but access revoked)
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
    And the current account has the following "artifact" rows:
      | release_id                           | filename                  | filetype | platform |
      | e314ba5d-c760-4e54-81c4-fa01af68ff66 | Test-App-1.0.0.dmg        | dmg      | macos    |
      | e26e9fef-d1ce-43d3-a15c-c8fc94429709 | Test-App-1.2.0.dmg        | dmg      | macos    |
      | ff04d1c4-cc04-4d19-985a-cb113827b821 | Test-App-1.0.1.zip        | zip      | macos    |
      | c8b55f91-e66f-4093-ae4d-7f3d390eae8d | Test-App-1.1.0.zip        | zip      | macos    |
      | dde54ea8-731d-4375-9d57-186ef01f3fcb | Test-App-1.3.0.zip        | zip      | macos    |
      | a7fad100-04eb-418f-8af9-e5eac497ad5a | Test-App-2.0.0-beta.1.zip | zip      | macos    |
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
    And I use API version "1.0"
    When I send a GET request to "/accounts/test1/releases/$2/actions/upgrade"
    Then the response status should be "204"

  Scenario: License retrieves an upgrade for a release of their product (expired, access maintained)
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
    And the current account has the following "artifact" rows:
      | release_id                           | filename                  | filetype | platform |
      | e314ba5d-c760-4e54-81c4-fa01af68ff66 | Test-App-1.0.0.dmg        | dmg      | macos    |
      | e26e9fef-d1ce-43d3-a15c-c8fc94429709 | Test-App-1.2.0.dmg        | dmg      | macos    |
      | ff04d1c4-cc04-4d19-985a-cb113827b821 | Test-App-1.0.1.zip        | zip      | macos    |
      | c8b55f91-e66f-4093-ae4d-7f3d390eae8d | Test-App-1.1.0.zip        | zip      | macos    |
      | dde54ea8-731d-4375-9d57-186ef01f3fcb | Test-App-1.3.0.zip        | zip      | macos    |
      | a7fad100-04eb-418f-8af9-e5eac497ad5a | Test-App-2.0.0-beta.1.zip | zip      | macos    |
    And the current account has 1 "policy" for the first "product"
    And the first "policy" has the following attributes:
      """
      { "expirationStrategy": "MAINTAIN_ACCESS" }
      """
    And the current account has 1 "license" for the first "policy"
    And the first "license" has the following attributes:
      """
      { "expiry": "$time.2.months.ago" }
      """
    And I am a license of account "test1"
    And I use an authentication token
    And I use API version "1.0"
    When I send a GET request to "/accounts/test1/releases/$2/actions/upgrade"
    Then the response status should be "204"

  Scenario: License retrieves an upgrade for a release of their product (expired, access allowed)
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
    And the current account has the following "artifact" rows:
      | release_id                           | filename                  | filetype | platform |
      | e314ba5d-c760-4e54-81c4-fa01af68ff66 | Test-App-1.0.0.dmg        | dmg      | macos    |
      | e26e9fef-d1ce-43d3-a15c-c8fc94429709 | Test-App-1.2.0.dmg        | dmg      | macos    |
      | ff04d1c4-cc04-4d19-985a-cb113827b821 | Test-App-1.0.1.zip        | zip      | macos    |
      | c8b55f91-e66f-4093-ae4d-7f3d390eae8d | Test-App-1.1.0.zip        | zip      | macos    |
      | dde54ea8-731d-4375-9d57-186ef01f3fcb | Test-App-1.3.0.zip        | zip      | macos    |
      | a7fad100-04eb-418f-8af9-e5eac497ad5a | Test-App-2.0.0-beta.1.zip | zip      | macos    |
    And the current account has 1 "policy" for the first "product"
    And the first "policy" has the following attributes:
      """
      { "expirationStrategy": "ALLOW_ACCESS" }
      """
    And the current account has 1 "license" for the first "policy"
    And the first "license" has the following attributes:
      """
      { "expiry": "$time.2.months.ago" }
      """
    And I am a license of account "test1"
    And I use an authentication token
    And I use API version "1.0"
    When I send a GET request to "/accounts/test1/releases/$2/actions/upgrade"
    Then the response status should be "303"
    And the response body should be an "artifact"
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
    And the current account has the following "artifact" rows:
      | release_id                           | filename                  | filetype | platform |
      | e314ba5d-c760-4e54-81c4-fa01af68ff66 | Test-App-1.0.0.dmg        | dmg      | macos    |
      | e26e9fef-d1ce-43d3-a15c-c8fc94429709 | Test-App-1.2.0.dmg        | dmg      | macos    |
      | ff04d1c4-cc04-4d19-985a-cb113827b821 | Test-App-1.0.1.zip        | zip      | macos    |
      | c8b55f91-e66f-4093-ae4d-7f3d390eae8d | Test-App-1.1.0.zip        | zip      | macos    |
      | dde54ea8-731d-4375-9d57-186ef01f3fcb | Test-App-1.3.0.zip        | zip      | macos    |
      | a7fad100-04eb-418f-8af9-e5eac497ad5a | Test-App-2.0.0-beta.1.zip | zip      | macos    |
    And the current account has 1 "policy" for the first "product"
    And the current account has 1 "license" for the first "policy"
    And the first "license" has the following attributes:
      """
      { "suspended": true }
      """
    And I am a license of account "test1"
    And I use an authentication token
    And I use API version "1.0"
    When I send a GET request to "/accounts/test1/releases/$2/actions/upgrade"
    Then the response status should be "204"

  Scenario: License retrieves an upgrade for a release of their product (key auth, expired, but access restricted)
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
    And the current account has the following "artifact" rows:
      | release_id                           | filename                  | filetype | platform |
      | e314ba5d-c760-4e54-81c4-fa01af68ff66 | Test-App-1.0.0.dmg        | dmg      | macos    |
      | e26e9fef-d1ce-43d3-a15c-c8fc94429709 | Test-App-1.2.0.dmg        | dmg      | macos    |
      | ff04d1c4-cc04-4d19-985a-cb113827b821 | Test-App-1.0.1.zip        | zip      | macos    |
      | c8b55f91-e66f-4093-ae4d-7f3d390eae8d | Test-App-1.1.0.zip        | zip      | macos    |
      | dde54ea8-731d-4375-9d57-186ef01f3fcb | Test-App-1.3.0.zip        | zip      | macos    |
      | a7fad100-04eb-418f-8af9-e5eac497ad5a | Test-App-2.0.0-beta.1.zip | zip      | macos    |
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
      { "expiry": "$time.2.months.ago" }
      """
    And I am a license of account "test1"
    And I authenticate with my key
    And I use API version "1.0"
    When I send a GET request to "/accounts/test1/releases/$2/actions/upgrade"
    Then the response status should be "204"

  Scenario: License retrieves an upgrade for a release of their product (key auth, expired, but access revoked)
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
    And the current account has the following "artifact" rows:
      | release_id                           | filename                  | filetype | platform |
      | e314ba5d-c760-4e54-81c4-fa01af68ff66 | Test-App-1.0.0.dmg        | dmg      | macos    |
      | e26e9fef-d1ce-43d3-a15c-c8fc94429709 | Test-App-1.2.0.dmg        | dmg      | macos    |
      | ff04d1c4-cc04-4d19-985a-cb113827b821 | Test-App-1.0.1.zip        | zip      | macos    |
      | c8b55f91-e66f-4093-ae4d-7f3d390eae8d | Test-App-1.1.0.zip        | zip      | macos    |
      | dde54ea8-731d-4375-9d57-186ef01f3fcb | Test-App-1.3.0.zip        | zip      | macos    |
      | a7fad100-04eb-418f-8af9-e5eac497ad5a | Test-App-2.0.0-beta.1.zip | zip      | macos    |
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
      { "expiry": "$time.6.months.ago" }
      """
    And I am a license of account "test1"
    And I authenticate with my key
    And I use API version "1.0"
    When I send a GET request to "/accounts/test1/releases/$2/actions/upgrade"
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
    And the current account has the following "artifact" rows:
      | release_id                           | filename                  | filetype | platform |
      | e314ba5d-c760-4e54-81c4-fa01af68ff66 | Test-App-1.0.0.dmg        | dmg      | macos    |
      | e26e9fef-d1ce-43d3-a15c-c8fc94429709 | Test-App-1.2.0.dmg        | dmg      | macos    |
      | ff04d1c4-cc04-4d19-985a-cb113827b821 | Test-App-1.0.1.zip        | zip      | macos    |
      | c8b55f91-e66f-4093-ae4d-7f3d390eae8d | Test-App-1.1.0.zip        | zip      | macos    |
      | dde54ea8-731d-4375-9d57-186ef01f3fcb | Test-App-1.3.0.zip        | zip      | macos    |
      | a7fad100-04eb-418f-8af9-e5eac497ad5a | Test-App-2.0.0-beta.1.zip | zip      | macos    |
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
    And I use API version "1.0"
    When I send a GET request to "/accounts/test1/releases/$2/actions/upgrade"
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
    And the current account has the following "artifact" rows:
      | release_id                           | filename                  | filetype | platform |
      | e314ba5d-c760-4e54-81c4-fa01af68ff66 | Test-App-1.0.0.dmg        | dmg      | macos    |
      | e26e9fef-d1ce-43d3-a15c-c8fc94429709 | Test-App-1.2.0.dmg        | dmg      | macos    |
      | ff04d1c4-cc04-4d19-985a-cb113827b821 | Test-App-1.0.1.zip        | zip      | macos    |
      | c8b55f91-e66f-4093-ae4d-7f3d390eae8d | Test-App-1.1.0.zip        | zip      | macos    |
      | dde54ea8-731d-4375-9d57-186ef01f3fcb | Test-App-1.3.0.zip        | zip      | macos    |
      | a7fad100-04eb-418f-8af9-e5eac497ad5a | Test-App-2.0.0-beta.1.zip | zip      | macos    |
    And the current account has 1 "license"
    And I am a license of account "test1"
    And I use an authentication token
    And I use API version "1.0"
    When I send a GET request to "/accounts/test1/releases/$2/actions/upgrade"
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
    And the current account has the following "artifact" rows:
      | release_id                           | filename           | filetype | platform |
      | e314ba5d-c760-4e54-81c4-fa01af68ff66 | Test-App-1.0.0.dmg | dmg      | macos    |
      | e26e9fef-d1ce-43d3-a15c-c8fc94429709 | Test-App-1.1.0.dmg | dmg      | macos    |
      | ff04d1c4-cc04-4d19-985a-cb113827b821 | Test-App-1.2.0.zip | zip      | macos    |
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
    And I use API version "1.0"
    When I send a GET request to "/accounts/test1/releases/$0/actions/upgrade"
    Then the response status should be "303"
    And the response body should be an "artifact"
    And the response body should contain meta which includes the following:
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
      | id                                   | product_id                           | version       | channel |
      | e314ba5d-c760-4e54-81c4-fa01af68ff66 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0-alpha.1 | alpha   |
      | e26e9fef-d1ce-43d3-a15c-c8fc94429709 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0         | stable  |
    And the current account has the following "artifact" rows:
      | release_id                           | filename                   | filetype | platform |
      | e314ba5d-c760-4e54-81c4-fa01af68ff66 | Test-App-1.0.0-alpha.1.dmg | dmg      | macos    |
      | e26e9fef-d1ce-43d3-a15c-c8fc94429709 | Test-App-1.0.0.dmg         | dmg      | macos    |
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
    And I use API version "1.0"
    When I send a GET request to "/accounts/test1/releases/$0/actions/upgrade?channel=alpha"
    Then the response status should be "303"
    And the response body should be an "artifact"
    And the response body should contain meta which includes the following:
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
      | id                                   | product_id                           | version       | channel |
      | e314ba5d-c760-4e54-81c4-fa01af68ff66 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0-alpha.1 | alpha   |
      | e26e9fef-d1ce-43d3-a15c-c8fc94429709 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0         | stable  |
    And the current account has the following "artifact" rows:
      | release_id                           | filename                   | filetype | platform |
      | e314ba5d-c760-4e54-81c4-fa01af68ff66 | Test-App-1.0.0-alpha.1.dmg | dmg      | macos    |
      | e26e9fef-d1ce-43d3-a15c-c8fc94429709 | Test-App-1.0.0.dmg         | dmg      | macos    |
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
    And I use API version "1.0"
    When I send a GET request to "/accounts/test1/releases/$0/actions/upgrade"
    Then the response status should be "204"

  Scenario: License retrieves an upgrade for a release of their product (missing all entitlements)
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name     |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test App |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | version       | channel |
      | e314ba5d-c760-4e54-81c4-fa01af68ff66 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0-alpha.1 | alpha   |
      | e26e9fef-d1ce-43d3-a15c-c8fc94429709 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0         | stable  |
    And the current account has the following "artifact" rows:
      | release_id                           | filename                   | filetype | platform |
      | e314ba5d-c760-4e54-81c4-fa01af68ff66 | Test-App-1.0.0-alpha.1.dmg | dmg      | macos    |
      | e26e9fef-d1ce-43d3-a15c-c8fc94429709 | Test-App-1.0.0.dmg         | dmg      | macos    |
    And the current account has 1 "policy" for an existing "product"
    And the current account has 1 "license" for an existing "policy"
    And the current account has 2 "release-entitlement-constraints" for the first "release"
    And the current account has 2 "release-entitlement-constraints" for the second "release"
    And I am a license of account "test1"
    And I use an authentication token
    And I use API version "1.0"
    When I send a GET request to "/accounts/test1/releases/$0/actions/upgrade"
    Then the response status should be "404"

  # Upgrade by filename
  Scenario: Admin retrieves an upgrade for a product release (upgrade available)
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name     |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test App |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | version       | channel |
      | e314ba5d-c760-4e54-81c4-fa01af68ff66 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0-alpha.1 | alpha   |
      | e26e9fef-d1ce-43d3-a15c-c8fc94429709 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0         | stable  |
    And the current account has the following "artifact" rows:
      | release_id                           | filename                   | filetype | platform |
      | e314ba5d-c760-4e54-81c4-fa01af68ff66 | Test-App-1.0.0-alpha.1.dmg | dmg      | macos    |
      | e26e9fef-d1ce-43d3-a15c-c8fc94429709 | Test-App-1.0.0.dmg         | dmg      | macos    |
    And I am an admin of account "test1"
    And I use an authentication token
    And I use API version "1.0"
    When I send a GET request to "/accounts/test1/releases/Test-App-1.0.0.dmg/actions/upgrade"
    Then the response status should be "404"

  # Users
  Scenario: User retrieves an upgrade for a release of their product (upgrade available)
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
    And the current account has the following "artifact" rows:
      | release_id                           | filename                  | filetype | platform |
      | e314ba5d-c760-4e54-81c4-fa01af68ff66 | Test-App-1.0.0.dmg        | dmg      | macos    |
      | e26e9fef-d1ce-43d3-a15c-c8fc94429709 | Test-App-1.2.0.dmg        | dmg      | macos    |
      | ff04d1c4-cc04-4d19-985a-cb113827b821 | Test-App-1.0.1.zip        | zip      | macos    |
      | c8b55f91-e66f-4093-ae4d-7f3d390eae8d | Test-App-1.1.0.zip        | zip      | macos    |
      | dde54ea8-731d-4375-9d57-186ef01f3fcb | Test-App-1.3.0.zip        | zip      | macos    |
      | a7fad100-04eb-418f-8af9-e5eac497ad5a | Test-App-2.0.0-beta.1.zip | zip      | macos    |
    And the current account has 1 "policy" for the first "product"
    And the current account has 1 "license" for the first "policy"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    And I use API version "1.0"
    And the current user has 1 "license"
    When I send a GET request to "/accounts/test1/releases/$2/actions/upgrade?channel=beta"
    Then the response status should be "303"
    And the response body should be an "artifact"
    And the response body should contain meta which includes the following:
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
      | id                                   | product_id                           | version | channel |
      | e314ba5d-c760-4e54-81c4-fa01af68ff66 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0   | stable  |
      | e26e9fef-d1ce-43d3-a15c-c8fc94429709 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.2.0   | stable  |
      | ff04d1c4-cc04-4d19-985a-cb113827b821 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.1   | stable  |
    And the current account has the following "artifact" rows:
      | release_id                           | filename           | filetype | platform |
      | e314ba5d-c760-4e54-81c4-fa01af68ff66 | Test-App-1.0.0.dmg | dmg      | macos    |
      | e26e9fef-d1ce-43d3-a15c-c8fc94429709 | Test-App-1.2.0.dmg | dmg      | macos    |
      | ff04d1c4-cc04-4d19-985a-cb113827b821 | Test-App-1.0.1.zip | zip      | macos    |
    And the current account has 1 "policy" for the first "product"
    And the current account has 1 "license" for the first "policy"
    And the first "license" has the following attributes:
      """
      { "expiry": "$time.2.months.ago" }
      """
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    And I use API version "1.0"
    And the current user has 1 "license"
    When I send a GET request to "/accounts/test1/releases/$0/actions/upgrade"
    Then the response status should be "204"

  Scenario: User retrieves an upgrade for a release of their product (suspended)
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name     |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test App |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | version | channel |
      | e314ba5d-c760-4e54-81c4-fa01af68ff66 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0   | stable  |
      | e26e9fef-d1ce-43d3-a15c-c8fc94429709 | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0   | stable  |
    And the current account has the following "artifact" rows:
      | release_id                           | filename           | filetype | platform |
      | e314ba5d-c760-4e54-81c4-fa01af68ff66 | Test-App-1.0.0.exe | exe      | win32    |
      | e26e9fef-d1ce-43d3-a15c-c8fc94429709 | Test-App-2.0.0.exe | exe      | win32    |
    And the current account has 1 "policy" for the first "product"
    And the current account has 1 "license" for the first "policy"
    And the first "license" has the following attributes:
      """
      { "suspended": true }
      """
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    And I use API version "1.0"
    And the current user has 1 "license"
    When I send a GET request to "/accounts/test1/releases/$0/actions/upgrade"
    Then the response status should be "204"

  Scenario: License retrieves an upgrade for a release of a different product
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name     |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test App |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | version | channel |
      | e314ba5d-c760-4e54-81c4-fa01af68ff66 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0   | stable  |
      | e26e9fef-d1ce-43d3-a15c-c8fc94429709 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.0   | stable  |
    And the current account has the following "artifact" rows:
      | release_id                           | filename              | filetype | platform |
      | e314ba5d-c760-4e54-81c4-fa01af68ff66 | Test-App-1.0.0.tar.gz | tar.gz   | linux    |
      | e26e9fef-d1ce-43d3-a15c-c8fc94429709 | Test-App-1.1.0.tar.gz | tar.gz   | linux    |
    And the current account has 1 "license"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    And I use API version "1.0"
    And the current user has 1 "license"
    When I send a GET request to "/accounts/test1/releases/$0/actions/upgrade"
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
    And the current account has the following "artifact" rows:
      | release_id                           | filename           | filetype | platform |
      | e314ba5d-c760-4e54-81c4-fa01af68ff66 | Test-App-1.0.0.dmg | dmg      | macos    |
      | e26e9fef-d1ce-43d3-a15c-c8fc94429709 | Test-App-1.1.0.dmg | dmg      | macos    |
      | ff04d1c4-cc04-4d19-985a-cb113827b821 | Test-App-1.2.0.zip | zip      | macos    |
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
    And I use API version "1.0"
    And the current user has 1 "license"
    When I send a GET request to "/accounts/test1/releases/$0/actions/upgrade"
    Then the response status should be "303"
    And the response body should be an "artifact"
    And the response body should contain meta which includes the following:
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
      | id                                   | product_id                           | version       | channel |
      | e314ba5d-c760-4e54-81c4-fa01af68ff66 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0-alpha.1 | alpha   |
      | e26e9fef-d1ce-43d3-a15c-c8fc94429709 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0         | stable  |
    And the current account has the following "artifact" rows:
      | release_id                           | filename                   | filetype | platform |
      | e314ba5d-c760-4e54-81c4-fa01af68ff66 | Test-App-1.0.0-alpha.1.dmg | dmg      | macos    |
      | e26e9fef-d1ce-43d3-a15c-c8fc94429709 | Test-App-1.0.0.dmg         | dmg      | macos    |
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
    And I use API version "1.0"
    And the current user has 1 "license"
    When I send a GET request to "/accounts/test1/releases/$0/actions/upgrade"
    Then the response status should be "303"
    And the response body should be an "artifact"
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
    And the current account has the following "artifact" rows:
      | release_id                           | filename                   | filetype | platform |
      | e314ba5d-c760-4e54-81c4-fa01af68ff66 | Test-App-1.0.0-alpha.1.dmg | dmg      | macos    |
      | e26e9fef-d1ce-43d3-a15c-c8fc94429709 | Test-App-1.0.0.dmg         | dmg      | macos    |
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
    And I use API version "1.0"
    And the current user has 1 "license"
    When I send a GET request to "/accounts/test1/releases/$0/actions/upgrade"
    Then the response status should be "204"

  Scenario: User retrieves an upgrade for a release of their product (missing all entitlements)
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name     |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test App |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | version       | channel |
      | e314ba5d-c760-4e54-81c4-fa01af68ff66 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0-alpha.1 | alpha   |
      | e26e9fef-d1ce-43d3-a15c-c8fc94429709 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0         | stable  |
    And the current account has the following "artifact" rows:
      | release_id                           | filename                   | filetype | platform |
      | e314ba5d-c760-4e54-81c4-fa01af68ff66 | Test-App-1.0.0-alpha.1.dmg | dmg      | macos    |
      | e26e9fef-d1ce-43d3-a15c-c8fc94429709 | Test-App-1.0.0.dmg         | dmg      | macos    |
    And the current account has 1 "policy" for an existing "product"
    And the current account has 1 "license" for an existing "policy"
    And the current account has 2 "release-entitlement-constraints" for the first "release"
    And the current account has 2 "release-entitlement-constraints" for the second "release"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    And I use API version "1.0"
    And the current user has 1 "license"
    When I send a GET request to "/accounts/test1/releases/$0/actions/upgrade"
    Then the response status should be "404"

  # Upgrade by query
  Scenario: Admin retrieves an upgrade for a product release (upgrade available)
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name     |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test App |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | version | channel |
      | 9ddb76a5-7eb1-4ca1-b54b-926c6cddc778 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0   | stable  |
      | 55cf485e-de9e-4561-8b41-50649141bc49 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.1   | stable  |
      | 55e2e6bc-bec0-4cb6-b9f0-175f0c5c5a15 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.2   | stable  |
      | bb416eb1-2119-4d46-bbaa-304962aa102a | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.3   | stable  |
      | 3b5e1c28-0bfe-4e67-9c31-732fb82cbefb | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.0   | stable  |
      | d4db720c-4d00-4a5d-b0cf-def59ae2f99e | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.1   | stable  |
      | 92c6b69a-c0d0-4ee8-ba6f-cfae75593ccc | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.2   | stable  |
      | 00959a09-7eb6-44a4-b519-e84c62319a09 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.2.0   | stable  |
      | 137887e2-f0d2-4557-b3de-1a14d3260df7 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.3.0   | stable  |
      | 92f7fddb-7c4b-4876-82a0-50f776a65b4e | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.4.0   | stable  |
      | af4e4b5e-fd0b-487b-87b0-8fde99600528 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.5.0   | stable  |
      | b2db715f-647e-4dd3-a753-f4fd45b75fb3 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.6.0   | stable  |
      | 787ef96f-44da-440c-9020-de6637337743 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.7.0   | stable  |
    And the current account has the following "artifact" rows:
      | release_id                           | filename            | filetype | platform |
      | 9ddb76a5-7eb1-4ca1-b54b-926c6cddc778 | Test-App-1.0.0.dmg  | dmg      | macos    |
      | 55cf485e-de9e-4561-8b41-50649141bc49 | Test-App-1.0.1.dmg  | dmg      | macos    |
      | 55e2e6bc-bec0-4cb6-b9f0-175f0c5c5a15 | Test-App-1.0.2.dmg  | dmg      | macos    |
      | bb416eb1-2119-4d46-bbaa-304962aa102a | Test-App-1.0.3.dmg  | dmg      | macos    |
      | 3b5e1c28-0bfe-4e67-9c31-732fb82cbefb | Test-App-1.1.0.dmg  | dmg      | macos    |
      | d4db720c-4d00-4a5d-b0cf-def59ae2f99e | Test-App-1.1.1.dmg  | dmg      | macos    |
      | 92c6b69a-c0d0-4ee8-ba6f-cfae75593ccc | Test-App-1.1.2.dmg  | dmg      | macos    |
      | 00959a09-7eb6-44a4-b519-e84c62319a09 | Test-App-1.2.0.dmg  | dmg      | macos    |
      | 137887e2-f0d2-4557-b3de-1a14d3260df7 | Test-App-1.3.0.dmg  | dmg      | macos    |
      | 92f7fddb-7c4b-4876-82a0-50f776a65b4e | Test-App-1.4.0.dmg  | dmg      | macos    |
      | af4e4b5e-fd0b-487b-87b0-8fde99600528 | Test-App-1.5.0.dmg  | dmg      | macos    |
      | b2db715f-647e-4dd3-a753-f4fd45b75fb3 | Test-App-1.6.0.dmg  | dmg      | macos    |
      | 787ef96f-44da-440c-9020-de6637337743 | Test-App-1.7.0.dmg  | dmg      | macos    |
    And I am an admin of account "test1"
    And I use an authentication token
    And I use API version "1.0"
    When I send a GET request to "/accounts/test1/releases/actions/upgrade?version=1.1.1&platform=macos&filetype=dmg&product=6198261a-48b5-4445-a045-9fed4afc7735"
    Then the response status should be "303"
    And the response body should be an "artifact" with the following attributes:
      """
      { "key": "Test-App-1.7.0.dmg" }
      """
    And the response body should contain meta which includes the following:
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
      | id                                   | product_id                           | version | channel |
      | 9ddb76a5-7eb1-4ca1-b54b-926c6cddc778 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0   | stable  |
      | 55cf485e-de9e-4561-8b41-50649141bc49 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.0   | stable  |
    And the current account has the following "artifact" rows:
      | release_id                           | filename           | filetype | platform |
      | 9ddb76a5-7eb1-4ca1-b54b-926c6cddc778 | Test-App-1.0.0.zip | zip      | macos    |
      | 55cf485e-de9e-4561-8b41-50649141bc49 | Test-App-1.1.0.zip | zip      | macos    |
    And I am an admin of account "test1"
    And I use an authentication token
    And I use API version "1.0"
    When I send a GET request to "/accounts/test1/releases/actions/upgrade?version=1.0.0&platform=win32&filetype=zip&product=6198261a-48b5-4445-a045-9fed4afc7735"
    Then the response status should be "204"

  Scenario: Admin retrieves an upgrade for a product release (unknown filetype)
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name     |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test App |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | version | channel |
      | 9ddb76a5-7eb1-4ca1-b54b-926c6cddc778 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0   | stable  |
      | 55cf485e-de9e-4561-8b41-50649141bc49 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.0   | stable  |
    And the current account has the following "artifact" rows:
      | release_id                           | filename           | filetype | platform |
      | 9ddb76a5-7eb1-4ca1-b54b-926c6cddc778 | Test-App-1.0.0.zip | zip      | macos    |
      | 55cf485e-de9e-4561-8b41-50649141bc49 | Test-App-1.1.0.zip | zip      | macos    |
    And I am an admin of account "test1"
    And I use an authentication token
    And I use API version "1.0"
    When I send a GET request to "/accounts/test1/releases/actions/upgrade?version=1.0.0&platform=macos&filetype=dmg&product=6198261a-48b5-4445-a045-9fed4afc7735"
    Then the response status should be "204"

  Scenario: Admin retrieves an upgrade for a product release (unknown product)
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name     |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test App |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | version | channel |
      | 9ddb76a5-7eb1-4ca1-b54b-926c6cddc778 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0   | stable  |
      | 55cf485e-de9e-4561-8b41-50649141bc49 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.0   | stable  |
    And the current account has the following "artifact" rows:
      | release_id                           | filename           | filetype | platform |
      | 9ddb76a5-7eb1-4ca1-b54b-926c6cddc778 | Test-App-1.0.0.zip | zip      | macos    |
      | 55cf485e-de9e-4561-8b41-50649141bc49 | Test-App-1.1.0.zip | zip      | macos    |
    And I am an admin of account "test1"
    And I use an authentication token
    And I use API version "1.0"
    When I send a GET request to "/accounts/test1/releases/actions/upgrade?version=1.0.0&platform=macos&filetype=zip&product=4f1c06e0-a4b2-4e3e-8a19-f2ce7f2f6e62"
    Then the response status should be "204"

  Scenario: Admin retrieves an upgrade for a product release (constrained to v1.x)
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name     |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test App |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | version | channel |
      | 9ddb76a5-7eb1-4ca1-b54b-926c6cddc778 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0   | stable  |
      | 55cf485e-de9e-4561-8b41-50649141bc49 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.1   | stable  |
      | 55e2e6bc-bec0-4cb6-b9f0-175f0c5c5a15 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.0   | stable  |
      | bb416eb1-2119-4d46-bbaa-304962aa102a | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0   | stable  |
    And the current account has the following "artifact" rows:
      | release_id                           | filename           | filetype | platform |
      | 9ddb76a5-7eb1-4ca1-b54b-926c6cddc778 | Test-App-1.0.0.zip | zip      | macos    |
      | 55cf485e-de9e-4561-8b41-50649141bc49 | Test-App-1.0.1.zip | zip      | macos    |
      | 55e2e6bc-bec0-4cb6-b9f0-175f0c5c5a15 | Test-App-1.1.0.zip | zip      | macos    |
      | bb416eb1-2119-4d46-bbaa-304962aa102a | Test-App-2.0.0.zip | zip      | macos    |
    And I am an admin of account "test1"
    And I use an authentication token
    And I use API version "1.0"
    When I send a GET request to "/accounts/test1/releases/actions/upgrade?version=1.0.0&constraint=1.0&platform=macos&filetype=zip&product=6198261a-48b5-4445-a045-9fed4afc7735"
    Then the response status should be "303"
    And the response body should be an "artifact"
    And the response body should contain meta which includes the following:
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
      | id                                   | product_id                           | version | channel |
      | 9ddb76a5-7eb1-4ca1-b54b-926c6cddc778 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0   | stable  |
      | 55cf485e-de9e-4561-8b41-50649141bc49 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.0   | stable  |
      | 55e2e6bc-bec0-4cb6-b9f0-175f0c5c5a15 | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0   | stable  |
      | bb416eb1-2119-4d46-bbaa-304962aa102a | 6198261a-48b5-4445-a045-9fed4afc7735 | 3.0.0   | stable  |
    And the current account has the following "artifact" rows:
      | release_id                           | filename           | filetype | platform |
      | 9ddb76a5-7eb1-4ca1-b54b-926c6cddc778 | Test-App-1.0.0.zip | zip      | macos    |
      | 55cf485e-de9e-4561-8b41-50649141bc49 | Test-App-1.1.0.zip | zip      | macos    |
      | 55e2e6bc-bec0-4cb6-b9f0-175f0c5c5a15 | Test-App-2.0.0.zip | zip      | macos    |
      | bb416eb1-2119-4d46-bbaa-304962aa102a | Test-App-3.0.0.zip | zip      | macos    |
    And I am an admin of account "test1"
    And I use an authentication token
    And I use API version "1.0"
    When I send a GET request to "/accounts/test1/releases/actions/upgrade?version=1.0.0&constraint=2.0&platform=macos&filetype=zip&product=6198261a-48b5-4445-a045-9fed4afc7735"
    Then the response status should be "303"
    And the response body should be an "artifact"
    And the response body should contain meta which includes the following:
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
      | id                                   | product_id                           | version | channel | entitlements |
      | 47a5b2f4-a645-49b4-936f-3cf27ccb4d86 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0   | stable  | APP_V1       |
      | 1f865b63-a837-47d9-bb97-144d4bb6516d | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.1   | stable  | APP_V1       |
      | 79483f7c-f189-472f-a630-0b25925e3d46 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.2   | stable  | APP_V1       |
      | fd7a0210-da80-4d3e-a606-4f570229d929 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.3   | stable  | APP_V1       |
      | d35a4882-8d0f-47af-9c06-863f1df96353 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.0   | stable  | APP_V1       |
      | 3dac4494-e991-4dc1-9c03-428277387c57 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.1   | stable  | APP_V1       |
      | 6e2fe3dc-0427-4be5-a35a-6fce1a41f1d3 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.2   | stable  | APP_V1       |
      | c9170c9f-b735-488a-8307-7c81bea938a2 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.2.0   | stable  | APP_V1       |
      | b3ebc9cb-d12a-4498-bc32-b36fb3992ef3 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.3.0   | stable  | APP_V1       |
      | 0d834cd8-6d24-4ac2-82f8-03fac86a7f43 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.4.0   | stable  | APP_V1       |
      | 607466af-28bf-4555-872f-0cc538bcc2c0 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.5.0   | stable  | APP_V1       |
      | 6959896e-4466-4c38-895b-7756309661bb | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.6.0   | stable  | APP_V1       |
      | 97445363-19bc-4a4e-bc87-6b58664d1aa1 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.7.0   | stable  | APP_V1       |
      | 54378e18-d254-4c24-8f73-060f87ac624a | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0   | stable  | APP_V2       |
      | ea0e8c7c-b1e4-4f3b-8330-fc2123ee7f4e | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.1   | stable  | APP_V2       |
    And the current account has the following "artifact" rows:
      | release_id                           | filename                  | filetype | platform |
      | 47a5b2f4-a645-49b4-936f-3cf27ccb4d86 | Test-App-1.0.0.dmg        | dmg      | macos    |
      | 1f865b63-a837-47d9-bb97-144d4bb6516d | Test-App-1.0.1.dmg        | dmg      | macos    |
      | 79483f7c-f189-472f-a630-0b25925e3d46 | Test-App-1.0.2.dmg        | dmg      | macos    |
      | fd7a0210-da80-4d3e-a606-4f570229d929 | Test-App-1.0.3.dmg        | dmg      | macos    |
      | d35a4882-8d0f-47af-9c06-863f1df96353 | Test-App-1.1.0.dmg        | dmg      | macos    |
      | 3dac4494-e991-4dc1-9c03-428277387c57 | Test-App-1.1.1.dmg        | dmg      | macos    |
      | 6e2fe3dc-0427-4be5-a35a-6fce1a41f1d3 | Test-App-1.1.2.dmg        | dmg      | macos    |
      | c9170c9f-b735-488a-8307-7c81bea938a2 | Test-App-1.2.0.dmg        | dmg      | macos    |
      | b3ebc9cb-d12a-4498-bc32-b36fb3992ef3 | Test-App-1.3.0.dmg        | dmg      | macos    |
      | 0d834cd8-6d24-4ac2-82f8-03fac86a7f43 | Test-App-1.4.0.dmg        | dmg      | macos    |
      | 607466af-28bf-4555-872f-0cc538bcc2c0 | Test-App-1.5.0.dmg        | dmg      | macos    |
      | 6959896e-4466-4c38-895b-7756309661bb | Test-App-1.6.0.dmg        | dmg      | macos    |
      | 97445363-19bc-4a4e-bc87-6b58664d1aa1 | Test-App-1.7.0.dmg        | dmg      | macos    |
      | 54378e18-d254-4c24-8f73-060f87ac624a | Test-App-2.0.0.dmg        | dmg      | macos    |
      | ea0e8c7c-b1e4-4f3b-8330-fc2123ee7f4e | Test-App-2.0.1.dmg        | dmg      | macos    |
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
    And I use API version "1.0"
    When I send a GET request to "/accounts/test1/releases/actions/upgrade?version=1.0.0&constraint=2.0&platform=macos&filetype=dmg&product=6198261a-48b5-4445-a045-9fed4afc7735"
    Then the response status should be "303"
    And the response body should be an "artifact"
    And the response body should contain meta which includes the following:
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
      | id                                   | product_id                           | version | channel | entitlements |
      | 47a5b2f4-a645-49b4-936f-3cf27ccb4d86 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0   | stable  | APP_V1       |
      | 1f865b63-a837-47d9-bb97-144d4bb6516d | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.1   | stable  | APP_V1       |
      | 79483f7c-f189-472f-a630-0b25925e3d46 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.2   | stable  | APP_V1       |
      | fd7a0210-da80-4d3e-a606-4f570229d929 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.3   | stable  | APP_V1       |
      | d35a4882-8d0f-47af-9c06-863f1df96353 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.0   | stable  | APP_V1       |
      | 3dac4494-e991-4dc1-9c03-428277387c57 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.1   | stable  | APP_V1       |
      | 6e2fe3dc-0427-4be5-a35a-6fce1a41f1d3 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.2   | stable  | APP_V1       |
      | c9170c9f-b735-488a-8307-7c81bea938a2 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.2.0   | stable  | APP_V1       |
      | b3ebc9cb-d12a-4498-bc32-b36fb3992ef3 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.3.0   | stable  | APP_V1       |
      | 0d834cd8-6d24-4ac2-82f8-03fac86a7f43 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.4.0   | stable  | APP_V1       |
      | 607466af-28bf-4555-872f-0cc538bcc2c0 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.5.0   | stable  | APP_V1       |
      | 6959896e-4466-4c38-895b-7756309661bb | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.6.0   | stable  | APP_V1       |
      | 97445363-19bc-4a4e-bc87-6b58664d1aa1 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.7.0   | stable  | APP_V1       |
      | 54378e18-d254-4c24-8f73-060f87ac624a | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0   | stable  | APP_V2       |
      | ea0e8c7c-b1e4-4f3b-8330-fc2123ee7f4e | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.1   | stable  | APP_V2       |
    And the current account has the following "artifact" rows:
      | release_id                           | filename                  | filetype | platform |
      | 47a5b2f4-a645-49b4-936f-3cf27ccb4d86 | Test-App-1.0.0.dmg        | dmg      | macos    |
      | 1f865b63-a837-47d9-bb97-144d4bb6516d | Test-App-1.0.1.dmg        | dmg      | macos    |
      | 79483f7c-f189-472f-a630-0b25925e3d46 | Test-App-1.0.2.dmg        | dmg      | macos    |
      | fd7a0210-da80-4d3e-a606-4f570229d929 | Test-App-1.0.3.dmg        | dmg      | macos    |
      | d35a4882-8d0f-47af-9c06-863f1df96353 | Test-App-1.1.0.dmg        | dmg      | macos    |
      | 3dac4494-e991-4dc1-9c03-428277387c57 | Test-App-1.1.1.dmg        | dmg      | macos    |
      | 6e2fe3dc-0427-4be5-a35a-6fce1a41f1d3 | Test-App-1.1.2.dmg        | dmg      | macos    |
      | c9170c9f-b735-488a-8307-7c81bea938a2 | Test-App-1.2.0.dmg        | dmg      | macos    |
      | b3ebc9cb-d12a-4498-bc32-b36fb3992ef3 | Test-App-1.3.0.dmg        | dmg      | macos    |
      | 0d834cd8-6d24-4ac2-82f8-03fac86a7f43 | Test-App-1.4.0.dmg        | dmg      | macos    |
      | 607466af-28bf-4555-872f-0cc538bcc2c0 | Test-App-1.5.0.dmg        | dmg      | macos    |
      | 6959896e-4466-4c38-895b-7756309661bb | Test-App-1.6.0.dmg        | dmg      | macos    |
      | 97445363-19bc-4a4e-bc87-6b58664d1aa1 | Test-App-1.7.0.dmg        | dmg      | macos    |
      | 54378e18-d254-4c24-8f73-060f87ac624a | Test-App-2.0.0.dmg        | dmg      | macos    |
      | ea0e8c7c-b1e4-4f3b-8330-fc2123ee7f4e | Test-App-2.0.1.dmg        | dmg      | macos    |
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
    And I use API version "1.0"
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
      | id                                   | product_id                           | version | channel | entitlements |
      | 47a5b2f4-a645-49b4-936f-3cf27ccb4d86 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0   | stable  | APP_V1       |
      | 1f865b63-a837-47d9-bb97-144d4bb6516d | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.1   | stable  | APP_V1       |
      | 79483f7c-f189-472f-a630-0b25925e3d46 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.2   | stable  | APP_V1       |
      | fd7a0210-da80-4d3e-a606-4f570229d929 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.3   | stable  | APP_V1       |
      | d35a4882-8d0f-47af-9c06-863f1df96353 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.0   | stable  | APP_V1       |
      | 3dac4494-e991-4dc1-9c03-428277387c57 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.1   | stable  | APP_V1       |
      | 6e2fe3dc-0427-4be5-a35a-6fce1a41f1d3 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.2   | stable  | APP_V1       |
      | c9170c9f-b735-488a-8307-7c81bea938a2 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.2.0   | stable  | APP_V1       |
      | b3ebc9cb-d12a-4498-bc32-b36fb3992ef3 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.3.0   | stable  | APP_V1       |
      | 0d834cd8-6d24-4ac2-82f8-03fac86a7f43 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.4.0   | stable  | APP_V1       |
      | 607466af-28bf-4555-872f-0cc538bcc2c0 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.5.0   | stable  | APP_V1       |
      | 6959896e-4466-4c38-895b-7756309661bb | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.6.0   | stable  | APP_V1       |
      | 97445363-19bc-4a4e-bc87-6b58664d1aa1 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.7.0   | stable  | APP_V1       |
      | 54378e18-d254-4c24-8f73-060f87ac624a | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0   | stable  | APP_V2       |
      | ea0e8c7c-b1e4-4f3b-8330-fc2123ee7f4e | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.1   | stable  | APP_V2       |
    And the current account has the following "artifact" rows:
      | release_id                           | filename                  | filetype | platform |
      | 47a5b2f4-a645-49b4-936f-3cf27ccb4d86 | Test-App-1.0.0.dmg        | dmg      | macos    |
      | 1f865b63-a837-47d9-bb97-144d4bb6516d | Test-App-1.0.1.dmg        | dmg      | macos    |
      | 79483f7c-f189-472f-a630-0b25925e3d46 | Test-App-1.0.2.dmg        | dmg      | macos    |
      | fd7a0210-da80-4d3e-a606-4f570229d929 | Test-App-1.0.3.dmg        | dmg      | macos    |
      | d35a4882-8d0f-47af-9c06-863f1df96353 | Test-App-1.1.0.dmg        | dmg      | macos    |
      | 3dac4494-e991-4dc1-9c03-428277387c57 | Test-App-1.1.1.dmg        | dmg      | macos    |
      | 6e2fe3dc-0427-4be5-a35a-6fce1a41f1d3 | Test-App-1.1.2.dmg        | dmg      | macos    |
      | c9170c9f-b735-488a-8307-7c81bea938a2 | Test-App-1.2.0.dmg        | dmg      | macos    |
      | b3ebc9cb-d12a-4498-bc32-b36fb3992ef3 | Test-App-1.3.0.dmg        | dmg      | macos    |
      | 0d834cd8-6d24-4ac2-82f8-03fac86a7f43 | Test-App-1.4.0.dmg        | dmg      | macos    |
      | 607466af-28bf-4555-872f-0cc538bcc2c0 | Test-App-1.5.0.dmg        | dmg      | macos    |
      | 6959896e-4466-4c38-895b-7756309661bb | Test-App-1.6.0.dmg        | dmg      | macos    |
      | 97445363-19bc-4a4e-bc87-6b58664d1aa1 | Test-App-1.7.0.dmg        | dmg      | macos    |
      | 54378e18-d254-4c24-8f73-060f87ac624a | Test-App-2.0.0.dmg        | dmg      | macos    |
      | ea0e8c7c-b1e4-4f3b-8330-fc2123ee7f4e | Test-App-2.0.1.dmg        | dmg      | macos    |
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
    And I use API version "1.0"
    When I send a GET request to "/accounts/test1/releases/actions/upgrade?version=1.0.0&constraint=1.0&platform=macos&filetype=dmg&product=6198261a-48b5-4445-a045-9fed4afc7735"
    Then the response status should be "303"
    And the response body should be an "artifact"
    And the response body should contain meta which includes the following:
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
      | id                                   | product_id                           | version                    | channel |
      | f53f57cb-dc3f-4b18-9d90-534038214b49 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0-alpha.1              | alpha   |
      | 80e20324-c578-4763-bbef-c9698bf0023a | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0                      | stable  |
      | d34846b1-fdfe-46aa-9194-7d1a08e2d0cb | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.1                      | stable  |
      | f517903b-5126-4405-9793-bf95a287b1f9 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.2                      | stable  |
      | 21088509-2dfc-4459-a8a2-3204136ad1df | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.3                      | stable  |
      | 0fd7f4a3-dd48-40bc-8f1c-d4449432f8fb | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.0                      | stable  |
      | eb4d5801-5238-4825-9236-50769fce5d2f | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.1                      | stable  |
      | 298eac03-7caf-4225-8554-181920d70d75 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.2                      | stable  |
      | 4e41ac33-79ea-4dc3-b179-87d0174aaed4 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.2.0                      | stable  |
      | c1f7e75b-3aba-4bba-a0b0-d3fbe8cf7750 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.3.0                      | stable  |
      | 61992b58-c283-4c56-95d7-d83ff52bc0f4 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.4.0-beta.1               | beta    |
      | 873c088e-8d32-4d5d-afd4-11a28c58b9bc | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.4.0-beta.2               | beta    |
      | 4d2737af-0c5a-4c55-a31a-e8781261cbd5 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.4.0-beta.3               | beta    |
      | e8d06fe3-ac5f-44af-a88d-bebb2d322947 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.4.0                      | stable  |
      | f761080b-92fe-423a-a8b6-68f91d55a08a | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.5.0                      | stable  |
      | 8d1eb3ce-fb23-41a9-b66c-6328b2fde235 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.6.0                      | stable  |
      | f287e696-27cb-4d2b-978a-d6cca2d386c2 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.7.0-dev+build.1624653614 | dev     |
      | da38f541-0f22-4340-a7b5-4f7c410ded88 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.7.0                      | stable  |
      | 88d9bba0-726b-4695-aee2-28c86ff689c4 | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0-dev+build.1624653627 | dev     |
      | 8147443c-fe47-4654-9935-80a29b490905 | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0-dev+build.1624653693 | dev     |
      | 697107b8-01fb-4c05-9c95-0399e2fab5f7 | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0-dev+build.1624653702 | dev     |
      | 1849d528-e552-4def-91cb-4020a9ec995e | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0-dev+build.1624653708 | dev     |
      | 46da3538-89d1-4bcf-a478-25109a40eae5 | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0-dev+build.1624653716 | dev     |
      | 01947f94-f574-4b71-aa4f-7a5b9101a092 | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0-alpha.1              | alpha   |
      | 5f187a7d-8ab8-4a9c-85f6-9bc0331f09b4 | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0-alpha.2              | alpha   |
      | 04fc4e72-beaa-4a6f-92d7-168a0c4e924c | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0-beta.1               | beta    |
      | c2b11198-de3d-4c7c-8dd8-e3fe86650e6b | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0-beta.2               | beta    |
      | 14496b66-0004-422f-87e9-15172287bae4 | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0-beta.3               | beta    |
      | 7da7b744-1c60-441f-967d-68134c93c2d9 | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0-rc.1                 | rc      |
      | 84fe5dbf-6e41-458e-821b-d716487fbd12 | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0                      | stable  |
      | 33046ea9-2a77-46c3-b650-7b3b4bbae016 | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.1-dev+build.1624653735 | dev     |
      | aa067117-948f-46e8-977f-6998ad366a97 | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.1-dev+build.1624653760 | dev     |
      | fffa0764-3a19-48ea-beb3-8950563c7357 | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.1-rc.1                 | rc      |
      | 165d5389-e535-4f36-9232-ed59c67375d1 | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.1                      | stable  |
      | e4fa628e-593d-48bc-8e3e-5e4dda1f2c3a | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.2-dev+build.1624653771 | dev     |
      | fd10ab0c-c52a-412f-b34f-180eebd7325d | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.2-alpha.1              | alpha   |
      | f98d8c17-5fad-4361-ad89-43b0c6f6fa00 | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.2-beta.1               | beta    |
      | 077ca1f2-6125-4a77-bdf0-3161a0fc278e | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.3-alpha.1              | alpha   |
      | 0a027f00-0860-4fa7-bd37-5900c8866818 | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.1.0-dev+build.1624654615 | dev     |
    And the current account has the following "artifact" rows:
      | release_id                           | filename                   | filetype | platform |
      | f53f57cb-dc3f-4b18-9d90-534038214b49 | Test-App-1.0.0-alpha.1.dmg | dmg      | darwin   |
      | 80e20324-c578-4763-bbef-c9698bf0023a | Test-App-1.0.0.dmg         | dmg      | darwin   |
      | d34846b1-fdfe-46aa-9194-7d1a08e2d0cb | Test-App-1.0.1.dmg         | dmg      | darwin   |
      | f517903b-5126-4405-9793-bf95a287b1f9 | Test-App-1.0.2.dmg         | dmg      | darwin   |
      | 21088509-2dfc-4459-a8a2-3204136ad1df | Test-App-1.0.3.dmg         | dmg      | darwin   |
      | 0fd7f4a3-dd48-40bc-8f1c-d4449432f8fb | Test-App-1.1.0.dmg         | dmg      | darwin   |
      | eb4d5801-5238-4825-9236-50769fce5d2f | Test-App-1.1.1.dmg         | dmg      | darwin   |
      | 298eac03-7caf-4225-8554-181920d70d75 | Test-App-1.1.2.dmg         | dmg      | darwin   |
      | 4e41ac33-79ea-4dc3-b179-87d0174aaed4 | Test-App-1.2.0.dmg         | dmg      | darwin   |
      | c1f7e75b-3aba-4bba-a0b0-d3fbe8cf7750 | Test-App-1.3.0.dmg         | dmg      | darwin   |
      | 61992b58-c283-4c56-95d7-d83ff52bc0f4 | Test-App-1.4.0-beta.1.dmg  | dmg      | darwin   |
      | 873c088e-8d32-4d5d-afd4-11a28c58b9bc | Test-App-1.4.0-beta.2.dmg  | dmg      | darwin   |
      | 4d2737af-0c5a-4c55-a31a-e8781261cbd5 | Test-App-1.4.0-beta.3.dmg  | dmg      | darwin   |
      | e8d06fe3-ac5f-44af-a88d-bebb2d322947 | Test-App-1.4.0.dmg         | dmg      | darwin   |
      | f761080b-92fe-423a-a8b6-68f91d55a08a | Test-App-1.5.0.dmg         | dmg      | darwin   |
      | 8d1eb3ce-fb23-41a9-b66c-6328b2fde235 | Test-App-1.6.0.dmg         | dmg      | darwin   |
      | f287e696-27cb-4d2b-978a-d6cca2d386c2 | Test-App-1624653614.dmg    | dmg      | darwin   |
      | da38f541-0f22-4340-a7b5-4f7c410ded88 | Test-App-1.7.0.dmg         | dmg      | darwin   |
      | 88d9bba0-726b-4695-aee2-28c86ff689c4 | Test-App-1624653627.dmg    | dmg      | darwin   |
      | 8147443c-fe47-4654-9935-80a29b490905 | Test-App-1624653693.dmg    | dmg      | darwin   |
      | 697107b8-01fb-4c05-9c95-0399e2fab5f7 | Test-App-1624653702.dmg    | dmg      | darwin   |
      | 1849d528-e552-4def-91cb-4020a9ec995e | Test-App-1624653708.dmg    | dmg      | darwin   |
      | 46da3538-89d1-4bcf-a478-25109a40eae5 | Test-App-1624653716.dmg    | dmg      | darwin   |
      | 01947f94-f574-4b71-aa4f-7a5b9101a092 | Test-App-2.0.0-alpha.1.dmg | dmg      | darwin   |
      | 5f187a7d-8ab8-4a9c-85f6-9bc0331f09b4 | Test-App-2.0.0-alpha.2.dmg | dmg      | darwin   |
      | 04fc4e72-beaa-4a6f-92d7-168a0c4e924c | Test-App-2.0.0-beta.1.dmg  | dmg      | darwin   |
      | c2b11198-de3d-4c7c-8dd8-e3fe86650e6b | Test-App-2.0.0-beta.2.dmg  | dmg      | darwin   |
      | 14496b66-0004-422f-87e9-15172287bae4 | Test-App-2.0.0-beta.3.dmg  | dmg      | darwin   |
      | 7da7b744-1c60-441f-967d-68134c93c2d9 | Test-App-2.0.0-rc.1.dmg    | dmg      | darwin   |
      | 84fe5dbf-6e41-458e-821b-d716487fbd12 | Test-App-2.0.0.dmg         | dmg      | darwin   |
      | 33046ea9-2a77-46c3-b650-7b3b4bbae016 | Test-App-1624653735.dmg    | dmg      | darwin   |
      | aa067117-948f-46e8-977f-6998ad366a97 | Test-App-1624653760.dmg    | dmg      | darwin   |
      | fffa0764-3a19-48ea-beb3-8950563c7357 | Test-App-2.0.1-rc.1.dmg    | dmg      | darwin   |
      | 165d5389-e535-4f36-9232-ed59c67375d1 | Test-App-2.0.1.dmg         | dmg      | darwin   |
      | e4fa628e-593d-48bc-8e3e-5e4dda1f2c3a | Test-App-1624653771.dmg    | dmg      | darwin   |
      | fd10ab0c-c52a-412f-b34f-180eebd7325d | Test-App-2.0.2-alpha.1.dmg | dmg      | darwin   |
      | f98d8c17-5fad-4361-ad89-43b0c6f6fa00 | Test-App-2.0.2-beta.1.dmg  | dmg      | darwin   |
      | 077ca1f2-6125-4a77-bdf0-3161a0fc278e | Test-App-2.0.3-alpha.1.dmg | dmg      | darwin   |
      | 0a027f00-0860-4fa7-bd37-5900c8866818 | Test-App-1624654615.dmg    | dmg      | darwin   |
    And the current account has 1 "policy" for the first "product"
    And the current account has 1 "license" for the first "policy"
    And I am a license of account "test1"
    And I use an authentication token
    And I use API version "1.0"
    When I send a GET request to "/accounts/test1/releases/actions/upgrade?version=1.6.0&channel=stable&platform=darwin&filetype=dmg&product=6198261a-48b5-4445-a045-9fed4afc7735"
    Then the response status should be "303"
    And the response body should be an "artifact"
    And the response body should contain meta which includes the following:
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
      | id                                   | product_id                           | version                    | channel |
      | f53f57cb-dc3f-4b18-9d90-534038214b49 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0-alpha.1              | alpha   |
      | 80e20324-c578-4763-bbef-c9698bf0023a | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0                      | stable  |
      | d34846b1-fdfe-46aa-9194-7d1a08e2d0cb | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.1                      | stable  |
      | f517903b-5126-4405-9793-bf95a287b1f9 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.2                      | stable  |
      | 21088509-2dfc-4459-a8a2-3204136ad1df | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.3                      | stable  |
      | 0fd7f4a3-dd48-40bc-8f1c-d4449432f8fb | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.0                      | stable  |
      | eb4d5801-5238-4825-9236-50769fce5d2f | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.1                      | stable  |
      | 298eac03-7caf-4225-8554-181920d70d75 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.2                      | stable  |
      | 4e41ac33-79ea-4dc3-b179-87d0174aaed4 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.2.0                      | stable  |
      | c1f7e75b-3aba-4bba-a0b0-d3fbe8cf7750 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.3.0                      | stable  |
      | 61992b58-c283-4c56-95d7-d83ff52bc0f4 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.4.0-beta.1               | beta    |
      | 873c088e-8d32-4d5d-afd4-11a28c58b9bc | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.4.0-beta.2               | beta    |
      | 4d2737af-0c5a-4c55-a31a-e8781261cbd5 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.4.0-beta.3               | beta    |
      | e8d06fe3-ac5f-44af-a88d-bebb2d322947 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.4.0                      | stable  |
      | f761080b-92fe-423a-a8b6-68f91d55a08a | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.5.0                      | stable  |
      | 8d1eb3ce-fb23-41a9-b66c-6328b2fde235 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.6.0                      | stable  |
      | f287e696-27cb-4d2b-978a-d6cca2d386c2 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.7.0-dev+build.1624653614 | dev     |
      | da38f541-0f22-4340-a7b5-4f7c410ded88 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.7.0                      | stable  |
      | 88d9bba0-726b-4695-aee2-28c86ff689c4 | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0-dev+build.1624653627 | dev     |
      | 8147443c-fe47-4654-9935-80a29b490905 | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0-dev+build.1624653693 | dev     |
      | 697107b8-01fb-4c05-9c95-0399e2fab5f7 | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0-dev+build.1624653702 | dev     |
      | 1849d528-e552-4def-91cb-4020a9ec995e | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0-dev+build.1624653708 | dev     |
      | 46da3538-89d1-4bcf-a478-25109a40eae5 | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0-dev+build.1624653716 | dev     |
      | 01947f94-f574-4b71-aa4f-7a5b9101a092 | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0-alpha.1              | alpha   |
      | 5f187a7d-8ab8-4a9c-85f6-9bc0331f09b4 | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0-alpha.2              | alpha   |
      | 04fc4e72-beaa-4a6f-92d7-168a0c4e924c | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0-beta.1               | beta    |
      | c2b11198-de3d-4c7c-8dd8-e3fe86650e6b | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0-beta.2               | beta    |
      | 14496b66-0004-422f-87e9-15172287bae4 | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0-beta.3               | beta    |
      | 7da7b744-1c60-441f-967d-68134c93c2d9 | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0-rc.1                 | rc      |
      | 84fe5dbf-6e41-458e-821b-d716487fbd12 | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0                      | stable  |
      | 33046ea9-2a77-46c3-b650-7b3b4bbae016 | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.1-dev+build.1624653735 | dev     |
      | aa067117-948f-46e8-977f-6998ad366a97 | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.1-dev+build.1624653760 | dev     |
      | fffa0764-3a19-48ea-beb3-8950563c7357 | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.1-rc.1                 | rc      |
      | 165d5389-e535-4f36-9232-ed59c67375d1 | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.1                      | stable  |
      | e4fa628e-593d-48bc-8e3e-5e4dda1f2c3a | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.2-dev+build.1624653771 | dev     |
      | fd10ab0c-c52a-412f-b34f-180eebd7325d | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.2-alpha.1              | alpha   |
      | f98d8c17-5fad-4361-ad89-43b0c6f6fa00 | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.2-beta.1               | beta    |
      | 077ca1f2-6125-4a77-bdf0-3161a0fc278e | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.3-alpha.1              | alpha   |
      | 0a027f00-0860-4fa7-bd37-5900c8866818 | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.1.0-dev+build.1624654615 | dev     |
    And the current account has the following "artifact" rows:
      | release_id                           | filename                   | filetype | platform |
      | f53f57cb-dc3f-4b18-9d90-534038214b49 | Test-App-1.0.0-alpha.1.dmg | dmg      | darwin   |
      | 80e20324-c578-4763-bbef-c9698bf0023a | Test-App-1.0.0.dmg         | dmg      | darwin   |
      | d34846b1-fdfe-46aa-9194-7d1a08e2d0cb | Test-App-1.0.1.dmg         | dmg      | darwin   |
      | f517903b-5126-4405-9793-bf95a287b1f9 | Test-App-1.0.2.dmg         | dmg      | darwin   |
      | 21088509-2dfc-4459-a8a2-3204136ad1df | Test-App-1.0.3.dmg         | dmg      | darwin   |
      | 0fd7f4a3-dd48-40bc-8f1c-d4449432f8fb | Test-App-1.1.0.dmg         | dmg      | darwin   |
      | eb4d5801-5238-4825-9236-50769fce5d2f | Test-App-1.1.1.dmg         | dmg      | darwin   |
      | 298eac03-7caf-4225-8554-181920d70d75 | Test-App-1.1.2.dmg         | dmg      | darwin   |
      | 4e41ac33-79ea-4dc3-b179-87d0174aaed4 | Test-App-1.2.0.dmg         | dmg      | darwin   |
      | c1f7e75b-3aba-4bba-a0b0-d3fbe8cf7750 | Test-App-1.3.0.dmg         | dmg      | darwin   |
      | 61992b58-c283-4c56-95d7-d83ff52bc0f4 | Test-App-1.4.0-beta.1.dmg  | dmg      | darwin   |
      | 873c088e-8d32-4d5d-afd4-11a28c58b9bc | Test-App-1.4.0-beta.2.dmg  | dmg      | darwin   |
      | 4d2737af-0c5a-4c55-a31a-e8781261cbd5 | Test-App-1.4.0-beta.3.dmg  | dmg      | darwin   |
      | e8d06fe3-ac5f-44af-a88d-bebb2d322947 | Test-App-1.4.0.dmg         | dmg      | darwin   |
      | f761080b-92fe-423a-a8b6-68f91d55a08a | Test-App-1.5.0.dmg         | dmg      | darwin   |
      | 8d1eb3ce-fb23-41a9-b66c-6328b2fde235 | Test-App-1.6.0.dmg         | dmg      | darwin   |
      | f287e696-27cb-4d2b-978a-d6cca2d386c2 | Test-App-1624653614.dmg    | dmg      | darwin   |
      | da38f541-0f22-4340-a7b5-4f7c410ded88 | Test-App-1.7.0.dmg         | dmg      | darwin   |
      | 88d9bba0-726b-4695-aee2-28c86ff689c4 | Test-App-1624653627.dmg    | dmg      | darwin   |
      | 8147443c-fe47-4654-9935-80a29b490905 | Test-App-1624653693.dmg    | dmg      | darwin   |
      | 697107b8-01fb-4c05-9c95-0399e2fab5f7 | Test-App-1624653702.dmg    | dmg      | darwin   |
      | 1849d528-e552-4def-91cb-4020a9ec995e | Test-App-1624653708.dmg    | dmg      | darwin   |
      | 46da3538-89d1-4bcf-a478-25109a40eae5 | Test-App-1624653716.dmg    | dmg      | darwin   |
      | 01947f94-f574-4b71-aa4f-7a5b9101a092 | Test-App-2.0.0-alpha.1.dmg | dmg      | darwin   |
      | 5f187a7d-8ab8-4a9c-85f6-9bc0331f09b4 | Test-App-2.0.0-alpha.2.dmg | dmg      | darwin   |
      | 04fc4e72-beaa-4a6f-92d7-168a0c4e924c | Test-App-2.0.0-beta.1.dmg  | dmg      | darwin   |
      | c2b11198-de3d-4c7c-8dd8-e3fe86650e6b | Test-App-2.0.0-beta.2.dmg  | dmg      | darwin   |
      | 14496b66-0004-422f-87e9-15172287bae4 | Test-App-2.0.0-beta.3.dmg  | dmg      | darwin   |
      | 7da7b744-1c60-441f-967d-68134c93c2d9 | Test-App-2.0.0-rc.1.dmg    | dmg      | darwin   |
      | 84fe5dbf-6e41-458e-821b-d716487fbd12 | Test-App-2.0.0.dmg         | dmg      | darwin   |
      | 33046ea9-2a77-46c3-b650-7b3b4bbae016 | Test-App-1624653735.dmg    | dmg      | darwin   |
      | aa067117-948f-46e8-977f-6998ad366a97 | Test-App-1624653760.dmg    | dmg      | darwin   |
      | fffa0764-3a19-48ea-beb3-8950563c7357 | Test-App-2.0.1-rc.1.dmg    | dmg      | darwin   |
      | 165d5389-e535-4f36-9232-ed59c67375d1 | Test-App-2.0.1.dmg         | dmg      | darwin   |
      | e4fa628e-593d-48bc-8e3e-5e4dda1f2c3a | Test-App-1624653771.dmg    | dmg      | darwin   |
      | fd10ab0c-c52a-412f-b34f-180eebd7325d | Test-App-2.0.2-alpha.1.dmg | dmg      | darwin   |
      | f98d8c17-5fad-4361-ad89-43b0c6f6fa00 | Test-App-2.0.2-beta.1.dmg  | dmg      | darwin   |
      | 077ca1f2-6125-4a77-bdf0-3161a0fc278e | Test-App-2.0.3-alpha.1.dmg | dmg      | darwin   |
      | 0a027f00-0860-4fa7-bd37-5900c8866818 | Test-App-1624654615.dmg    | dmg      | darwin   |
    And the current account has 1 "policy" for the first "product"
    And the current account has 1 "license" for the first "policy"
    And I am a license of account "test1"
    And I use an authentication token
    And I use API version "1.0"
    When I send a GET request to "/accounts/test1/releases/actions/upgrade?version=1.0.0-dev%2bbuild.0&channel=rc&platform=darwin&filetype=dmg&product=6198261a-48b5-4445-a045-9fed4afc7735"
    Then the response status should be "303"
    And the response body should be an "artifact"
    And the response body should contain meta which includes the following:
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
      | id                                   | product_id                           | version                    | channel |
      | f53f57cb-dc3f-4b18-9d90-534038214b49 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0-alpha.1              | alpha   |
      | 80e20324-c578-4763-bbef-c9698bf0023a | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0                      | stable  |
      | d34846b1-fdfe-46aa-9194-7d1a08e2d0cb | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.1                      | stable  |
      | f517903b-5126-4405-9793-bf95a287b1f9 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.2                      | stable  |
      | 21088509-2dfc-4459-a8a2-3204136ad1df | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.3                      | stable  |
      | 0fd7f4a3-dd48-40bc-8f1c-d4449432f8fb | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.0                      | stable  |
      | eb4d5801-5238-4825-9236-50769fce5d2f | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.1                      | stable  |
      | 298eac03-7caf-4225-8554-181920d70d75 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.2                      | stable  |
      | 4e41ac33-79ea-4dc3-b179-87d0174aaed4 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.2.0                      | stable  |
      | c1f7e75b-3aba-4bba-a0b0-d3fbe8cf7750 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.3.0                      | stable  |
      | 61992b58-c283-4c56-95d7-d83ff52bc0f4 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.4.0-beta.1               | beta    |
      | 873c088e-8d32-4d5d-afd4-11a28c58b9bc | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.4.0-beta.2               | beta    |
      | 4d2737af-0c5a-4c55-a31a-e8781261cbd5 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.4.0-beta.3               | beta    |
      | e8d06fe3-ac5f-44af-a88d-bebb2d322947 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.4.0                      | stable  |
      | f761080b-92fe-423a-a8b6-68f91d55a08a | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.5.0                      | stable  |
      | 8d1eb3ce-fb23-41a9-b66c-6328b2fde235 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.6.0                      | stable  |
      | f287e696-27cb-4d2b-978a-d6cca2d386c2 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.7.0-dev+build.1624653614 | dev     |
      | da38f541-0f22-4340-a7b5-4f7c410ded88 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.7.0                      | stable  |
      | 88d9bba0-726b-4695-aee2-28c86ff689c4 | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0-dev+build.1624653627 | dev     |
      | 8147443c-fe47-4654-9935-80a29b490905 | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0-dev+build.1624653693 | dev     |
      | 697107b8-01fb-4c05-9c95-0399e2fab5f7 | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0-dev+build.1624653702 | dev     |
      | 1849d528-e552-4def-91cb-4020a9ec995e | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0-dev+build.1624653708 | dev     |
      | 46da3538-89d1-4bcf-a478-25109a40eae5 | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0-dev+build.1624653716 | dev     |
      | 01947f94-f574-4b71-aa4f-7a5b9101a092 | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0-alpha.1              | alpha   |
      | 5f187a7d-8ab8-4a9c-85f6-9bc0331f09b4 | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0-alpha.2              | alpha   |
      | 04fc4e72-beaa-4a6f-92d7-168a0c4e924c | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0-beta.1               | beta    |
      | c2b11198-de3d-4c7c-8dd8-e3fe86650e6b | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0-beta.2               | beta    |
      | 14496b66-0004-422f-87e9-15172287bae4 | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0-beta.3               | beta    |
      | 7da7b744-1c60-441f-967d-68134c93c2d9 | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0-rc.1                 | rc      |
      | 84fe5dbf-6e41-458e-821b-d716487fbd12 | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0                      | stable  |
      | 33046ea9-2a77-46c3-b650-7b3b4bbae016 | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.1-dev+build.1624653735 | dev     |
      | aa067117-948f-46e8-977f-6998ad366a97 | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.1-dev+build.1624653760 | dev     |
      | fffa0764-3a19-48ea-beb3-8950563c7357 | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.1-rc.1                 | rc      |
      | 165d5389-e535-4f36-9232-ed59c67375d1 | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.1                      | stable  |
      | e4fa628e-593d-48bc-8e3e-5e4dda1f2c3a | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.2-dev+build.1624653771 | dev     |
      | fd10ab0c-c52a-412f-b34f-180eebd7325d | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.2-alpha.1              | alpha   |
      | f98d8c17-5fad-4361-ad89-43b0c6f6fa00 | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.2-beta.1               | beta    |
      | 077ca1f2-6125-4a77-bdf0-3161a0fc278e | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.3-alpha.1              | alpha   |
      | 0a027f00-0860-4fa7-bd37-5900c8866818 | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.1.0-dev+build.1624654615 | dev     |
    And the current account has the following "artifact" rows:
      | release_id                           | filename                   | filetype | platform |
      | f53f57cb-dc3f-4b18-9d90-534038214b49 | Test-App-1.0.0-alpha.1.dmg | dmg      | darwin   |
      | 80e20324-c578-4763-bbef-c9698bf0023a | Test-App-1.0.0.dmg         | dmg      | darwin   |
      | d34846b1-fdfe-46aa-9194-7d1a08e2d0cb | Test-App-1.0.1.dmg         | dmg      | darwin   |
      | f517903b-5126-4405-9793-bf95a287b1f9 | Test-App-1.0.2.dmg         | dmg      | darwin   |
      | 21088509-2dfc-4459-a8a2-3204136ad1df | Test-App-1.0.3.dmg         | dmg      | darwin   |
      | 0fd7f4a3-dd48-40bc-8f1c-d4449432f8fb | Test-App-1.1.0.dmg         | dmg      | darwin   |
      | eb4d5801-5238-4825-9236-50769fce5d2f | Test-App-1.1.1.dmg         | dmg      | darwin   |
      | 298eac03-7caf-4225-8554-181920d70d75 | Test-App-1.1.2.dmg         | dmg      | darwin   |
      | 4e41ac33-79ea-4dc3-b179-87d0174aaed4 | Test-App-1.2.0.dmg         | dmg      | darwin   |
      | c1f7e75b-3aba-4bba-a0b0-d3fbe8cf7750 | Test-App-1.3.0.dmg         | dmg      | darwin   |
      | 61992b58-c283-4c56-95d7-d83ff52bc0f4 | Test-App-1.4.0-beta.1.dmg  | dmg      | darwin   |
      | 873c088e-8d32-4d5d-afd4-11a28c58b9bc | Test-App-1.4.0-beta.2.dmg  | dmg      | darwin   |
      | 4d2737af-0c5a-4c55-a31a-e8781261cbd5 | Test-App-1.4.0-beta.3.dmg  | dmg      | darwin   |
      | e8d06fe3-ac5f-44af-a88d-bebb2d322947 | Test-App-1.4.0.dmg         | dmg      | darwin   |
      | f761080b-92fe-423a-a8b6-68f91d55a08a | Test-App-1.5.0.dmg         | dmg      | darwin   |
      | 8d1eb3ce-fb23-41a9-b66c-6328b2fde235 | Test-App-1.6.0.dmg         | dmg      | darwin   |
      | f287e696-27cb-4d2b-978a-d6cca2d386c2 | Test-App-1624653614.dmg    | dmg      | darwin   |
      | da38f541-0f22-4340-a7b5-4f7c410ded88 | Test-App-1.7.0.dmg         | dmg      | darwin   |
      | 88d9bba0-726b-4695-aee2-28c86ff689c4 | Test-App-1624653627.dmg    | dmg      | darwin   |
      | 8147443c-fe47-4654-9935-80a29b490905 | Test-App-1624653693.dmg    | dmg      | darwin   |
      | 697107b8-01fb-4c05-9c95-0399e2fab5f7 | Test-App-1624653702.dmg    | dmg      | darwin   |
      | 1849d528-e552-4def-91cb-4020a9ec995e | Test-App-1624653708.dmg    | dmg      | darwin   |
      | 46da3538-89d1-4bcf-a478-25109a40eae5 | Test-App-1624653716.dmg    | dmg      | darwin   |
      | 01947f94-f574-4b71-aa4f-7a5b9101a092 | Test-App-2.0.0-alpha.1.dmg | dmg      | darwin   |
      | 5f187a7d-8ab8-4a9c-85f6-9bc0331f09b4 | Test-App-2.0.0-alpha.2.dmg | dmg      | darwin   |
      | 04fc4e72-beaa-4a6f-92d7-168a0c4e924c | Test-App-2.0.0-beta.1.dmg  | dmg      | darwin   |
      | c2b11198-de3d-4c7c-8dd8-e3fe86650e6b | Test-App-2.0.0-beta.2.dmg  | dmg      | darwin   |
      | 14496b66-0004-422f-87e9-15172287bae4 | Test-App-2.0.0-beta.3.dmg  | dmg      | darwin   |
      | 7da7b744-1c60-441f-967d-68134c93c2d9 | Test-App-2.0.0-rc.1.dmg    | dmg      | darwin   |
      | 84fe5dbf-6e41-458e-821b-d716487fbd12 | Test-App-2.0.0.dmg         | dmg      | darwin   |
      | 33046ea9-2a77-46c3-b650-7b3b4bbae016 | Test-App-1624653735.dmg    | dmg      | darwin   |
      | aa067117-948f-46e8-977f-6998ad366a97 | Test-App-1624653760.dmg    | dmg      | darwin   |
      | fffa0764-3a19-48ea-beb3-8950563c7357 | Test-App-2.0.1-rc.1.dmg    | dmg      | darwin   |
      | 165d5389-e535-4f36-9232-ed59c67375d1 | Test-App-2.0.1.dmg         | dmg      | darwin   |
      | e4fa628e-593d-48bc-8e3e-5e4dda1f2c3a | Test-App-1624653771.dmg    | dmg      | darwin   |
      | fd10ab0c-c52a-412f-b34f-180eebd7325d | Test-App-2.0.2-alpha.1.dmg | dmg      | darwin   |
      | f98d8c17-5fad-4361-ad89-43b0c6f6fa00 | Test-App-2.0.2-beta.1.dmg  | dmg      | darwin   |
      | 077ca1f2-6125-4a77-bdf0-3161a0fc278e | Test-App-2.0.3-alpha.1.dmg | dmg      | darwin   |
      | 0a027f00-0860-4fa7-bd37-5900c8866818 | Test-App-1624654615.dmg    | dmg      | darwin   |
    And the current account has 1 "policy" for the first "product"
    And the current account has 1 "license" for the first "policy"
    And I am a license of account "test1"
    And I use an authentication token
    And I use API version "1.0"
    When I send a GET request to "/accounts/test1/releases/actions/upgrade?version=2.0.0&channel=beta&platform=darwin&filetype=dmg&product=6198261a-48b5-4445-a045-9fed4afc7735"
    Then the response status should be "303"
    And the response body should be an "artifact"
    And the response body should contain meta which includes the following:
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
      | id                                   | product_id                           | version                    | channel |
      | f53f57cb-dc3f-4b18-9d90-534038214b49 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0-alpha.1              | alpha   |
      | 80e20324-c578-4763-bbef-c9698bf0023a | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0                      | stable  |
      | d34846b1-fdfe-46aa-9194-7d1a08e2d0cb | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.1                      | stable  |
      | f517903b-5126-4405-9793-bf95a287b1f9 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.2                      | stable  |
      | 21088509-2dfc-4459-a8a2-3204136ad1df | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.3                      | stable  |
      | 0fd7f4a3-dd48-40bc-8f1c-d4449432f8fb | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.0                      | stable  |
      | eb4d5801-5238-4825-9236-50769fce5d2f | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.1                      | stable  |
      | 298eac03-7caf-4225-8554-181920d70d75 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.2                      | stable  |
      | 4e41ac33-79ea-4dc3-b179-87d0174aaed4 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.2.0                      | stable  |
      | c1f7e75b-3aba-4bba-a0b0-d3fbe8cf7750 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.3.0                      | stable  |
      | 61992b58-c283-4c56-95d7-d83ff52bc0f4 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.4.0-beta.1               | beta    |
      | 873c088e-8d32-4d5d-afd4-11a28c58b9bc | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.4.0-beta.2               | beta    |
      | 4d2737af-0c5a-4c55-a31a-e8781261cbd5 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.4.0-beta.3               | beta    |
      | e8d06fe3-ac5f-44af-a88d-bebb2d322947 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.4.0                      | stable  |
      | f761080b-92fe-423a-a8b6-68f91d55a08a | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.5.0                      | stable  |
      | 8d1eb3ce-fb23-41a9-b66c-6328b2fde235 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.6.0                      | stable  |
      | f287e696-27cb-4d2b-978a-d6cca2d386c2 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.7.0-dev+build.1624653614 | dev     |
      | da38f541-0f22-4340-a7b5-4f7c410ded88 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.7.0                      | stable  |
      | 88d9bba0-726b-4695-aee2-28c86ff689c4 | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0-dev+build.1624653627 | dev     |
      | 8147443c-fe47-4654-9935-80a29b490905 | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0-dev+build.1624653693 | dev     |
      | 697107b8-01fb-4c05-9c95-0399e2fab5f7 | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0-dev+build.1624653702 | dev     |
      | 1849d528-e552-4def-91cb-4020a9ec995e | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0-dev+build.1624653708 | dev     |
      | 46da3538-89d1-4bcf-a478-25109a40eae5 | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0-dev+build.1624653716 | dev     |
      | 01947f94-f574-4b71-aa4f-7a5b9101a092 | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0-alpha.1              | alpha   |
      | 5f187a7d-8ab8-4a9c-85f6-9bc0331f09b4 | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0-alpha.2              | alpha   |
      | 04fc4e72-beaa-4a6f-92d7-168a0c4e924c | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0-beta.1               | beta    |
      | c2b11198-de3d-4c7c-8dd8-e3fe86650e6b | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0-beta.2               | beta    |
      | 14496b66-0004-422f-87e9-15172287bae4 | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0-beta.3               | beta    |
      | 7da7b744-1c60-441f-967d-68134c93c2d9 | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0-rc.1                 | rc      |
      | 84fe5dbf-6e41-458e-821b-d716487fbd12 | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0                      | stable  |
      | 33046ea9-2a77-46c3-b650-7b3b4bbae016 | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.1-dev+build.1624653735 | dev     |
      | aa067117-948f-46e8-977f-6998ad366a97 | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.1-dev+build.1624653760 | dev     |
      | fffa0764-3a19-48ea-beb3-8950563c7357 | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.1-rc.1                 | rc      |
      | 165d5389-e535-4f36-9232-ed59c67375d1 | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.1                      | stable  |
      | e4fa628e-593d-48bc-8e3e-5e4dda1f2c3a | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.2-dev+build.1624653771 | dev     |
      | fd10ab0c-c52a-412f-b34f-180eebd7325d | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.2-alpha.1              | alpha   |
      | f98d8c17-5fad-4361-ad89-43b0c6f6fa00 | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.2-beta.1               | beta    |
      | 077ca1f2-6125-4a77-bdf0-3161a0fc278e | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.3-alpha.1              | alpha   |
      | 0a027f00-0860-4fa7-bd37-5900c8866818 | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.1.0-dev+build.1624654615 | dev     |
    And the current account has the following "artifact" rows:
      | release_id                           | filename                   | filetype | platform |
      | f53f57cb-dc3f-4b18-9d90-534038214b49 | Test-App-1.0.0-alpha.1.dmg | dmg      | darwin   |
      | 80e20324-c578-4763-bbef-c9698bf0023a | Test-App-1.0.0.dmg         | dmg      | darwin   |
      | d34846b1-fdfe-46aa-9194-7d1a08e2d0cb | Test-App-1.0.1.dmg         | dmg      | darwin   |
      | f517903b-5126-4405-9793-bf95a287b1f9 | Test-App-1.0.2.dmg         | dmg      | darwin   |
      | 21088509-2dfc-4459-a8a2-3204136ad1df | Test-App-1.0.3.dmg         | dmg      | darwin   |
      | 0fd7f4a3-dd48-40bc-8f1c-d4449432f8fb | Test-App-1.1.0.dmg         | dmg      | darwin   |
      | eb4d5801-5238-4825-9236-50769fce5d2f | Test-App-1.1.1.dmg         | dmg      | darwin   |
      | 298eac03-7caf-4225-8554-181920d70d75 | Test-App-1.1.2.dmg         | dmg      | darwin   |
      | 4e41ac33-79ea-4dc3-b179-87d0174aaed4 | Test-App-1.2.0.dmg         | dmg      | darwin   |
      | c1f7e75b-3aba-4bba-a0b0-d3fbe8cf7750 | Test-App-1.3.0.dmg         | dmg      | darwin   |
      | 61992b58-c283-4c56-95d7-d83ff52bc0f4 | Test-App-1.4.0-beta.1.dmg  | dmg      | darwin   |
      | 873c088e-8d32-4d5d-afd4-11a28c58b9bc | Test-App-1.4.0-beta.2.dmg  | dmg      | darwin   |
      | 4d2737af-0c5a-4c55-a31a-e8781261cbd5 | Test-App-1.4.0-beta.3.dmg  | dmg      | darwin   |
      | e8d06fe3-ac5f-44af-a88d-bebb2d322947 | Test-App-1.4.0.dmg         | dmg      | darwin   |
      | f761080b-92fe-423a-a8b6-68f91d55a08a | Test-App-1.5.0.dmg         | dmg      | darwin   |
      | 8d1eb3ce-fb23-41a9-b66c-6328b2fde235 | Test-App-1.6.0.dmg         | dmg      | darwin   |
      | f287e696-27cb-4d2b-978a-d6cca2d386c2 | Test-App-1624653614.dmg    | dmg      | darwin   |
      | da38f541-0f22-4340-a7b5-4f7c410ded88 | Test-App-1.7.0.dmg         | dmg      | darwin   |
      | 88d9bba0-726b-4695-aee2-28c86ff689c4 | Test-App-1624653627.dmg    | dmg      | darwin   |
      | 8147443c-fe47-4654-9935-80a29b490905 | Test-App-1624653693.dmg    | dmg      | darwin   |
      | 697107b8-01fb-4c05-9c95-0399e2fab5f7 | Test-App-1624653702.dmg    | dmg      | darwin   |
      | 1849d528-e552-4def-91cb-4020a9ec995e | Test-App-1624653708.dmg    | dmg      | darwin   |
      | 46da3538-89d1-4bcf-a478-25109a40eae5 | Test-App-1624653716.dmg    | dmg      | darwin   |
      | 01947f94-f574-4b71-aa4f-7a5b9101a092 | Test-App-2.0.0-alpha.1.dmg | dmg      | darwin   |
      | 5f187a7d-8ab8-4a9c-85f6-9bc0331f09b4 | Test-App-2.0.0-alpha.2.dmg | dmg      | darwin   |
      | 04fc4e72-beaa-4a6f-92d7-168a0c4e924c | Test-App-2.0.0-beta.1.dmg  | dmg      | darwin   |
      | c2b11198-de3d-4c7c-8dd8-e3fe86650e6b | Test-App-2.0.0-beta.2.dmg  | dmg      | darwin   |
      | 14496b66-0004-422f-87e9-15172287bae4 | Test-App-2.0.0-beta.3.dmg  | dmg      | darwin   |
      | 7da7b744-1c60-441f-967d-68134c93c2d9 | Test-App-2.0.0-rc.1.dmg    | dmg      | darwin   |
      | 84fe5dbf-6e41-458e-821b-d716487fbd12 | Test-App-2.0.0.dmg         | dmg      | darwin   |
      | 33046ea9-2a77-46c3-b650-7b3b4bbae016 | Test-App-1624653735.dmg    | dmg      | darwin   |
      | aa067117-948f-46e8-977f-6998ad366a97 | Test-App-1624653760.dmg    | dmg      | darwin   |
      | fffa0764-3a19-48ea-beb3-8950563c7357 | Test-App-2.0.1-rc.1.dmg    | dmg      | darwin   |
      | 165d5389-e535-4f36-9232-ed59c67375d1 | Test-App-2.0.1.dmg         | dmg      | darwin   |
      | e4fa628e-593d-48bc-8e3e-5e4dda1f2c3a | Test-App-1624653771.dmg    | dmg      | darwin   |
      | fd10ab0c-c52a-412f-b34f-180eebd7325d | Test-App-2.0.2-alpha.1.dmg | dmg      | darwin   |
      | f98d8c17-5fad-4361-ad89-43b0c6f6fa00 | Test-App-2.0.2-beta.1.dmg  | dmg      | darwin   |
      | 077ca1f2-6125-4a77-bdf0-3161a0fc278e | Test-App-2.0.3-alpha.1.dmg | dmg      | darwin   |
      | 0a027f00-0860-4fa7-bd37-5900c8866818 | Test-App-1624654615.dmg    | dmg      | darwin   |
    And the current account has 1 "policy" for the first "product"
    And the current account has 1 "license" for the first "policy"
    And I am a license of account "test1"
    And I use an authentication token
    And I use API version "1.0"
    When I send a GET request to "/accounts/test1/releases/actions/upgrade?version=1.0.0-alpha.1&channel=alpha&platform=darwin&filetype=dmg&product=6198261a-48b5-4445-a045-9fed4afc7735"
    Then the response status should be "303"
    And the response body should be an "artifact"
    And the response body should contain meta which includes the following:
      """
      {
        "current": "1.0.0-alpha.1",
        "next": "2.0.3-alpha.1"
      }
      """

  Scenario: License retrieves an upgrade for a product release (dev channel)
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name     |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test App |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | version                    | channel |
      | f53f57cb-dc3f-4b18-9d90-534038214b49 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0-alpha.1              | alpha   |
      | 80e20324-c578-4763-bbef-c9698bf0023a | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0                      | stable  |
      | d34846b1-fdfe-46aa-9194-7d1a08e2d0cb | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.1                      | stable  |
      | f517903b-5126-4405-9793-bf95a287b1f9 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.2                      | stable  |
      | 21088509-2dfc-4459-a8a2-3204136ad1df | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.3                      | stable  |
      | 0fd7f4a3-dd48-40bc-8f1c-d4449432f8fb | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.0                      | stable  |
      | eb4d5801-5238-4825-9236-50769fce5d2f | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.1                      | stable  |
      | 298eac03-7caf-4225-8554-181920d70d75 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.2                      | stable  |
      | 4e41ac33-79ea-4dc3-b179-87d0174aaed4 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.2.0                      | stable  |
      | c1f7e75b-3aba-4bba-a0b0-d3fbe8cf7750 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.3.0                      | stable  |
      | 61992b58-c283-4c56-95d7-d83ff52bc0f4 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.4.0-beta.1               | beta    |
      | 873c088e-8d32-4d5d-afd4-11a28c58b9bc | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.4.0-beta.2               | beta    |
      | 4d2737af-0c5a-4c55-a31a-e8781261cbd5 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.4.0-beta.3               | beta    |
      | e8d06fe3-ac5f-44af-a88d-bebb2d322947 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.4.0                      | stable  |
      | f761080b-92fe-423a-a8b6-68f91d55a08a | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.5.0                      | stable  |
      | 8d1eb3ce-fb23-41a9-b66c-6328b2fde235 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.6.0                      | stable  |
      | f287e696-27cb-4d2b-978a-d6cca2d386c2 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.7.0-dev+build.1624653614 | dev     |
      | da38f541-0f22-4340-a7b5-4f7c410ded88 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.7.0                      | stable  |
      | 88d9bba0-726b-4695-aee2-28c86ff689c4 | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0-dev+build.1624653627 | dev     |
      | 8147443c-fe47-4654-9935-80a29b490905 | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0-dev+build.1624653693 | dev     |
      | 697107b8-01fb-4c05-9c95-0399e2fab5f7 | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0-dev+build.1624653702 | dev     |
      | 1849d528-e552-4def-91cb-4020a9ec995e | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0-dev+build.1624653708 | dev     |
      | 46da3538-89d1-4bcf-a478-25109a40eae5 | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0-dev+build.1624653716 | dev     |
      | 01947f94-f574-4b71-aa4f-7a5b9101a092 | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0-alpha.1              | alpha   |
      | 5f187a7d-8ab8-4a9c-85f6-9bc0331f09b4 | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0-alpha.2              | alpha   |
      | 04fc4e72-beaa-4a6f-92d7-168a0c4e924c | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0-beta.1               | beta    |
      | c2b11198-de3d-4c7c-8dd8-e3fe86650e6b | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0-beta.2               | beta    |
      | 14496b66-0004-422f-87e9-15172287bae4 | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0-beta.3               | beta    |
      | 7da7b744-1c60-441f-967d-68134c93c2d9 | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0-rc.1                 | rc      |
      | 84fe5dbf-6e41-458e-821b-d716487fbd12 | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0                      | stable  |
      | 33046ea9-2a77-46c3-b650-7b3b4bbae016 | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.1-dev+build.1624653735 | dev     |
      | aa067117-948f-46e8-977f-6998ad366a97 | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.1-dev+build.1624653760 | dev     |
      | fffa0764-3a19-48ea-beb3-8950563c7357 | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.1-rc.1                 | rc      |
      | 165d5389-e535-4f36-9232-ed59c67375d1 | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.1                      | stable  |
      | e4fa628e-593d-48bc-8e3e-5e4dda1f2c3a | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.2-dev+build.1624653771 | dev     |
      | fd10ab0c-c52a-412f-b34f-180eebd7325d | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.2-alpha.1              | alpha   |
      | f98d8c17-5fad-4361-ad89-43b0c6f6fa00 | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.2-beta.1               | beta    |
      | 077ca1f2-6125-4a77-bdf0-3161a0fc278e | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.3-alpha.1              | alpha   |
      | 0a027f00-0860-4fa7-bd37-5900c8866818 | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.1.0-dev+build.1624654615 | dev     |
    And the current account has the following "artifact" rows:
      | release_id                           | filename                   | filetype | platform |
      | f53f57cb-dc3f-4b18-9d90-534038214b49 | Test-App-1.0.0-alpha.1.dmg | dmg      | darwin   |
      | 80e20324-c578-4763-bbef-c9698bf0023a | Test-App-1.0.0.dmg         | dmg      | darwin   |
      | d34846b1-fdfe-46aa-9194-7d1a08e2d0cb | Test-App-1.0.1.dmg         | dmg      | darwin   |
      | f517903b-5126-4405-9793-bf95a287b1f9 | Test-App-1.0.2.dmg         | dmg      | darwin   |
      | 21088509-2dfc-4459-a8a2-3204136ad1df | Test-App-1.0.3.dmg         | dmg      | darwin   |
      | 0fd7f4a3-dd48-40bc-8f1c-d4449432f8fb | Test-App-1.1.0.dmg         | dmg      | darwin   |
      | eb4d5801-5238-4825-9236-50769fce5d2f | Test-App-1.1.1.dmg         | dmg      | darwin   |
      | 298eac03-7caf-4225-8554-181920d70d75 | Test-App-1.1.2.dmg         | dmg      | darwin   |
      | 4e41ac33-79ea-4dc3-b179-87d0174aaed4 | Test-App-1.2.0.dmg         | dmg      | darwin   |
      | c1f7e75b-3aba-4bba-a0b0-d3fbe8cf7750 | Test-App-1.3.0.dmg         | dmg      | darwin   |
      | 61992b58-c283-4c56-95d7-d83ff52bc0f4 | Test-App-1.4.0-beta.1.dmg  | dmg      | darwin   |
      | 873c088e-8d32-4d5d-afd4-11a28c58b9bc | Test-App-1.4.0-beta.2.dmg  | dmg      | darwin   |
      | 4d2737af-0c5a-4c55-a31a-e8781261cbd5 | Test-App-1.4.0-beta.3.dmg  | dmg      | darwin   |
      | e8d06fe3-ac5f-44af-a88d-bebb2d322947 | Test-App-1.4.0.dmg         | dmg      | darwin   |
      | f761080b-92fe-423a-a8b6-68f91d55a08a | Test-App-1.5.0.dmg         | dmg      | darwin   |
      | 8d1eb3ce-fb23-41a9-b66c-6328b2fde235 | Test-App-1.6.0.dmg         | dmg      | darwin   |
      | f287e696-27cb-4d2b-978a-d6cca2d386c2 | Test-App-1624653614.dmg    | dmg      | darwin   |
      | da38f541-0f22-4340-a7b5-4f7c410ded88 | Test-App-1.7.0.dmg         | dmg      | darwin   |
      | 88d9bba0-726b-4695-aee2-28c86ff689c4 | Test-App-1624653627.dmg    | dmg      | darwin   |
      | 8147443c-fe47-4654-9935-80a29b490905 | Test-App-1624653693.dmg    | dmg      | darwin   |
      | 697107b8-01fb-4c05-9c95-0399e2fab5f7 | Test-App-1624653702.dmg    | dmg      | darwin   |
      | 1849d528-e552-4def-91cb-4020a9ec995e | Test-App-1624653708.dmg    | dmg      | darwin   |
      | 46da3538-89d1-4bcf-a478-25109a40eae5 | Test-App-1624653716.dmg    | dmg      | darwin   |
      | 01947f94-f574-4b71-aa4f-7a5b9101a092 | Test-App-2.0.0-alpha.1.dmg | dmg      | darwin   |
      | 5f187a7d-8ab8-4a9c-85f6-9bc0331f09b4 | Test-App-2.0.0-alpha.2.dmg | dmg      | darwin   |
      | 04fc4e72-beaa-4a6f-92d7-168a0c4e924c | Test-App-2.0.0-beta.1.dmg  | dmg      | darwin   |
      | c2b11198-de3d-4c7c-8dd8-e3fe86650e6b | Test-App-2.0.0-beta.2.dmg  | dmg      | darwin   |
      | 14496b66-0004-422f-87e9-15172287bae4 | Test-App-2.0.0-beta.3.dmg  | dmg      | darwin   |
      | 7da7b744-1c60-441f-967d-68134c93c2d9 | Test-App-2.0.0-rc.1.dmg    | dmg      | darwin   |
      | 84fe5dbf-6e41-458e-821b-d716487fbd12 | Test-App-2.0.0.dmg         | dmg      | darwin   |
      | 33046ea9-2a77-46c3-b650-7b3b4bbae016 | Test-App-1624653735.dmg    | dmg      | darwin   |
      | aa067117-948f-46e8-977f-6998ad366a97 | Test-App-1624653760.dmg    | dmg      | darwin   |
      | fffa0764-3a19-48ea-beb3-8950563c7357 | Test-App-2.0.1-rc.1.dmg    | dmg      | darwin   |
      | 165d5389-e535-4f36-9232-ed59c67375d1 | Test-App-2.0.1.dmg         | dmg      | darwin   |
      | e4fa628e-593d-48bc-8e3e-5e4dda1f2c3a | Test-App-1624653771.dmg    | dmg      | darwin   |
      | fd10ab0c-c52a-412f-b34f-180eebd7325d | Test-App-2.0.2-alpha.1.dmg | dmg      | darwin   |
      | f98d8c17-5fad-4361-ad89-43b0c6f6fa00 | Test-App-2.0.2-beta.1.dmg  | dmg      | darwin   |
      | 077ca1f2-6125-4a77-bdf0-3161a0fc278e | Test-App-2.0.3-alpha.1.dmg | dmg      | darwin   |
      | 0a027f00-0860-4fa7-bd37-5900c8866818 | Test-App-1624654615.dmg    | dmg      | darwin   |
    And the current account has 1 "policy" for the first "product"
    And the current account has 1 "license" for the first "policy"
    And I am a license of account "test1"
    And I use an authentication token
    And I use API version "1.0"
    When I send a GET request to "/accounts/test1/releases/actions/upgrade?version=1.7.0-dev%2bbuild.1624653614&channel=dev&platform=darwin&filetype=dmg&product=6198261a-48b5-4445-a045-9fed4afc7735"
    Then the response status should be "303"
    And the response body should be an "artifact"
    And the response body should contain meta which includes the following:
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
      | id                                   | name     | distribution_strategy |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test App | LICENSED              |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | version | channel |
      | f53f57cb-dc3f-4b18-9d90-534038214b49 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0   | stable  |
      | 80e20324-c578-4763-bbef-c9698bf0023a | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.1   | stable  |
      | d34846b1-fdfe-46aa-9194-7d1a08e2d0cb | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.2   | stable  |
      | f517903b-5126-4405-9793-bf95a287b1f9 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.3   | stable  |
      | 21088509-2dfc-4459-a8a2-3204136ad1df | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.0   | stable  |
    And the current account has the following "artifact" rows:
      | release_id                           | filename           | filetype | platform |
      | f53f57cb-dc3f-4b18-9d90-534038214b49 | Test-App-1.0.0.dmg | dmg      | darwin   |
      | 80e20324-c578-4763-bbef-c9698bf0023a | Test-App-1.0.1.dmg | dmg      | darwin   |
      | d34846b1-fdfe-46aa-9194-7d1a08e2d0cb | Test-App-1.0.2.dmg | dmg      | darwin   |
      | f517903b-5126-4405-9793-bf95a287b1f9 | Test-App-1.0.3.dmg | dmg      | darwin   |
      | 21088509-2dfc-4459-a8a2-3204136ad1df | Test-App-1.1.0.dmg | dmg      | darwin   |
    And the current account has 1 "policy" for the first "product"
    And the current account has 1 "license" for the first "policy"
    And I am a license of account "test1"
    And I use an authentication token
    And I use API version "1.0"
    When I send a GET request to "/accounts/test1/releases/actions/upgrade?version=1.0.2&channel=stable&platform=darwin&filetype=dmg&product=6198261a-48b5-4445-a045-9fed4afc7735"
    Then the response status should be "303"
    And the response body should be an "artifact"
    And the response body should contain meta which includes the following:
      """
      {
        "current": "1.0.2",
        "next": "1.1.0"
      }
      """

  Scenario: User retrieves an upgrade for a product release (LICENSED distribution strategy)
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name     | distribution_strategy |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test App | LICENSED              |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | version | channel |
      | f53f57cb-dc3f-4b18-9d90-534038214b49 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0   | stable  |
      | 80e20324-c578-4763-bbef-c9698bf0023a | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.1   | stable  |
      | d34846b1-fdfe-46aa-9194-7d1a08e2d0cb | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.2   | stable  |
      | f517903b-5126-4405-9793-bf95a287b1f9 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.3   | stable  |
      | 21088509-2dfc-4459-a8a2-3204136ad1df | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.0   | stable  |
    And the current account has the following "artifact" rows:
      | release_id                           | filename           | filetype | platform |
      | f53f57cb-dc3f-4b18-9d90-534038214b49 | Test-App-1.0.0.dmg | dmg      | darwin   |
      | 80e20324-c578-4763-bbef-c9698bf0023a | Test-App-1.0.1.dmg | dmg      | darwin   |
      | d34846b1-fdfe-46aa-9194-7d1a08e2d0cb | Test-App-1.0.2.dmg | dmg      | darwin   |
      | f517903b-5126-4405-9793-bf95a287b1f9 | Test-App-1.0.3.dmg | dmg      | darwin   |
      | 21088509-2dfc-4459-a8a2-3204136ad1df | Test-App-1.1.0.dmg | dmg      | darwin   |
    And the current account has 1 "policy" for an existing "product"
    And the current account has 1 "license" for an existing "policy"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    And I use API version "1.0"
    And the current user has 1 "license"
    When I send a GET request to "/accounts/test1/releases/actions/upgrade?version=1.0.2&channel=stable&platform=darwin&filetype=dmg&product=6198261a-48b5-4445-a045-9fed4afc7735"
    Then the response status should be "303"
    And the response body should be an "artifact"
    And the response body should contain meta which includes the following:
      """
      {
        "current": "1.0.2",
        "next": "1.1.0"
      }
      """

  Scenario: Anonymous retrieves an upgrade for a product release (LICENSED distribution strategy)
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name     | distribution_strategy |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test App | LICENSED              |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | version | channel |
      | f53f57cb-dc3f-4b18-9d90-534038214b49 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0   | stable  |
      | 80e20324-c578-4763-bbef-c9698bf0023a | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.1   | stable  |
      | d34846b1-fdfe-46aa-9194-7d1a08e2d0cb | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.2   | stable  |
      | f517903b-5126-4405-9793-bf95a287b1f9 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.3   | stable  |
      | 21088509-2dfc-4459-a8a2-3204136ad1df | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.0   | stable  |
    And the current account has the following "artifact" rows:
      | release_id                           | filename           | filetype | platform |
      | f53f57cb-dc3f-4b18-9d90-534038214b49 | Test-App-1.0.0.dmg | dmg      | darwin   |
      | 80e20324-c578-4763-bbef-c9698bf0023a | Test-App-1.0.1.dmg | dmg      | darwin   |
      | d34846b1-fdfe-46aa-9194-7d1a08e2d0cb | Test-App-1.0.2.dmg | dmg      | darwin   |
      | f517903b-5126-4405-9793-bf95a287b1f9 | Test-App-1.0.3.dmg | dmg      | darwin   |
      | 21088509-2dfc-4459-a8a2-3204136ad1df | Test-App-1.1.0.dmg | dmg      | darwin   |
    And I use API version "1.0"
    When I send a GET request to "/accounts/test1/releases/actions/upgrade?version=1.0.2&channel=stable&platform=darwin&filetype=dmg&product=6198261a-48b5-4445-a045-9fed4afc7735"
    Then the response status should be "204"

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
      | 21088509-2dfc-4459-a8a2-3204136ad1df | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.0   | stable  |
    And the current account has the following "artifact" rows:
      | release_id                           | filename           | filetype | platform |
      | f53f57cb-dc3f-4b18-9d90-534038214b49 | Test-App-1.0.0.dmg | dmg      | darwin   |
      | 80e20324-c578-4763-bbef-c9698bf0023a | Test-App-1.0.1.dmg | dmg      | darwin   |
      | d34846b1-fdfe-46aa-9194-7d1a08e2d0cb | Test-App-1.0.2.dmg | dmg      | darwin   |
      | f517903b-5126-4405-9793-bf95a287b1f9 | Test-App-1.0.3.dmg | dmg      | darwin   |
      | 21088509-2dfc-4459-a8a2-3204136ad1df | Test-App-1.1.0.dmg | dmg      | darwin   |
    And the current account has 1 "policy" for the first "product"
    And the current account has 1 "license" for the first "policy"
    And I am a license of account "test1"
    And I use an authentication token
    And I use API version "1.0"
    When I send a GET request to "/accounts/test1/releases/actions/upgrade?version=1.0.2&channel=stable&platform=darwin&filetype=dmg&product=6198261a-48b5-4445-a045-9fed4afc7735"
    Then the response status should be "303"
    And the response body should be an "artifact"
    And the response body should contain meta which includes the following:
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
      | id                                   | name     | distribution_strategy |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test App | OPEN                  |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | version | channel | entitlements |
      | f53f57cb-dc3f-4b18-9d90-534038214b49 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0   | stable  | TEST_ENTL    |
      | 80e20324-c578-4763-bbef-c9698bf0023a | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.1   | stable  | TEST_ENTL    |
      | d34846b1-fdfe-46aa-9194-7d1a08e2d0cb | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.2   | stable  | TEST_ENTL    |
      | f517903b-5126-4405-9793-bf95a287b1f9 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.3   | stable  | TEST_ENTL    |
      | 21088509-2dfc-4459-a8a2-3204136ad1df | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.0   | stable  | TEST_ENTL    |
    And the current account has the following "artifact" rows:
      | release_id                           | filename           | filetype | platform |
      | f53f57cb-dc3f-4b18-9d90-534038214b49 | Test-App-1.0.0.dmg | dmg      | darwin   |
      | 80e20324-c578-4763-bbef-c9698bf0023a | Test-App-1.0.1.dmg | dmg      | darwin   |
      | d34846b1-fdfe-46aa-9194-7d1a08e2d0cb | Test-App-1.0.2.dmg | dmg      | darwin   |
      | f517903b-5126-4405-9793-bf95a287b1f9 | Test-App-1.0.3.dmg | dmg      | darwin   |
      | 21088509-2dfc-4459-a8a2-3204136ad1df | Test-App-1.1.0.dmg | dmg      | darwin   |
    And the current account has 1 "policy" for the first "product"
    And the current account has 1 "license" for the first "policy"
    And I am a license of account "test1"
    And I use an authentication token
    And I use API version "1.0"
    When I send a GET request to "/accounts/test1/releases/actions/upgrade?version=1.0.2&channel=stable&platform=darwin&filetype=dmg&product=6198261a-48b5-4445-a045-9fed4afc7735"
    Then the response status should be "204"

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
      | 21088509-2dfc-4459-a8a2-3204136ad1df | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.0   | stable  | TEST_ENTL    |
    And the current account has the following "artifact" rows:
      | release_id                           | filename           | filetype | platform |
      | f53f57cb-dc3f-4b18-9d90-534038214b49 | Test-App-1.0.0.dmg | dmg      | darwin   |
      | 80e20324-c578-4763-bbef-c9698bf0023a | Test-App-1.0.1.dmg | dmg      | darwin   |
      | d34846b1-fdfe-46aa-9194-7d1a08e2d0cb | Test-App-1.0.2.dmg | dmg      | darwin   |
      | f517903b-5126-4405-9793-bf95a287b1f9 | Test-App-1.0.3.dmg | dmg      | darwin   |
      | 21088509-2dfc-4459-a8a2-3204136ad1df | Test-App-1.1.0.dmg | dmg      | darwin   |
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
    And I use API version "1.0"
    When I send a GET request to "/accounts/test1/releases/actions/upgrade?version=1.0.2&channel=stable&platform=darwin&filetype=dmg&product=6198261a-48b5-4445-a045-9fed4afc7735"
    Then the response status should be "303"
    And the response body should be an "artifact"
    And the response body should contain meta which includes the following:
      """
      {
        "current": "1.0.2",
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
      | 21088509-2dfc-4459-a8a2-3204136ad1df | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.0   | stable  |
    And the current account has the following "artifact" rows:
      | release_id                           | filename           | filetype | platform |
      | f53f57cb-dc3f-4b18-9d90-534038214b49 | Test-App-1.0.0.dmg | dmg      | darwin   |
      | 80e20324-c578-4763-bbef-c9698bf0023a | Test-App-1.0.1.dmg | dmg      | darwin   |
      | d34846b1-fdfe-46aa-9194-7d1a08e2d0cb | Test-App-1.0.2.dmg | dmg      | darwin   |
      | f517903b-5126-4405-9793-bf95a287b1f9 | Test-App-1.0.3.dmg | dmg      | darwin   |
      | 21088509-2dfc-4459-a8a2-3204136ad1df | Test-App-1.1.0.dmg | dmg      | darwin   |
    And the current account has 1 "policy" for an existing "product"
    And the current account has 1 "license" for an existing "policy"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    And I use API version "1.0"
    And the current user has 1 "license"
    When I send a GET request to "/accounts/test1/releases/actions/upgrade?version=1.0.2&channel=stable&platform=darwin&filetype=dmg&product=6198261a-48b5-4445-a045-9fed4afc7735"
    Then the response status should be "303"
    And the response body should be an "artifact"
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
      | 21088509-2dfc-4459-a8a2-3204136ad1df | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.0   | stable  |
    And the current account has the following "artifact" rows:
      | release_id                           | filename           | filetype | platform |
      | f53f57cb-dc3f-4b18-9d90-534038214b49 | Test-App-1.0.0.dmg | dmg      | darwin   |
      | 80e20324-c578-4763-bbef-c9698bf0023a | Test-App-1.0.1.dmg | dmg      | darwin   |
      | d34846b1-fdfe-46aa-9194-7d1a08e2d0cb | Test-App-1.0.2.dmg | dmg      | darwin   |
      | f517903b-5126-4405-9793-bf95a287b1f9 | Test-App-1.0.3.dmg | dmg      | darwin   |
      | 21088509-2dfc-4459-a8a2-3204136ad1df | Test-App-1.1.0.dmg | dmg      | darwin   |
    And I use API version "1.0"
    When I send a GET request to "/accounts/test1/releases/actions/upgrade?version=1.0.2&channel=stable&platform=darwin&filetype=dmg&product=6198261a-48b5-4445-a045-9fed4afc7735"
    Then the response status should be "303"
    And the response body should be an "artifact"
    And the response body should contain meta which includes the following:
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
      | id                                   | name     | distribution_strategy |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test App | CLOSED                |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | version | channel |
      | f53f57cb-dc3f-4b18-9d90-534038214b49 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0   | stable  |
      | 80e20324-c578-4763-bbef-c9698bf0023a | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.1   | stable  |
      | d34846b1-fdfe-46aa-9194-7d1a08e2d0cb | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.2   | stable  |
      | f517903b-5126-4405-9793-bf95a287b1f9 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.3   | stable  |
      | 21088509-2dfc-4459-a8a2-3204136ad1df | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.0   | stable  |
    And the current account has the following "artifact" rows:
      | release_id                           | filename           | filetype | platform |
      | f53f57cb-dc3f-4b18-9d90-534038214b49 | Test-App-1.0.0.dmg | dmg      | darwin   |
      | 80e20324-c578-4763-bbef-c9698bf0023a | Test-App-1.0.1.dmg | dmg      | darwin   |
      | d34846b1-fdfe-46aa-9194-7d1a08e2d0cb | Test-App-1.0.2.dmg | dmg      | darwin   |
      | f517903b-5126-4405-9793-bf95a287b1f9 | Test-App-1.0.3.dmg | dmg      | darwin   |
      | 21088509-2dfc-4459-a8a2-3204136ad1df | Test-App-1.1.0.dmg | dmg      | darwin   |
    And I use API version "1.0"
    When I send a GET request to "/accounts/test1/releases/actions/upgrade?version=1.0.2&channel=stable&platform=darwin&filetype=dmg&product=6198261a-48b5-4445-a045-9fed4afc7735"
    Then the response status should be "204"

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
      | 21088509-2dfc-4459-a8a2-3204136ad1df | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.0   | stable  |
    And the current account has the following "artifact" rows:
      | release_id                           | filename           | filetype | platform |
      | f53f57cb-dc3f-4b18-9d90-534038214b49 | Test-App-1.0.0.dmg | dmg      | darwin   |
      | 80e20324-c578-4763-bbef-c9698bf0023a | Test-App-1.0.1.dmg | dmg      | darwin   |
      | d34846b1-fdfe-46aa-9194-7d1a08e2d0cb | Test-App-1.0.2.dmg | dmg      | darwin   |
      | f517903b-5126-4405-9793-bf95a287b1f9 | Test-App-1.0.3.dmg | dmg      | darwin   |
      | 21088509-2dfc-4459-a8a2-3204136ad1df | Test-App-1.1.0.dmg | dmg      | darwin   |
    And the current account has 1 "policy" for the first "product"
    And the current account has 1 "license" for the first "policy"
    And I am a license of account "test1"
    And I use an authentication token
    And I use API version "1.0"
    When I send a GET request to "/accounts/test1/releases/actions/upgrade?version=1.0.2&channel=stable&platform=darwin&filetype=dmg&product=6198261a-48b5-4445-a045-9fed4afc7735"
    Then the response status should be "204"

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
      | 21088509-2dfc-4459-a8a2-3204136ad1df | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.0   | stable  |
    And the current account has the following "artifact" rows:
      | release_id                           | filename           | filetype | platform |
      | f53f57cb-dc3f-4b18-9d90-534038214b49 | Test-App-1.0.0.dmg | dmg      | darwin   |
      | 80e20324-c578-4763-bbef-c9698bf0023a | Test-App-1.0.1.dmg | dmg      | darwin   |
      | d34846b1-fdfe-46aa-9194-7d1a08e2d0cb | Test-App-1.0.2.dmg | dmg      | darwin   |
      | f517903b-5126-4405-9793-bf95a287b1f9 | Test-App-1.0.3.dmg | dmg      | darwin   |
      | 21088509-2dfc-4459-a8a2-3204136ad1df | Test-App-1.1.0.dmg | dmg      | darwin   |
    And the current account has 1 "policy" for an existing "product"
    And the current account has 1 "license" for an existing "policy"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    And I use API version "1.0"
    And the current user has 1 "license"
    When I send a GET request to "/accounts/test1/releases/actions/upgrade?version=1.0.2&channel=stable&platform=darwin&filetype=dmg&product=6198261a-48b5-4445-a045-9fed4afc7735"
    Then the response status should be "204"

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
      | 21088509-2dfc-4459-a8a2-3204136ad1df | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.0   | stable  |
    And the current account has the following "artifact" rows:
      | release_id                           | filename           | filetype | platform |
      | f53f57cb-dc3f-4b18-9d90-534038214b49 | Test-App-1.0.0.dmg | dmg      | darwin   |
      | 80e20324-c578-4763-bbef-c9698bf0023a | Test-App-1.0.1.dmg | dmg      | darwin   |
      | d34846b1-fdfe-46aa-9194-7d1a08e2d0cb | Test-App-1.0.2.dmg | dmg      | darwin   |
      | f517903b-5126-4405-9793-bf95a287b1f9 | Test-App-1.0.3.dmg | dmg      | darwin   |
      | 21088509-2dfc-4459-a8a2-3204136ad1df | Test-App-1.1.0.dmg | dmg      | darwin   |
    And I am an admin of account "test1"
    And I use an authentication token
    And I use API version "1.0"
    When I send a GET request to "/accounts/test1/releases/actions/upgrade?version=1.0.2&channel=stable&platform=darwin&filetype=dmg&product=6198261a-48b5-4445-a045-9fed4afc7735"
    Then the response status should be "303"
    And the response body should be an "artifact"
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
      | 21088509-2dfc-4459-a8a2-3204136ad1df | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.0   | stable  |
    And the current account has the following "artifact" rows:
      | release_id                           | filename           | filetype | platform |
      | f53f57cb-dc3f-4b18-9d90-534038214b49 | Test-App-1.0.0.dmg | dmg      | darwin   |
      | 80e20324-c578-4763-bbef-c9698bf0023a | Test-App-1.0.1.dmg | dmg      | darwin   |
      | d34846b1-fdfe-46aa-9194-7d1a08e2d0cb | Test-App-1.0.2.dmg | dmg      | darwin   |
      | f517903b-5126-4405-9793-bf95a287b1f9 | Test-App-1.0.3.dmg | dmg      | darwin   |
      | 21088509-2dfc-4459-a8a2-3204136ad1df | Test-App-1.1.0.dmg | dmg      | darwin   |
    And I am a product of account "test1"
    And I use an authentication token
    And I use API version "1.0"
    And the current user has 1 "license"
    When I send a GET request to "/accounts/test1/releases/actions/upgrade?version=1.0.2&channel=stable&platform=darwin&filetype=dmg&product=6198261a-48b5-4445-a045-9fed4afc7735"
    Then the response status should be "303"
    And the response body should be an "artifact"
    And the response body should contain meta which includes the following:
      """
      {
        "current": "1.0.2",
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
      | 21088509-2dfc-4459-a8a2-3204136ad1df | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.0   | stable  |
    And the current account has the following "artifact" rows:
      | release_id                           | filename           | filetype | platform |
      | f53f57cb-dc3f-4b18-9d90-534038214b49 | Test-App-1.0.0.dmg | dmg      | darwin   |
      | 80e20324-c578-4763-bbef-c9698bf0023a | Test-App-1.0.1.dmg | dmg      | darwin   |
      | d34846b1-fdfe-46aa-9194-7d1a08e2d0cb | Test-App-1.0.2.dmg | dmg      | darwin   |
      | f517903b-5126-4405-9793-bf95a287b1f9 | Test-App-1.0.3.dmg | dmg      | darwin   |
      | 21088509-2dfc-4459-a8a2-3204136ad1df | Test-App-1.1.0.dmg | dmg      | darwin   |
    And I am a product of account "test1"
    And I use an authentication token
    And I use API version "1.0"
    And the current user has 1 "license"
    When I send a GET request to "/accounts/test1/releases/actions/upgrade?version=1.0.2&channel=stable&platform=darwin&filetype=dmg&product=6198261a-48b5-4445-a045-9fed4afc7735"
    Then the response status should be "204"

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
      | 21088509-2dfc-4459-a8a2-3204136ad1df | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.0   | stable  |
    And the current account has the following "artifact" rows:
      | release_id                           | filename           | filetype | platform |
      | f53f57cb-dc3f-4b18-9d90-534038214b49 | Test-App-1.0.0.dmg | dmg      | darwin   |
      | 80e20324-c578-4763-bbef-c9698bf0023a | Test-App-1.0.1.dmg | dmg      | darwin   |
      | d34846b1-fdfe-46aa-9194-7d1a08e2d0cb | Test-App-1.0.2.dmg | dmg      | darwin   |
      | f517903b-5126-4405-9793-bf95a287b1f9 | Test-App-1.0.3.dmg | dmg      | darwin   |
      | 21088509-2dfc-4459-a8a2-3204136ad1df | Test-App-1.1.0.dmg | dmg      | darwin   |
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
    And I use API version "1.0"
    When I send a GET request to "/accounts/test1/releases/actions/upgrade?version=1.0.0&channel=stable&platform=darwin&filetype=dmg&product=6198261a-48b5-4445-a045-9fed4afc7735"
    Then the response status should be "303"
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
      | 21088509-2dfc-4459-a8a2-3204136ad1df | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.0   | stable  |
    And the current account has the following "artifact" rows:
      | release_id                           | filename           | filetype | platform |
      | f53f57cb-dc3f-4b18-9d90-534038214b49 | Test-App-1.0.0.dmg | dmg      | darwin   |
      | 80e20324-c578-4763-bbef-c9698bf0023a | Test-App-1.0.1.dmg | dmg      | darwin   |
      | d34846b1-fdfe-46aa-9194-7d1a08e2d0cb | Test-App-1.0.2.dmg | dmg      | darwin   |
      | f517903b-5126-4405-9793-bf95a287b1f9 | Test-App-1.0.3.dmg | dmg      | darwin   |
      | 21088509-2dfc-4459-a8a2-3204136ad1df | Test-App-1.1.0.dmg | dmg      | darwin   |
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
        "expiry": "2042-01-03T14:18:02.743Z"
      }
      """
    And I am a license of account "test1"
    And I use an authentication token
    And I use API version "1.0"
    When I send a GET request to "/accounts/test1/releases/actions/upgrade?version=1.0.0&channel=stable&platform=darwin&filetype=dmg&product=6198261a-48b5-4445-a045-9fed4afc7735"
    Then the response status should be "303"
    And sidekiq should process 1 "event-log" job
    And sidekiq should process 1 "event-notification" job
    And the first "license" should have the expiry "2042-01-03T14:18:02.743Z"

  Scenario: License retrieves an upgrade for a release that has multiple artifacts
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name     |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test App |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | version | channel | api_version |
      | e314ba5d-c760-4e54-81c4-fa01af68ff66 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0   | stable  | 1.0         |
      | e26e9fef-d1ce-43d3-a15c-c8fc94429709 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.2.0   | stable  | 1.0         |
      | ff04d1c4-cc04-4d19-985a-cb113827b821 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.1   | stable  | 1.0         |
      | c8b55f91-e66f-4093-ae4d-7f3d390eae8d | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.0   | stable  | 1.0         |
      | dde54ea8-731d-4375-9d57-186ef01f3fcb | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.3.0   | stable  | 1.0         |
      | 21088509-2dfc-4459-a8a2-3204136ad1df | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.4.0   | stable  | 1.1         |
    And the current account has the following "artifact" rows:
      | release_id                           | filename                | filetype | platform |
      | e314ba5d-c760-4e54-81c4-fa01af68ff66 | Test-App-1.0.0.dmg      | dmg      | macos    |
      | e26e9fef-d1ce-43d3-a15c-c8fc94429709 | Test-App-1.2.0.dmg      | dmg      | macos    |
      | ff04d1c4-cc04-4d19-985a-cb113827b821 | Test-App-1.0.1.zip      | zip      | macos    |
      | c8b55f91-e66f-4093-ae4d-7f3d390eae8d | Test-App-1.1.0.zip      | zip      | macos    |
      | dde54ea8-731d-4375-9d57-186ef01f3fcb | Test-App-1.3.0.zip      | zip      | macos    |
      | 21088509-2dfc-4459-a8a2-3204136ad1df | Test-App-1.4.0.dmg      | dmg      | darwin   |
      | 21088509-2dfc-4459-a8a2-3204136ad1df | Test-App-1.4.0.exe      | exe      | win32    |
      | 21088509-2dfc-4459-a8a2-3204136ad1df | Test-App-1.4.0.zip      | zip      | darwin   |
      | 21088509-2dfc-4459-a8a2-3204136ad1df | Test-App-1.4.0.appimage | appimage | linux    |
      | 21088509-2dfc-4459-a8a2-3204136ad1df | stable.yml              | yml      |          |
    And the current account has 1 "policy" for the first "product"
    And the current account has 1 "license" for the first "policy"
    And I am a license of account "test1"
    And I use an authentication token
    And I use API version "1.0"
    When I send a GET request to "/accounts/test1/releases/actions/upgrade?version=1.0.0&channel=stable&platform=darwin&filetype=dmg&product=6198261a-48b5-4445-a045-9fed4afc7735"
    Then the response status should be "303"
    And the response body should be an "artifact" with the following attributes:
      """
      { "filename": "Test-App-1.4.0.dmg" }
      """
    And the response body should contain meta which includes the following:
      """
      {
        "current": "1.0.0",
        "next": "1.4.0"
      }
      """

  Scenario: License retrieves an upgrade for a release that has multiple artifacts (same platform/filetype)
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name     |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test App |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | version | channel | api_version |
      | e314ba5d-c760-4e54-81c4-fa01af68ff66 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0   | stable  | 1.0         |
      | e26e9fef-d1ce-43d3-a15c-c8fc94429709 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.2.0   | stable  | 1.0         |
      | ff04d1c4-cc04-4d19-985a-cb113827b821 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.1   | stable  | 1.0         |
      | c8b55f91-e66f-4093-ae4d-7f3d390eae8d | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.0   | stable  | 1.0         |
      | dde54ea8-731d-4375-9d57-186ef01f3fcb | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.3.0   | stable  | 1.0         |
      | 21088509-2dfc-4459-a8a2-3204136ad1df | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.4.0   | stable  | 1.1         |
    And the current account has the following "artifact" rows:
      | release_id                           | filename                | filetype | platform |
      | e314ba5d-c760-4e54-81c4-fa01af68ff66 | Test-App-1.0.0.dmg      | dmg      | macos    |
      | e26e9fef-d1ce-43d3-a15c-c8fc94429709 | Test-App-1.2.0.dmg      | dmg      | macos    |
      | ff04d1c4-cc04-4d19-985a-cb113827b821 | Test-App-1.0.1.zip      | zip      | macos    |
      | c8b55f91-e66f-4093-ae4d-7f3d390eae8d | Test-App-1.1.0.zip      | zip      | macos    |
      | dde54ea8-731d-4375-9d57-186ef01f3fcb | Test-App-1.3.0.zip      | zip      | macos    |
      | 21088509-2dfc-4459-a8a2-3204136ad1df | Test-App-1.4.0.dmg      | dmg      | darwin   |
      | 21088509-2dfc-4459-a8a2-3204136ad1df | Test-App-Installer.dmg  | dmg      | darwin   |
      | 21088509-2dfc-4459-a8a2-3204136ad1df | Test-App-1.4.0.exe      | exe      | win32    |
      | 21088509-2dfc-4459-a8a2-3204136ad1df | Test-App-1.4.0.zip      | zip      | darwin   |
      | 21088509-2dfc-4459-a8a2-3204136ad1df | Test-App-1.4.0.appimage | appimage | linux    |
      | 21088509-2dfc-4459-a8a2-3204136ad1df | stable.yml              | yml      |          |
    And the current account has 1 "policy" for the first "product"
    And the current account has 1 "license" for the first "policy"
    And I am a license of account "test1"
    And I use an authentication token
    And I use API version "1.0"
    When I send a GET request to "/accounts/test1/releases/actions/upgrade?version=1.0.0&channel=stable&platform=darwin&filetype=dmg&product=6198261a-48b5-4445-a045-9fed4afc7735"
    Then the response status should be "422"
    And the response body should be an array of 1 error
    And the first error should have the following properties:
      """
      {
        "title": "Unprocessable entity",
        "detail": "multiple artifacts are not supported by this release (see upgrading from v1.0 to v1.1)"
      }
      """
