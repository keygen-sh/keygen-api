@api/v1.0 @deprecated
Feature: Show release artifact

  Background:
    Given the following "accounts" exist:
      | name    | slug  |
      | Test 1  | test1 |
      | Test 2  | test2 |
    And I send and accept JSON

  Scenario: Endpoint should be inaccessible when account is disabled
    Given the account "test1" is canceled
    And I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "release"
    And the current account has 1 "artifact" for the last "release"
    And I use an authentication token
    And I use API version "1.0"
    When I send a GET request to "/accounts/test1/artifacts/$0"
    Then the response status should be "403"

  # NOTE(ezekg) Since we no longer have a uniqueness index, and we've removed the upsert
  #             release method, we need to assert that multiple artifacts with the same
  #             version are correctly handled, i.e. that the latest version is fetched,
  #             sorted by created_at and semver_* columns.
  Scenario: License retrieves the latest artifact by filename (duplicate versions)
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name     |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test App |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | version | channel | api_version |
      | 80e20324-c578-4763-bbef-c9698bf0023a | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0   | stable  | 1.0         |
      | d34846b1-fdfe-46aa-9194-7d1a08e2d0cb | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0   | stable  | 1.0         |
      | f517903b-5126-4405-9793-bf95a287b1f9 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0   | stable  | 1.0         |
      | 21088509-2dfc-4459-a8a2-3204136ad1df | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0   | stable  | 1.0         |
      | 0fd7f4a3-dd48-40bc-8f1c-d4449432f8fb | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0   | stable  | 1.0         |
      | eb4d5801-5238-4825-9236-50769fce5d2f | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.1   | stable  | 1.0         |
      | 298eac03-7caf-4225-8554-181920d70d75 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.1   | stable  | 1.0         |
      | 4e41ac33-79ea-4dc3-b179-87d0174aaed4 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.1   | stable  | 1.0         |
      | c1f7e75b-3aba-4bba-a0b0-d3fbe8cf7750 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.1   | stable  | 1.0         |
    And the current account has the following "artifact" rows:
      | release_id                           | filename       | filetype | platform |
      | 80e20324-c578-4763-bbef-c9698bf0023a | latest-mac.yml | yml      | darwin   |
      | d34846b1-fdfe-46aa-9194-7d1a08e2d0cb | latest-mac.yml | yml      | darwin   |
      | f517903b-5126-4405-9793-bf95a287b1f9 | latest-mac.yml | yml      | darwin   |
      | 21088509-2dfc-4459-a8a2-3204136ad1df | latest-mac.yml | yml      | darwin   |
      | 0fd7f4a3-dd48-40bc-8f1c-d4449432f8fb | latest-mac.yml | yml      | darwin   |
      | eb4d5801-5238-4825-9236-50769fce5d2f | latest-mac.yml | yml      | darwin   |
      | 298eac03-7caf-4225-8554-181920d70d75 | latest-mac.yml | yml      | darwin   |
      | 4e41ac33-79ea-4dc3-b179-87d0174aaed4 | latest-mac.yml | yml      | darwin   |
      | c1f7e75b-3aba-4bba-a0b0-d3fbe8cf7750 | latest-mac.yml | yml      | darwin   |
    And the current account has 1 "policy" for an existing "product"
    And the current account has 1 "license" for an existing "policy"
    And the current account has 1 "artifact" for the last "release"
    And I am a license of account "test1"
    And I use an authentication token
    And I use API version "1.0"
    When I send a GET request to "/accounts/test1/artifacts/latest-mac.yml"
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
            "id": "c1f7e75b-3aba-4bba-a0b0-d3fbe8cf7750"
          },
          "links": {
            "related": "/v1/accounts/$account/releases/c1f7e75b-3aba-4bba-a0b0-d3fbe8cf7750"
          }
        }
      }
      """
    And the response body should be an "artifact" with the following attributes:
      """
      { "key": "latest-mac.yml" }
      """
