@api/v1
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
    When I send a GET request to "/accounts/test1/artifacts/$0"
    Then the response status should be "403"

  Scenario: Admin retrieves an artifact for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 3 "releases"
    And the current account has 1 "artifact" for each "release"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/artifacts/$0"
    Then the response status should be "303"
    And the response body should be an "artifact"
    And sidekiq should have 2 "webhook" jobs
    And sidekiq should have 2 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin retrieves an artifact for their account (prefers no-download via header)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 3 "releases"
    And the current account has 1 "artifact" for each "release"
    And I send the following raw headers:
      """
      Prefer: no-download
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/artifacts/$0"
    Then the response status should be "200"
    And the response body should be an "artifact" without a "redirect" link
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin retrieves an artifact for their account (prefers no-download via query parameter)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 3 "releases"
    And the current account has 1 "artifact" for each "release"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/artifacts/$0?prefer=no-download"
    Then the response status should be "200"
    And the response body should be an "artifact" without a "redirect" link
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin retrieves an artifact for their account (prefers no-redirect via header)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 3 "releases"
    And the current account has 1 "artifact" for each "release"
    And I send the following raw headers:
      """
      Prefer: no-redirect
      """
    And I use an authentication token
    When I send a GET request to "/accounts/test1/artifacts/$0"
    Then the response status should be "200"
    And the response body should be an "artifact" with a "redirect" link
    And sidekiq should have 2 "webhook" jobs
    And sidekiq should have 2 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin retrieves an artifact for their account (prefers no-redirect via query parameter)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 3 "releases"
    And the current account has 1 "artifact" for each "release"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/artifacts/$0?prefer=no-redirect"
    Then the response status should be "200"
    And the response body should be an "artifact" with a "redirect" link
    And sidekiq should have 2 "webhook" jobs
    And sidekiq should have 2 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin retrieves an artifact for their account (prefers via unsupported query parameter)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 3 "releases"
    And the current account has 1 "artifact" for each "release"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/artifacts/$0?prefer[]=no-redirect&prefer[]=no-download"
    Then the response status should be "303"
    And the response body should be an "artifact"
    And sidekiq should have 2 "webhook" jobs
    And sidekiq should have 2 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Developer retrieves an artifact for their account
    Given the current account is "test1"
    And the current account has 1 "developer"
    And I am a developer of account "test1"
    And the current account has 3 "releases"
    And the current account has 1 "artifact" for each "release"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/artifacts/$0"
    Then the response status should be "303"

  Scenario: Sales retrieves an artifact for their account
    Given the current account is "test1"
    And the current account has 1 "sales-agent"
    And I am a sales agent of account "test1"
    And the current account has 3 "releases"
    And the current account has 1 "artifact" for each "release"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/artifacts/$0"
    Then the response status should be "303"

  Scenario: Support retrieves an artifact for their account
    Given the current account is "test1"
    And the current account has 1 "support-agent"
    And I am a support agent of account "test1"
    And the current account has 3 "releases"
    And the current account has 1 "artifact" for each "release"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/artifacts/$0"
    Then the response status should be "303"

  Scenario: Read-only retrieves an artifact for their account
    Given the current account is "test1"
    And the current account has 1 "read-only"
    And I am a read only of account "test1"
    And the current account has 3 "releases"
    And the current account has 1 "artifact" for each "release"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/artifacts/$0"
    Then the response status should be "303"

  Scenario: Admin retrieves an invalid artifact for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/artifacts/invalid"
    Then the response status should be "404"
    And the first error should have the following properties:
      """
      {
        "title": "Not found",
        "detail": "The requested release artifact 'invalid' was not found",
        "code": "NOT_FOUND"
      }
      """

  @ce
  Scenario: Environment retrieves an isolated artifact (via environment header)
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And the current account has 1 isolated "artifact"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    When I send a GET request to "/accounts/test1/artifacts/$0"
    Then the response status should be "400"
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

  @ce
  Scenario: Environment retrieves an artifact (via environment param)
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And the current account has 1 isolated "artifact"
    And I am an environment of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/artifacts/$0?environment=isolated"
    Then the response status should be "400"
    And the first error should have the following properties:
      """
      {
        "title": "Bad request",
        "detail": "is unsupported",
        "source": {
          "parameter": "environment"
        }
      }
      """

  @ee
  Scenario: Environment retrieves an isolated artifact (via environment header)
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And the current account has 1 isolated "artifact"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    When I send a GET request to "/accounts/test1/artifacts/$0"
    Then the response status should be "303"
    And the response body should be an "artifact"

  @ee
  Scenario: Environment retrieves an isolated artifact (via environment param)
    Given the current account is "test1"
    And the current account has 1 isolated "environment"
    And the current account has 1 isolated "artifact"
    And I am an environment of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/artifacts/$0?environment=isolated"
    Then the response status should be "303"
    And the response body should be an "artifact"

  @ee
  Scenario: Environment retrieves a shared artifact (via environment header)
    Given the current account is "test1"
    And the current account has 1 shared "environment"
    And the current account has 1 shared "artifact"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
    When I send a GET request to "/accounts/test1/artifacts/$0"
    Then the response status should be "303"
    And the response body should be an "artifact"

  @ee
  Scenario: Environment retrieves a shared artifact (via environment param)
    Given the current account is "test1"
    And the current account has 1 shared "environment"
    And the current account has 1 shared "artifact"
    And I am an environment of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/artifacts/$0?environment=shared"
    Then the response status should be "303"
    And the response body should be an "artifact"

  Scenario: Product retrieves an artifact for their product
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "release" for the last "product"
    And the current account has 1 "artifact" for the last "release"
    And I am a product of account "test1"
    And I use an authentication token
    And the current product has 1 "release"
    When I send a GET request to "/accounts/test1/artifacts/$0"
    Then the response status should be "303"
    And the response body should be an "artifact"

  Scenario: Product retrieves an artifact for another product
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "release"
    And the current account has 1 "artifact" for the last "release"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/artifacts/$0"
    Then the response status should be "404"

  Scenario: User retrieves an artifact without a license for it
    Given the current account is "test1"
    And the current account has 1 "user"
    And the current account has 1 "release"
    And the current account has 1 "artifact" for the last "release"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/artifacts/$0"
    Then the response status should be "404"

  Scenario: User retrieves an artifact with a license for it
    Given the current account is "test1"
    And the current account has 1 "user"
    And the current account has 1 "product"
    And the current account has 1 "release" for an existing "product"
    And the current account has 1 "policy" for an existing "product"
    And the current account has 1 "license" for an existing "policy"
    And the current account has 1 "artifact" for the last "release"
    And I am a user of account "test1"
    And I use an authentication token
    And the current user has 1 "license"
    When I send a GET request to "/accounts/test1/artifacts/$0"
    Then the response status should be "303"

  Scenario: License retrieves an artifact of a different product
    Given the current account is "test1"
    And the current account has 1 "license"
    And the current account has 1 "release"
    And the current account has 1 "artifact" for the last "release"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/artifacts/$0"
    Then the response status should be "404"

  Scenario: License retrieves an artifact of their product
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "release" for an existing "product"
    And the current account has 1 "policy" for an existing "product"
    And the current account has 1 "license" for an existing "policy"
    And the current account has 1 "artifact" for the last "release"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/artifacts/$0"
    Then the response status should be "303"

  Scenario: License retrieves the latest artifact by filename
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
      | release_id                           | filename   | filetype | platform |
      | f53f57cb-dc3f-4b18-9d90-534038214b49 | latest.yml | yml      | darwin   |
      | 80e20324-c578-4763-bbef-c9698bf0023a | latest.yml | yml      | darwin   |
      | d34846b1-fdfe-46aa-9194-7d1a08e2d0cb | latest.yml | yml      | darwin   |
      | f517903b-5126-4405-9793-bf95a287b1f9 | latest.yml | yml      | darwin   |
      | 21088509-2dfc-4459-a8a2-3204136ad1df | latest.yml | yml      | darwin   |
      | 0fd7f4a3-dd48-40bc-8f1c-d4449432f8fb | latest.yml | yml      | darwin   |
      | eb4d5801-5238-4825-9236-50769fce5d2f | latest.yml | yml      | darwin   |
      | 298eac03-7caf-4225-8554-181920d70d75 | latest.yml | yml      | darwin   |
      | 4e41ac33-79ea-4dc3-b179-87d0174aaed4 | latest.yml | yml      | darwin   |
      | c1f7e75b-3aba-4bba-a0b0-d3fbe8cf7750 | latest.yml | yml      | darwin   |
      | 61992b58-c283-4c56-95d7-d83ff52bc0f4 | latest.yml | yml      | darwin   |
      | 873c088e-8d32-4d5d-afd4-11a28c58b9bc | latest.yml | yml      | darwin   |
      | 4d2737af-0c5a-4c55-a31a-e8781261cbd5 | latest.yml | yml      | darwin   |
      | e8d06fe3-ac5f-44af-a88d-bebb2d322947 | latest.yml | yml      | darwin   |
      | f761080b-92fe-423a-a8b6-68f91d55a08a | latest.yml | yml      | darwin   |
      | 8d1eb3ce-fb23-41a9-b66c-6328b2fde235 | latest.yml | yml      | darwin   |
      | f287e696-27cb-4d2b-978a-d6cca2d386c2 | latest.yml | yml      | darwin   |
      | da38f541-0f22-4340-a7b5-4f7c410ded88 | latest.yml | yml      | darwin   |
      | 88d9bba0-726b-4695-aee2-28c86ff689c4 | latest.yml | yml      | darwin   |
      | 8147443c-fe47-4654-9935-80a29b490905 | latest.yml | yml      | darwin   |
      | 697107b8-01fb-4c05-9c95-0399e2fab5f7 | latest.yml | yml      | darwin   |
      | 1849d528-e552-4def-91cb-4020a9ec995e | latest.yml | yml      | darwin   |
      | 46da3538-89d1-4bcf-a478-25109a40eae5 | latest.yml | yml      | darwin   |
      | 01947f94-f574-4b71-aa4f-7a5b9101a092 | latest.yml | yml      | darwin   |
      | 5f187a7d-8ab8-4a9c-85f6-9bc0331f09b4 | latest.yml | yml      | darwin   |
      | 04fc4e72-beaa-4a6f-92d7-168a0c4e924c | latest.yml | yml      | darwin   |
      | c2b11198-de3d-4c7c-8dd8-e3fe86650e6b | latest.yml | yml      | darwin   |
      | 14496b66-0004-422f-87e9-15172287bae4 | latest.yml | yml      | darwin   |
      | 7da7b744-1c60-441f-967d-68134c93c2d9 | latest.yml | yml      | darwin   |
      | 84fe5dbf-6e41-458e-821b-d716487fbd12 | latest.yml | yml      | darwin   |
      | 33046ea9-2a77-46c3-b650-7b3b4bbae016 | latest.yml | yml      | darwin   |
      | aa067117-948f-46e8-977f-6998ad366a97 | latest.yml | yml      | darwin   |
      | fffa0764-3a19-48ea-beb3-8950563c7357 | latest.yml | yml      | darwin   |
      | 165d5389-e535-4f36-9232-ed59c67375d1 | latest.yml | yml      | darwin   |
      | e4fa628e-593d-48bc-8e3e-5e4dda1f2c3a | latest.yml | yml      | darwin   |
      | fd10ab0c-c52a-412f-b34f-180eebd7325d | latest.yml | yml      | darwin   |
      | f98d8c17-5fad-4361-ad89-43b0c6f6fa00 | latest.yml | yml      | darwin   |
      | 077ca1f2-6125-4a77-bdf0-3161a0fc278e | latest.yml | yml      | darwin   |
      | 0a027f00-0860-4fa7-bd37-5900c8866818 | latest.yml | yml      | darwin   |
    And the current account has 1 "policy" for an existing "product"
    And the current account has 1 "license" for an existing "policy"
    And the current account has 1 "artifact" for the last "release"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/artifacts/latest.yml"
    Then the response status should be "303"
    And the response body should be an "artifact" with the following relationships:
      """
      {
        "release": {
          "data": {
            "type": "releases",
            "id": "0a027f00-0860-4fa7-bd37-5900c8866818"
          },
          "links": {
            "related": "/v1/accounts/$account/releases/0a027f00-0860-4fa7-bd37-5900c8866818"
          }
        }
      }
      """
    And the response body should be an "artifact" with the following attributes:
      """
      { "filename": "latest.yml" }
      """

  Scenario: License retrieves the latest artifact by filename (stable channel)
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
      | release_id                           | filename   | filetype | platform |
      | f53f57cb-dc3f-4b18-9d90-534038214b49 | latest.yml | yml      | darwin   |
      | 80e20324-c578-4763-bbef-c9698bf0023a | latest.yml | yml      | darwin   |
      | d34846b1-fdfe-46aa-9194-7d1a08e2d0cb | latest.yml | yml      | darwin   |
      | f517903b-5126-4405-9793-bf95a287b1f9 | latest.yml | yml      | darwin   |
      | 21088509-2dfc-4459-a8a2-3204136ad1df | latest.yml | yml      | darwin   |
      | 0fd7f4a3-dd48-40bc-8f1c-d4449432f8fb | latest.yml | yml      | darwin   |
      | eb4d5801-5238-4825-9236-50769fce5d2f | latest.yml | yml      | darwin   |
      | 298eac03-7caf-4225-8554-181920d70d75 | latest.yml | yml      | darwin   |
      | 4e41ac33-79ea-4dc3-b179-87d0174aaed4 | latest.yml | yml      | darwin   |
      | c1f7e75b-3aba-4bba-a0b0-d3fbe8cf7750 | latest.yml | yml      | darwin   |
      | 61992b58-c283-4c56-95d7-d83ff52bc0f4 | latest.yml | yml      | darwin   |
      | 873c088e-8d32-4d5d-afd4-11a28c58b9bc | latest.yml | yml      | darwin   |
      | 4d2737af-0c5a-4c55-a31a-e8781261cbd5 | latest.yml | yml      | darwin   |
      | e8d06fe3-ac5f-44af-a88d-bebb2d322947 | latest.yml | yml      | darwin   |
      | f761080b-92fe-423a-a8b6-68f91d55a08a | latest.yml | yml      | darwin   |
      | 8d1eb3ce-fb23-41a9-b66c-6328b2fde235 | latest.yml | yml      | darwin   |
      | f287e696-27cb-4d2b-978a-d6cca2d386c2 | latest.yml | yml      | darwin   |
      | da38f541-0f22-4340-a7b5-4f7c410ded88 | latest.yml | yml      | darwin   |
      | 88d9bba0-726b-4695-aee2-28c86ff689c4 | latest.yml | yml      | darwin   |
      | 8147443c-fe47-4654-9935-80a29b490905 | latest.yml | yml      | darwin   |
      | 697107b8-01fb-4c05-9c95-0399e2fab5f7 | latest.yml | yml      | darwin   |
      | 1849d528-e552-4def-91cb-4020a9ec995e | latest.yml | yml      | darwin   |
      | 46da3538-89d1-4bcf-a478-25109a40eae5 | latest.yml | yml      | darwin   |
      | 01947f94-f574-4b71-aa4f-7a5b9101a092 | latest.yml | yml      | darwin   |
      | 5f187a7d-8ab8-4a9c-85f6-9bc0331f09b4 | latest.yml | yml      | darwin   |
      | 04fc4e72-beaa-4a6f-92d7-168a0c4e924c | latest.yml | yml      | darwin   |
      | c2b11198-de3d-4c7c-8dd8-e3fe86650e6b | latest.yml | yml      | darwin   |
      | 14496b66-0004-422f-87e9-15172287bae4 | latest.yml | yml      | darwin   |
      | 7da7b744-1c60-441f-967d-68134c93c2d9 | latest.yml | yml      | darwin   |
      | 84fe5dbf-6e41-458e-821b-d716487fbd12 | latest.yml | yml      | darwin   |
      | 33046ea9-2a77-46c3-b650-7b3b4bbae016 | latest.yml | yml      | darwin   |
      | aa067117-948f-46e8-977f-6998ad366a97 | latest.yml | yml      | darwin   |
      | fffa0764-3a19-48ea-beb3-8950563c7357 | latest.yml | yml      | darwin   |
      | 165d5389-e535-4f36-9232-ed59c67375d1 | latest.yml | yml      | darwin   |
      | e4fa628e-593d-48bc-8e3e-5e4dda1f2c3a | latest.yml | yml      | darwin   |
      | fd10ab0c-c52a-412f-b34f-180eebd7325d | latest.yml | yml      | darwin   |
      | f98d8c17-5fad-4361-ad89-43b0c6f6fa00 | latest.yml | yml      | darwin   |
      | 077ca1f2-6125-4a77-bdf0-3161a0fc278e | latest.yml | yml      | darwin   |
      | 0a027f00-0860-4fa7-bd37-5900c8866818 | latest.yml | yml      | darwin   |
    And the current account has 1 "policy" for an existing "product"
    And the current account has 1 "license" for an existing "policy"
    And the current account has 1 "artifact" for the last "release"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/artifacts/latest.yml?channel=stable"
    Then the response status should be "303"
    And the response body should be an "artifact" with the following relationships:
      """
      {
        "release": {
          "data": {
            "type": "releases",
            "id": "165d5389-e535-4f36-9232-ed59c67375d1"
          },
          "links": {
            "related": "/v1/accounts/$account/releases/165d5389-e535-4f36-9232-ed59c67375d1"
          }
        }
      }
      """
    And the response body should be an "artifact" with the following attributes:
      """
      { "filename": "latest.yml" }
      """

  Scenario: License retrieves the latest artifact by filename (rc channel)
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
      | release_id                           | filename   | filetype | platform |
      | f53f57cb-dc3f-4b18-9d90-534038214b49 | latest.yml | yml      | darwin   |
      | 80e20324-c578-4763-bbef-c9698bf0023a | latest.yml | yml      | darwin   |
      | d34846b1-fdfe-46aa-9194-7d1a08e2d0cb | latest.yml | yml      | darwin   |
      | f517903b-5126-4405-9793-bf95a287b1f9 | latest.yml | yml      | darwin   |
      | 21088509-2dfc-4459-a8a2-3204136ad1df | latest.yml | yml      | darwin   |
      | 0fd7f4a3-dd48-40bc-8f1c-d4449432f8fb | latest.yml | yml      | darwin   |
      | eb4d5801-5238-4825-9236-50769fce5d2f | latest.yml | yml      | darwin   |
      | 298eac03-7caf-4225-8554-181920d70d75 | latest.yml | yml      | darwin   |
      | 4e41ac33-79ea-4dc3-b179-87d0174aaed4 | latest.yml | yml      | darwin   |
      | c1f7e75b-3aba-4bba-a0b0-d3fbe8cf7750 | latest.yml | yml      | darwin   |
      | 61992b58-c283-4c56-95d7-d83ff52bc0f4 | latest.yml | yml      | darwin   |
      | 873c088e-8d32-4d5d-afd4-11a28c58b9bc | latest.yml | yml      | darwin   |
      | 4d2737af-0c5a-4c55-a31a-e8781261cbd5 | latest.yml | yml      | darwin   |
      | e8d06fe3-ac5f-44af-a88d-bebb2d322947 | latest.yml | yml      | darwin   |
      | f761080b-92fe-423a-a8b6-68f91d55a08a | latest.yml | yml      | darwin   |
      | 8d1eb3ce-fb23-41a9-b66c-6328b2fde235 | latest.yml | yml      | darwin   |
      | f287e696-27cb-4d2b-978a-d6cca2d386c2 | latest.yml | yml      | darwin   |
      | da38f541-0f22-4340-a7b5-4f7c410ded88 | latest.yml | yml      | darwin   |
      | 88d9bba0-726b-4695-aee2-28c86ff689c4 | latest.yml | yml      | darwin   |
      | 8147443c-fe47-4654-9935-80a29b490905 | latest.yml | yml      | darwin   |
      | 697107b8-01fb-4c05-9c95-0399e2fab5f7 | latest.yml | yml      | darwin   |
      | 1849d528-e552-4def-91cb-4020a9ec995e | latest.yml | yml      | darwin   |
      | 46da3538-89d1-4bcf-a478-25109a40eae5 | latest.yml | yml      | darwin   |
      | 01947f94-f574-4b71-aa4f-7a5b9101a092 | latest.yml | yml      | darwin   |
      | 5f187a7d-8ab8-4a9c-85f6-9bc0331f09b4 | latest.yml | yml      | darwin   |
      | 04fc4e72-beaa-4a6f-92d7-168a0c4e924c | latest.yml | yml      | darwin   |
      | c2b11198-de3d-4c7c-8dd8-e3fe86650e6b | latest.yml | yml      | darwin   |
      | 14496b66-0004-422f-87e9-15172287bae4 | latest.yml | yml      | darwin   |
      | 7da7b744-1c60-441f-967d-68134c93c2d9 | latest.yml | yml      | darwin   |
      | 84fe5dbf-6e41-458e-821b-d716487fbd12 | latest.yml | yml      | darwin   |
      | 33046ea9-2a77-46c3-b650-7b3b4bbae016 | latest.yml | yml      | darwin   |
      | aa067117-948f-46e8-977f-6998ad366a97 | latest.yml | yml      | darwin   |
      | fffa0764-3a19-48ea-beb3-8950563c7357 | latest.yml | yml      | darwin   |
      | 165d5389-e535-4f36-9232-ed59c67375d1 | latest.yml | yml      | darwin   |
      | e4fa628e-593d-48bc-8e3e-5e4dda1f2c3a | latest.yml | yml      | darwin   |
      | fd10ab0c-c52a-412f-b34f-180eebd7325d | latest.yml | yml      | darwin   |
      | f98d8c17-5fad-4361-ad89-43b0c6f6fa00 | latest.yml | yml      | darwin   |
      | 077ca1f2-6125-4a77-bdf0-3161a0fc278e | latest.yml | yml      | darwin   |
      | 0a027f00-0860-4fa7-bd37-5900c8866818 | latest.yml | yml      | darwin   |
    And the current account has 1 "policy" for an existing "product"
    And the current account has 1 "license" for an existing "policy"
    And the current account has 1 "artifact" for the last "release"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/artifacts/latest.yml?channel=rc"
    Then the response status should be "303"
    And the response body should be an "artifact" with the following relationships:
      """
      {
        "release": {
          "data": {
            "type": "releases",
            "id": "165d5389-e535-4f36-9232-ed59c67375d1"
          },
          "links": {
            "related": "/v1/accounts/$account/releases/165d5389-e535-4f36-9232-ed59c67375d1"
          }
        }
      }
      """
    And the response body should be an "artifact" with the following attributes:
      """
      { "filename": "latest.yml" }
      """

  Scenario: License retrieves the latest artifact by filename (beta channel)
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
      | release_id                           | filename   | filetype | platform |
      | f53f57cb-dc3f-4b18-9d90-534038214b49 | latest.yml | yml      | darwin   |
      | 80e20324-c578-4763-bbef-c9698bf0023a | latest.yml | yml      | darwin   |
      | d34846b1-fdfe-46aa-9194-7d1a08e2d0cb | latest.yml | yml      | darwin   |
      | f517903b-5126-4405-9793-bf95a287b1f9 | latest.yml | yml      | darwin   |
      | 21088509-2dfc-4459-a8a2-3204136ad1df | latest.yml | yml      | darwin   |
      | 0fd7f4a3-dd48-40bc-8f1c-d4449432f8fb | latest.yml | yml      | darwin   |
      | eb4d5801-5238-4825-9236-50769fce5d2f | latest.yml | yml      | darwin   |
      | 298eac03-7caf-4225-8554-181920d70d75 | latest.yml | yml      | darwin   |
      | 4e41ac33-79ea-4dc3-b179-87d0174aaed4 | latest.yml | yml      | darwin   |
      | c1f7e75b-3aba-4bba-a0b0-d3fbe8cf7750 | latest.yml | yml      | darwin   |
      | 61992b58-c283-4c56-95d7-d83ff52bc0f4 | latest.yml | yml      | darwin   |
      | 873c088e-8d32-4d5d-afd4-11a28c58b9bc | latest.yml | yml      | darwin   |
      | 4d2737af-0c5a-4c55-a31a-e8781261cbd5 | latest.yml | yml      | darwin   |
      | e8d06fe3-ac5f-44af-a88d-bebb2d322947 | latest.yml | yml      | darwin   |
      | f761080b-92fe-423a-a8b6-68f91d55a08a | latest.yml | yml      | darwin   |
      | 8d1eb3ce-fb23-41a9-b66c-6328b2fde235 | latest.yml | yml      | darwin   |
      | f287e696-27cb-4d2b-978a-d6cca2d386c2 | latest.yml | yml      | darwin   |
      | da38f541-0f22-4340-a7b5-4f7c410ded88 | latest.yml | yml      | darwin   |
      | 88d9bba0-726b-4695-aee2-28c86ff689c4 | latest.yml | yml      | darwin   |
      | 8147443c-fe47-4654-9935-80a29b490905 | latest.yml | yml      | darwin   |
      | 697107b8-01fb-4c05-9c95-0399e2fab5f7 | latest.yml | yml      | darwin   |
      | 1849d528-e552-4def-91cb-4020a9ec995e | latest.yml | yml      | darwin   |
      | 46da3538-89d1-4bcf-a478-25109a40eae5 | latest.yml | yml      | darwin   |
      | 01947f94-f574-4b71-aa4f-7a5b9101a092 | latest.yml | yml      | darwin   |
      | 5f187a7d-8ab8-4a9c-85f6-9bc0331f09b4 | latest.yml | yml      | darwin   |
      | 04fc4e72-beaa-4a6f-92d7-168a0c4e924c | latest.yml | yml      | darwin   |
      | c2b11198-de3d-4c7c-8dd8-e3fe86650e6b | latest.yml | yml      | darwin   |
      | 14496b66-0004-422f-87e9-15172287bae4 | latest.yml | yml      | darwin   |
      | 7da7b744-1c60-441f-967d-68134c93c2d9 | latest.yml | yml      | darwin   |
      | 84fe5dbf-6e41-458e-821b-d716487fbd12 | latest.yml | yml      | darwin   |
      | 33046ea9-2a77-46c3-b650-7b3b4bbae016 | latest.yml | yml      | darwin   |
      | aa067117-948f-46e8-977f-6998ad366a97 | latest.yml | yml      | darwin   |
      | fffa0764-3a19-48ea-beb3-8950563c7357 | latest.yml | yml      | darwin   |
      | 165d5389-e535-4f36-9232-ed59c67375d1 | latest.yml | yml      | darwin   |
      | e4fa628e-593d-48bc-8e3e-5e4dda1f2c3a | latest.yml | yml      | darwin   |
      | fd10ab0c-c52a-412f-b34f-180eebd7325d | latest.yml | yml      | darwin   |
      | f98d8c17-5fad-4361-ad89-43b0c6f6fa00 | latest.yml | yml      | darwin   |
      | 077ca1f2-6125-4a77-bdf0-3161a0fc278e | latest.yml | yml      | darwin   |
      | 0a027f00-0860-4fa7-bd37-5900c8866818 | latest.yml | yml      | darwin   |
    And the current account has 1 "policy" for an existing "product"
    And the current account has 1 "license" for an existing "policy"
    And the current account has 1 "artifact" for the last "release"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/artifacts/latest.yml?channel=beta"
    Then the response status should be "303"
    And the response body should be an "artifact" with the following relationships:
      """
      {
        "release": {
          "data": {
            "type": "releases",
            "id": "f98d8c17-5fad-4361-ad89-43b0c6f6fa00"
          },
          "links": {
            "related": "/v1/accounts/$account/releases/f98d8c17-5fad-4361-ad89-43b0c6f6fa00"
          }
        }
      }
      """
    And the response body should be an "artifact" with the following attributes:
      """
      { "filename": "latest.yml" }
      """

  Scenario: License retrieves the latest artifact by filename (alpha channel)
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
      | release_id                           | filename   | filetype | platform |
      | f53f57cb-dc3f-4b18-9d90-534038214b49 | latest.yml | yml      | darwin   |
      | 80e20324-c578-4763-bbef-c9698bf0023a | latest.yml | yml      | darwin   |
      | d34846b1-fdfe-46aa-9194-7d1a08e2d0cb | latest.yml | yml      | darwin   |
      | f517903b-5126-4405-9793-bf95a287b1f9 | latest.yml | yml      | darwin   |
      | 21088509-2dfc-4459-a8a2-3204136ad1df | latest.yml | yml      | darwin   |
      | 0fd7f4a3-dd48-40bc-8f1c-d4449432f8fb | latest.yml | yml      | darwin   |
      | eb4d5801-5238-4825-9236-50769fce5d2f | latest.yml | yml      | darwin   |
      | 298eac03-7caf-4225-8554-181920d70d75 | latest.yml | yml      | darwin   |
      | 4e41ac33-79ea-4dc3-b179-87d0174aaed4 | latest.yml | yml      | darwin   |
      | c1f7e75b-3aba-4bba-a0b0-d3fbe8cf7750 | latest.yml | yml      | darwin   |
      | 61992b58-c283-4c56-95d7-d83ff52bc0f4 | latest.yml | yml      | darwin   |
      | 873c088e-8d32-4d5d-afd4-11a28c58b9bc | latest.yml | yml      | darwin   |
      | 4d2737af-0c5a-4c55-a31a-e8781261cbd5 | latest.yml | yml      | darwin   |
      | e8d06fe3-ac5f-44af-a88d-bebb2d322947 | latest.yml | yml      | darwin   |
      | f761080b-92fe-423a-a8b6-68f91d55a08a | latest.yml | yml      | darwin   |
      | 8d1eb3ce-fb23-41a9-b66c-6328b2fde235 | latest.yml | yml      | darwin   |
      | f287e696-27cb-4d2b-978a-d6cca2d386c2 | latest.yml | yml      | darwin   |
      | da38f541-0f22-4340-a7b5-4f7c410ded88 | latest.yml | yml      | darwin   |
      | 88d9bba0-726b-4695-aee2-28c86ff689c4 | latest.yml | yml      | darwin   |
      | 8147443c-fe47-4654-9935-80a29b490905 | latest.yml | yml      | darwin   |
      | 697107b8-01fb-4c05-9c95-0399e2fab5f7 | latest.yml | yml      | darwin   |
      | 1849d528-e552-4def-91cb-4020a9ec995e | latest.yml | yml      | darwin   |
      | 46da3538-89d1-4bcf-a478-25109a40eae5 | latest.yml | yml      | darwin   |
      | 01947f94-f574-4b71-aa4f-7a5b9101a092 | latest.yml | yml      | darwin   |
      | 5f187a7d-8ab8-4a9c-85f6-9bc0331f09b4 | latest.yml | yml      | darwin   |
      | 04fc4e72-beaa-4a6f-92d7-168a0c4e924c | latest.yml | yml      | darwin   |
      | c2b11198-de3d-4c7c-8dd8-e3fe86650e6b | latest.yml | yml      | darwin   |
      | 14496b66-0004-422f-87e9-15172287bae4 | latest.yml | yml      | darwin   |
      | 7da7b744-1c60-441f-967d-68134c93c2d9 | latest.yml | yml      | darwin   |
      | 84fe5dbf-6e41-458e-821b-d716487fbd12 | latest.yml | yml      | darwin   |
      | 33046ea9-2a77-46c3-b650-7b3b4bbae016 | latest.yml | yml      | darwin   |
      | aa067117-948f-46e8-977f-6998ad366a97 | latest.yml | yml      | darwin   |
      | fffa0764-3a19-48ea-beb3-8950563c7357 | latest.yml | yml      | darwin   |
      | 165d5389-e535-4f36-9232-ed59c67375d1 | latest.yml | yml      | darwin   |
      | e4fa628e-593d-48bc-8e3e-5e4dda1f2c3a | latest.yml | yml      | darwin   |
      | fd10ab0c-c52a-412f-b34f-180eebd7325d | latest.yml | yml      | darwin   |
      | f98d8c17-5fad-4361-ad89-43b0c6f6fa00 | latest.yml | yml      | darwin   |
      | 077ca1f2-6125-4a77-bdf0-3161a0fc278e | latest.yml | yml      | darwin   |
      | 0a027f00-0860-4fa7-bd37-5900c8866818 | latest.yml | yml      | darwin   |
    And the current account has 1 "policy" for an existing "product"
    And the current account has 1 "license" for an existing "policy"
    And the current account has 1 "artifact" for the last "release"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/artifacts/latest.yml?channel=alpha"
    Then the response status should be "303"
    And the response body should be an "artifact" with the following relationships:
      """
      {
        "release": {
          "data": {
            "type": "releases",
            "id": "077ca1f2-6125-4a77-bdf0-3161a0fc278e"
          },
          "links": {
            "related": "/v1/accounts/$account/releases/077ca1f2-6125-4a77-bdf0-3161a0fc278e"
          }
        }
      }
      """
    And the response body should be an "artifact" with the following attributes:
      """
      { "filename": "latest.yml" }
      """

    Scenario: License retrieves an artifact by filename (dev channel)
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
      | release_id                           | filename   | filetype | platform |
      | f53f57cb-dc3f-4b18-9d90-534038214b49 | latest.yml | yml      | darwin   |
      | 80e20324-c578-4763-bbef-c9698bf0023a | latest.yml | yml      | darwin   |
      | d34846b1-fdfe-46aa-9194-7d1a08e2d0cb | latest.yml | yml      | darwin   |
      | f517903b-5126-4405-9793-bf95a287b1f9 | latest.yml | yml      | darwin   |
      | 21088509-2dfc-4459-a8a2-3204136ad1df | latest.yml | yml      | darwin   |
      | 0fd7f4a3-dd48-40bc-8f1c-d4449432f8fb | latest.yml | yml      | darwin   |
      | eb4d5801-5238-4825-9236-50769fce5d2f | latest.yml | yml      | darwin   |
      | 298eac03-7caf-4225-8554-181920d70d75 | latest.yml | yml      | darwin   |
      | 4e41ac33-79ea-4dc3-b179-87d0174aaed4 | latest.yml | yml      | darwin   |
      | c1f7e75b-3aba-4bba-a0b0-d3fbe8cf7750 | latest.yml | yml      | darwin   |
      | 61992b58-c283-4c56-95d7-d83ff52bc0f4 | latest.yml | yml      | darwin   |
      | 873c088e-8d32-4d5d-afd4-11a28c58b9bc | latest.yml | yml      | darwin   |
      | 4d2737af-0c5a-4c55-a31a-e8781261cbd5 | latest.yml | yml      | darwin   |
      | e8d06fe3-ac5f-44af-a88d-bebb2d322947 | latest.yml | yml      | darwin   |
      | f761080b-92fe-423a-a8b6-68f91d55a08a | latest.yml | yml      | darwin   |
      | 8d1eb3ce-fb23-41a9-b66c-6328b2fde235 | latest.yml | yml      | darwin   |
      | f287e696-27cb-4d2b-978a-d6cca2d386c2 | latest.yml | yml      | darwin   |
      | da38f541-0f22-4340-a7b5-4f7c410ded88 | latest.yml | yml      | darwin   |
      | 88d9bba0-726b-4695-aee2-28c86ff689c4 | latest.yml | yml      | darwin   |
      | 8147443c-fe47-4654-9935-80a29b490905 | latest.yml | yml      | darwin   |
      | 697107b8-01fb-4c05-9c95-0399e2fab5f7 | latest.yml | yml      | darwin   |
      | 1849d528-e552-4def-91cb-4020a9ec995e | latest.yml | yml      | darwin   |
      | 46da3538-89d1-4bcf-a478-25109a40eae5 | latest.yml | yml      | darwin   |
      | 01947f94-f574-4b71-aa4f-7a5b9101a092 | latest.yml | yml      | darwin   |
      | 5f187a7d-8ab8-4a9c-85f6-9bc0331f09b4 | latest.yml | yml      | darwin   |
      | 04fc4e72-beaa-4a6f-92d7-168a0c4e924c | latest.yml | yml      | darwin   |
      | c2b11198-de3d-4c7c-8dd8-e3fe86650e6b | latest.yml | yml      | darwin   |
      | 14496b66-0004-422f-87e9-15172287bae4 | latest.yml | yml      | darwin   |
      | 7da7b744-1c60-441f-967d-68134c93c2d9 | latest.yml | yml      | darwin   |
      | 84fe5dbf-6e41-458e-821b-d716487fbd12 | latest.yml | yml      | darwin   |
      | 33046ea9-2a77-46c3-b650-7b3b4bbae016 | latest.yml | yml      | darwin   |
      | aa067117-948f-46e8-977f-6998ad366a97 | latest.yml | yml      | darwin   |
      | fffa0764-3a19-48ea-beb3-8950563c7357 | latest.yml | yml      | darwin   |
      | 165d5389-e535-4f36-9232-ed59c67375d1 | latest.yml | yml      | darwin   |
      | e4fa628e-593d-48bc-8e3e-5e4dda1f2c3a | latest.yml | yml      | darwin   |
      | fd10ab0c-c52a-412f-b34f-180eebd7325d | latest.yml | yml      | darwin   |
      | f98d8c17-5fad-4361-ad89-43b0c6f6fa00 | latest.yml | yml      | darwin   |
      | 077ca1f2-6125-4a77-bdf0-3161a0fc278e | latest.yml | yml      | darwin   |
      | 0a027f00-0860-4fa7-bd37-5900c8866818 | latest.yml | yml      | darwin   |
    And the current account has 1 "policy" for an existing "product"
    And the current account has 1 "license" for an existing "policy"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/artifacts/latest.yml?channel=dev"
    Then the response status should be "303"
    And the response body should be an "artifact" with the following relationships:
      """
      {
        "release": {
          "data": {
            "type": "releases",
            "id": "0a027f00-0860-4fa7-bd37-5900c8866818"
          },
          "links": {
            "related": "/v1/accounts/$account/releases/0a027f00-0860-4fa7-bd37-5900c8866818"
          }
        }
      }
      """
    And the response body should be an "artifact" with the following attributes:
      """
      { "filename": "latest.yml" }
      """

  Scenario: License retrieves an artifact by filename (no prefix)
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name   |
      | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | Test 1 |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | version | channel |
      | f14ef993-f821-44c9-b2af-62e27f37f8db | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | 1.0.0   | stable  |
    And the current account has the following "artifact" rows:
      | release_id                           | filename              | filetype | platform |
      | f14ef993-f821-44c9-b2af-62e27f37f8db | Test-App-1.0.0.dmg    | dmg      | macos    |
      | f14ef993-f821-44c9-b2af-62e27f37f8db | Test-App-1.0.0.zip    | zip      | win32    |
      | f14ef993-f821-44c9-b2af-62e27f37f8db | Test-App.1.0.0.tar.gz | tar.gz   | linux    |
    And the current account has 1 "policy" for an existing "product"
    And the current account has 1 "license" for an existing "policy"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/artifacts/Test-App-1.0.0.dmg"
    Then the response status should be "303"

  Scenario: License retrieves an artifact by filename (not stable)
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name   |
      | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | Test 1 |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | version    | channel |
      | f14ef993-f821-44c9-b2af-62e27f37f8db | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | 1.0.0-beta | beta    |
    And the current account has the following "artifact" rows:
      | release_id                           | filename              | filetype | platform |
      | f14ef993-f821-44c9-b2af-62e27f37f8db | Test-App-1.0.0.dmg    | dmg      | macos    |
      | f14ef993-f821-44c9-b2af-62e27f37f8db | Test-App-1.0.0.zip    | zip      | win32    |
      | f14ef993-f821-44c9-b2af-62e27f37f8db | Test-App.1.0.0.tar.gz | tar.gz   | linux    |
    And the current account has 1 "policy" for an existing "product"
    And the current account has 1 "license" for an existing "policy"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/artifacts/Test-App-1.0.0.dmg?channel=stable"
    Then the response status should be "404"

  Scenario: License retrieves an artifact by filename (with prefix, uploaded)
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name   |
      | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | Test 1 |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | version | channel |
      | f14ef993-f821-44c9-b2af-62e27f37f8db | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | 1.0.0   | stable  |
    And the current account has the following "artifact" rows:
      | release_id                           | filename                  | filetype | platform | status   |
      | f14ef993-f821-44c9-b2af-62e27f37f8db | dir/Test-App-1.0.0.dmg    | dmg      | macos    | UPLOADED |
      | f14ef993-f821-44c9-b2af-62e27f37f8db | dir/Test-App-1.0.0.zip    | zip      | win32    | UPLOADED |
      | f14ef993-f821-44c9-b2af-62e27f37f8db | dir/Test-App.1.0.0.tar.gz | tar.gz   | linux    | UPLOADED |
    And the current account has 1 "policy" for an existing "product"
    And the current account has 1 "license" for an existing "policy"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/artifacts/dir/Test-App.1.0.0.tar.gz"
    Then the response status should be "303"

  Scenario: License retrieves an artifact by filename (not uploaded)
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name   |
      | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | Test 1 |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | version | channel |
      | f14ef993-f821-44c9-b2af-62e27f37f8db | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | 1.0.0   | stable  |
    And the current account has the following "artifact" rows:
      | release_id                           | filename                  | filetype | platform | status  |
      | f14ef993-f821-44c9-b2af-62e27f37f8db | dir/Test-App-1.0.0.zip    | zip      | win32    | WAITING |
    And the current account has 1 "policy" for an existing "product"
    And the current account has 1 "license" for an existing "policy"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/artifacts/dir/Test-App-1.0.0.zip"
    Then the response status should be "404"

  Scenario: License retrieves an artifact by filename (yanked)
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name   |
      | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | Test 1 |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | version | channel | status |
      | f14ef993-f821-44c9-b2af-62e27f37f8db | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | 1.0.0   | stable  | YANKED |
    And the current account has the following "artifact" rows:
      | release_id                           | filename                  | filetype | platform | status  |
      | f14ef993-f821-44c9-b2af-62e27f37f8db | dir/Test-App-1.0.0.zip    | zip      | win32    | UPLOADED |
    And the current account has 1 "policy" for an existing "product"
    And the current account has 1 "license" for an existing "policy"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/artifacts/dir/Test-App-1.0.0.zip"
    Then the response status should be "404"

  Scenario: License retrieves an artifact by filename that does not exist
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name   |
      | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | Test 1 |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | version | channel |
      | f14ef993-f821-44c9-b2af-62e27f37f8db | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | 1.0.0   | stable  |
    And the current account has the following "artifact" rows:
      | release_id                           | filename                  | filetype | platform |
      | f14ef993-f821-44c9-b2af-62e27f37f8db | dir/Test-App-1.0.0.zip    | zip      | win32    |
    And the current account has 1 "policy" for an existing "product"
    And the current account has 1 "license" for an existing "policy"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/artifacts/dir/Test-App-2.0.0.zip"
    Then the response status should be "404"

  Scenario: License retrieves an artifact with a conflicting filename (open/licensed)
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name         | distribution_strategy |
      | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | Freemium App | OPEN                  |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Premium App  | LICENSED              |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | version | channel |
      | f14ef993-f821-44c9-b2af-62e27f37f8db | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | 2.0.0   | stable  |
      | aa067117-948f-46e8-977f-6998ad366a97 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0   | stable  |
    And the current account has the following "artifact" rows:
      | release_id                           | filename   | filetype | platform |
      | f14ef993-f821-44c9-b2af-62e27f37f8db | stable.yml | yml      | darwin   |
      | aa067117-948f-46e8-977f-6998ad366a97 | stable.yml | yml      | darwin   |
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "license" for the last "policy"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/artifacts/stable.yml"
    Then the response status should be "303"
    And the response body should be an "artifact" with the following relationships:
      """
      {
        "release": {
          "data": {
            "type": "releases",
            "id": "f14ef993-f821-44c9-b2af-62e27f37f8db"
          },
          "links": {
            "related": "/v1/accounts/$account/releases/f14ef993-f821-44c9-b2af-62e27f37f8db"
          }
        }
      }
      """
    And the response body should be an "artifact" with the following attributes:
      """
      { "filename": "stable.yml" }
      """

  Scenario: License retrieves an artifact with a conflicting filename (open/licensed, with product qualifier)
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name         | distribution_strategy |
      | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | Freemium App | OPEN                  |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Premium App  | LICENSED              |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | version | channel |
      | f14ef993-f821-44c9-b2af-62e27f37f8db | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | 2.0.0   | stable  |
      | aa067117-948f-46e8-977f-6998ad366a97 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0   | stable  |
    And the current account has the following "artifact" rows:
      | release_id                           | filename   | filetype | platform |
      | f14ef993-f821-44c9-b2af-62e27f37f8db | stable.yml | yml      | darwin   |
      | aa067117-948f-46e8-977f-6998ad366a97 | stable.yml | yml      | darwin   |
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "license" for the last "policy"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/artifacts/stable.yml?product=6198261a-48b5-4445-a045-9fed4afc7735"
    Then the response status should be "303"
    And the response body should be an "artifact" with the following relationships:
      """
      {
        "release": {
          "data": {
            "type": "releases",
            "id": "aa067117-948f-46e8-977f-6998ad366a97"
          },
          "links": {
            "related": "/v1/accounts/$account/releases/aa067117-948f-46e8-977f-6998ad366a97"
          }
        }
      }
      """
    And the response body should be an "artifact" with the following attributes:
      """
      { "filename": "stable.yml" }
      """

  Scenario: Anonymous retrieves an artifact with a conflicting filename (open/open)
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name  | distribution_strategy |
      | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | App 1 | OPEN                  |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | App 2 | OPEN                  |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | version | channel |
      | f14ef993-f821-44c9-b2af-62e27f37f8db | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | 2.0.0   | stable  |
      | aa067117-948f-46e8-977f-6998ad366a97 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0   | stable  |
    And the current account has the following "artifact" rows:
      | release_id                           | filename   | filetype | platform |
      | f14ef993-f821-44c9-b2af-62e27f37f8db | stable.yml | yml      | darwin   |
      | aa067117-948f-46e8-977f-6998ad366a97 | stable.yml | yml      | darwin   |
    When I send a GET request to "/accounts/test1/artifacts/stable.yml"
    Then the response status should be "303"
    And the response body should be an "artifact" with the following relationships:
      """
      {
        "release": {
          "data": {
            "type": "releases",
            "id": "f14ef993-f821-44c9-b2af-62e27f37f8db"
          },
          "links": {
            "related": "/v1/accounts/$account/releases/f14ef993-f821-44c9-b2af-62e27f37f8db"
          }
        }
      }
      """
    And the response body should be an "artifact" with the following attributes:
      """
      { "filename": "stable.yml" }
      """

  Scenario: Anonymous retrieves an artifact with a conflicting filename (open/open, with product qualifier)
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name  | distribution_strategy |
      | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | App 1 | OPEN                  |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | App 2 | OPEN                  |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | version | channel |
      | f14ef993-f821-44c9-b2af-62e27f37f8db | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | 2.0.0   | stable  |
      | aa067117-948f-46e8-977f-6998ad366a97 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0   | stable  |
    And the current account has the following "artifact" rows:
      | release_id                           | filename   | filetype | platform |
      | f14ef993-f821-44c9-b2af-62e27f37f8db | stable.yml | yml      | darwin   |
      | aa067117-948f-46e8-977f-6998ad366a97 | stable.yml | yml      | darwin   |
    When I send a GET request to "/accounts/test1/artifacts/stable.yml?product=6198261a-48b5-4445-a045-9fed4afc7735"
    Then the response status should be "303"
    And the response body should be an "artifact" with the following relationships:
      """
      {
        "release": {
          "data": {
            "type": "releases",
            "id": "aa067117-948f-46e8-977f-6998ad366a97"
          },
          "links": {
            "related": "/v1/accounts/$account/releases/aa067117-948f-46e8-977f-6998ad366a97"
          }
        }
      }
      """
    And the response body should be an "artifact" with the following attributes:
      """
      { "filename": "stable.yml" }
      """

  # Licensed distribution strategy
  Scenario: Anonymous retrieves an artifact for a LICENSED release
    Given the current account is "test1"
    And the current account has 1 "product"
    And the last "product" has the following attributes:
      """
      { "distributionStrategy": "LICENSED" }
      """
    And the current account has 1 "release" for the last "product"
    And the current account has 1 "artifact" for the last "release"
    When I send a GET request to "/accounts/test1/artifacts/$0"
    Then the response status should be "404"

  Scenario: License retrieves an artifact for a LICENSED release without a license for it
    Given the current account is "test1"
    And the current account has 1 "product"
    And the last "product" has the following attributes:
      """
      { "distributionStrategy": "LICENSED" }
      """
    And the current account has 1 "release" for the last "product"
    And the current account has 1 "artifact" for the last "release"
    And the current account has 1 "license"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/artifacts/$0"
    Then the response status should be "404"

  Scenario: License retrieves an artifact for a LICENSED release with a license for it
    Given the current account is "test1"
    And the current account has 1 "product"
    And the last "product" has the following attributes:
      """
      { "distributionStrategy": "LICENSED" }
      """
    And the current account has 1 "release" for the last "product"
    And the current account has 1 "artifact" for the last "release"
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "license" for the last "policy"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/artifacts/$0"
    Then the response status should be "303"

  Scenario: License retrieves an artifact for a LICENSED release with an expired license for it (restrict access)
    Given the current account is "test1"
    And the current account has 1 "product"
    And the last "product" has the following attributes:
      """
      { "distributionStrategy": "LICENSED" }
      """
    And the current account has 1 "release" for the last "product"
    And the current account has 1 "artifact" for the last "release"
    And the current account has 1 "policy" for the last "product"
    And the last "policy" has the following attributes:
      """
      { "expirationStrategy": "RESTRICT_ACCESS" }
      """
    And the current account has 1 "license" for the last "policy"
    And the last "license" has the following attributes:
      """
      { "expiry": "$time.2.months.ago" }
      """
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/artifacts/$0"
    Then the response status should be "403"
    And the first error should have the following properties:
      """
      {
        "title": "Access denied",
        "detail": "You do not have permission to complete the request (license expiry falls outside of access window)"
      }
      """

  Scenario: License retrieves an artifact for a LICENSED release with an expired license for it (revoke access)
    Given the current account is "test1"
    And the current account has 1 "product"
    And the last "product" has the following attributes:
      """
      { "distributionStrategy": "LICENSED" }
      """
    And the current account has 1 "release" for the last "product"
    And the current account has 1 "artifact" for the last "release"
    And the current account has 1 "policy" for the last "product"
    And the last "policy" has the following attributes:
      """
      { "expirationStrategy": "REVOKE_ACCESS" }
      """
    And the current account has 1 "license" for the last "policy"
    And the last "license" has the following attributes:
      """
      { "expiry": "$time.2.months.ago" }
      """
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/artifacts/$0"
    Then the response status should be "403"
    And the first error should have the following properties:
      """
      {
        "title": "Access denied",
        "detail": "You do not have permission to complete the request (license is expired)"
      }
      """

  Scenario: License retrieves an artifact for a LICENSED release with an expired license for it (expired before release, maintain access)
    Given the current account is "test1"
    And the current account has 1 "product"
    And the last "product" has the following attributes:
      """
      { "distributionStrategy": "LICENSED" }
      """
    And the current account has 1 "release" for the last "product"
    And the current account has 1 "artifact" for the last "release"
    And the current account has 1 "policy" for the last "product"
    And the last "policy" has the following attributes:
      """
      { "expirationStrategy": "MAINTAIN_ACCESS" }
      """
    And the current account has 1 "license" for the last "policy"
    And the last "license" has the following attributes:
      """
      { "expiry": "$time.2.months.ago" }
      """
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/artifacts/$0"
    Then the response status should be "403"
    And the first error should have the following properties:
      """
      {
        "title": "Access denied",
        "detail": "You do not have permission to complete the request (license expiry falls outside of access window)"
      }
      """

  Scenario: License retrieves an artifact for a LICENSED release with an expired license for it (expired after release, maintain access)
    Given the current account is "test1"
    And the current account has 1 "product"
    And the last "product" has the following attributes:
      """
      { "distributionStrategy": "LICENSED" }
      """
    And the current account has 1 "release" for the last "product"
    And the current account has 1 "artifact" for the last "release"
    And the current account has 1 "policy" for the last "product"
    And the last "policy" has the following attributes:
      """
      { "expirationStrategy": "MAINTAIN_ACCESS" }
      """
    And the current account has 1 "license" for the last "policy"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/artifacts/$0"
    Then the response status should be "303"

  Scenario: License retrieves an artifact for a LICENSED release with an expired license for it (allow access)
    Given the current account is "test1"
    And the current account has 1 "product"
    And the last "product" has the following attributes:
      """
      { "distributionStrategy": "LICENSED" }
      """
    And the current account has 1 "release" for the last "product"
    And the current account has 1 "artifact" for the last "release"
    And the current account has 1 "policy" for the last "product"
    And the last "policy" has the following attributes:
      """
      { "expirationStrategy": "ALLOW_ACCESS" }
      """
    And the current account has 1 "license" for the last "policy"
    And the last "license" has the following attributes:
      """
      { "expiry": "$time.2.months.ago" }
      """
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/artifacts/$0"
    Then the response status should be "303"

  Scenario: User retrieves an artifact for a LICENSED release without a license for it
    Given the current account is "test1"
    And the current account has 1 "product"
    And the last "product" has the following attributes:
      """
      { "distributionStrategy": "LICENSED" }
      """
    And the current account has 1 "release" for the last "product"
    And the current account has 1 "artifact" for the last "release"
    And the current account has 1 "license"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    And the current user has 1 "license"
    When I send a GET request to "/accounts/test1/artifacts/$0"
    Then the response status should be "404"

  Scenario: User retrieves an artifact for a LICENSED release with a license for it
    Given the current account is "test1"
    And the current account has 1 "product"
    And the last "product" has the following attributes:
      """
      { "distributionStrategy": "LICENSED" }
      """
    And the current account has 1 "release" for the last "product"
    And the current account has 1 "artifact" for the last "release"
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "license" for the last "policy"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    And the current user has 1 "license"
    When I send a GET request to "/accounts/test1/artifacts/$0"
    Then the response status should be "303"

  Scenario: Product retrieves an artifact for a LICENSED release
    Given the current account is "test1"
    And the current account has 1 "product"
    And the last "product" has the following attributes:
      """
      { "distributionStrategy": "LICENSED" }
      """
    And the current account has 1 "release" for the last "product"
    And the current account has 1 "artifact" for the last "release"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/artifacts/$0"
    Then the response status should be "303"

  Scenario: Product retrieves an artifact for a LICENSED release of another product
    Given the current account is "test1"
    And the current account has 2 "products"
    And the second "product" has the following attributes:
      """
      { "distributionStrategy": "LICENSED" }
      """
    And the current account has 1 "release" for the second "product"
    And the current account has 1 "artifact" for the last "release"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/artifacts/$0"
    Then the response status should be "404"

  Scenario: Admin retrieves an artifact for a LICENSED release
    Given the current account is "test1"
    And the current account has 1 "product"
    And the last "product" has the following attributes:
      """
      { "distributionStrategy": "LICENSED" }
      """
    And the current account has 1 "release" for the last "product"
    And the current account has 1 "artifact" for the last "release"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/artifacts/$0"
    Then the response status should be "303"

  # Open distribution strategy
  Scenario: Anonymous retrieves an artifact for an OPEN release
    Given the current account is "test1"
    And the current account has 1 "product"
    And the last "product" has the following attributes:
      """
      { "distributionStrategy": "OPEN" }
      """
    And the current account has 1 "release" for the last "product"
    And the current account has 1 "artifact" for the last "release"
    When I send a GET request to "/accounts/test1/artifacts/$0"
    Then the response status should be "303"

  Scenario: License retrieves an artifact for an OPEN release without a license for it
    Given the current account is "test1"
    And the current account has 1 "product"
    And the last "product" has the following attributes:
      """
      { "distributionStrategy": "OPEN" }
      """
    And the current account has 1 "release" for the last "product"
    And the current account has 1 "artifact" for the last "release"
    And the current account has 1 "license"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/artifacts/$0"
    Then the response status should be "303"

  Scenario: License retrieves an artifact for an OPEN release with a license for it
    Given the current account is "test1"
    And the current account has 1 "product"
    And the last "product" has the following attributes:
      """
      { "distributionStrategy": "OPEN" }
      """
    And the current account has 1 "release" for the last "product"
    And the current account has 1 "artifact" for the last "release"
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "license" for the last "policy"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/artifacts/$0"
    Then the response status should be "303"

  Scenario: License retrieves an artifact for an OPEN release with an expired license for it
    Given the current account is "test1"
    And the current account has 1 "product"
    And the last "product" has the following attributes:
      """
      { "distributionStrategy": "OPEN" }
      """
    And the current account has 1 "release" for the last "product"
    And the current account has 1 "artifact" for the last "release"
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "license" for the last "policy"
    And the last "license" has the following attributes:
      """
      { "expiry": "$time.2.months.ago" }
      """
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/artifacts/$0"
    Then the response status should be "303"

  Scenario: User retrieves an artifact for an OPEN release without a license for it
    Given the current account is "test1"
    And the current account has 1 "product"
    And the last "product" has the following attributes:
      """
      { "distributionStrategy": "OPEN" }
      """
    And the current account has 1 "release" for the last "product"
    And the current account has 1 "artifact" for the last "release"
    And the current account has 1 "license"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    And the current user has 1 "license"
    When I send a GET request to "/accounts/test1/artifacts/$0"
    Then the response status should be "303"

  Scenario: User retrieves an artifact for an OPEN release with a license for it
    Given the current account is "test1"
    And the current account has 1 "product"
    And the last "product" has the following attributes:
      """
      { "distributionStrategy": "OPEN" }
      """
    And the current account has 1 "release" for the last "product"
    And the current account has 1 "artifact" for the last "release"
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "license" for the last "policy"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    And the current user has 1 "license"
    When I send a GET request to "/accounts/test1/artifacts/$0"
    Then the response status should be "303"

  Scenario: Product retrieves an artifact for an OPEN release
    Given the current account is "test1"
    And the current account has 1 "product"
    And the last "product" has the following attributes:
      """
      { "distributionStrategy": "OPEN" }
      """
    And the current account has 1 "release" for the last "product"
    And the current account has 1 "artifact" for the last "release"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/artifacts/$0"
    Then the response status should be "303"

  Scenario: Product retrieves an artifact for an OPEN release of another product
    Given the current account is "test1"
    And the current account has 2 "products"
    And the second "product" has the following attributes:
      """
      { "distributionStrategy": "OPEN" }
      """
    And the current account has 1 "release" for the second "product"
    And the current account has 1 "artifact" for the last "release"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/artifacts/$0"
    Then the response status should be "404"

  Scenario: Admin retrieves an artifact for an OPEN release
    Given the current account is "test1"
    And the current account has 1 "product"
    And the last "product" has the following attributes:
      """
      { "distributionStrategy": "OPEN" }
      """
    And the current account has 1 "release" for the last "product"
    And the current account has 1 "artifact" for the last "release"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/artifacts/$0"
    Then the response status should be "303"

  # Closed distribution strategy
  Scenario: Anonymous retrieves an artifact for a CLOSED release
    Given the current account is "test1"
    And the current account has 1 "product"
    And the last "product" has the following attributes:
      """
      { "distributionStrategy": "CLOSED" }
      """
    And the current account has 1 "release" for the last "product"
    And the current account has 1 "artifact" for the last "release"
    When I send a GET request to "/accounts/test1/artifacts/$0"
    Then the response status should be "404"

  Scenario: License retrieves an artifact for a CLOSED release without a license for it
    Given the current account is "test1"
    And the current account has 1 "product"
    And the last "product" has the following attributes:
      """
      { "distributionStrategy": "CLOSED" }
      """
    And the current account has 1 "release" for the last "product"
    And the current account has 1 "artifact" for the last "release"
    And the current account has 1 "license"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/artifacts/$0"
    Then the response status should be "404"

  Scenario: License retrieves an artifact for a CLOSED release with a license for it
    Given the current account is "test1"
    And the current account has 1 "product"
    And the last "product" has the following attributes:
      """
      { "distributionStrategy": "CLOSED" }
      """
    And the current account has 1 "release" for the last "product"
    And the current account has 1 "artifact" for the last "release"
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "license" for the last "policy"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/artifacts/$0"
    Then the response status should be "404"

  Scenario: User retrieves an artifact for a CLOSED release without a license for it
    Given the current account is "test1"
    And the current account has 1 "product"
    And the last "product" has the following attributes:
      """
      { "distributionStrategy": "CLOSED" }
      """
    And the current account has 1 "release" for the last "product"
    And the current account has 1 "artifact" for the last "release"
    And the current account has 1 "license"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    And the current user has 1 "license"
    When I send a GET request to "/accounts/test1/artifacts/$0"
    Then the response status should be "404"

  Scenario: User retrieves an artifact for a CLOSED release with a license for it
    Given the current account is "test1"
    And the current account has 1 "product"
    And the last "product" has the following attributes:
      """
      { "distributionStrategy": "CLOSED" }
      """
    And the current account has 1 "release" for the last "product"
    And the current account has 1 "artifact" for the last "release"
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "license" for the last "policy"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    And the current user has 1 "license"
    When I send a GET request to "/accounts/test1/artifacts/$0"
    Then the response status should be "404"

  Scenario: Product retrieves an artifact for a CLOSED release
    Given the current account is "test1"
    And the current account has 1 "product"
    And the last "product" has the following attributes:
      """
      { "distributionStrategy": "CLOSED" }
      """
    And the current account has 1 "release" for the last "product"
    And the current account has 1 "artifact" for the last "release"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/artifacts/$0"
    Then the response status should be "303"

  Scenario: Product retrieves an artifact for a CLOSED release of another product
    Given the current account is "test1"
    And the current account has 2 "products"
    And the second "product" has the following attributes:
      """
      { "distributionStrategy": "CLOSED" }
      """
    And the current account has 1 "release" for the second "product"
    And the current account has 1 "artifact" for the last "release"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/artifacts/$0"
    Then the response status should be "404"

  Scenario: Admin retrieves an artifact for a CLOSED release
    Given the current account is "test1"
    And the current account has 1 "product"
    And the last "product" has the following attributes:
      """
      { "distributionStrategy": "CLOSED" }
      """
    And the current account has 1 "release" for the last "product"
    And the current account has 1 "artifact" for the last "release"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/artifacts/$0"
    Then the response status should be "303"

  Scenario: Admin attempts to retrieve an artifact for another account
    Given I am an admin of account "test2"
    But the current account is "test1"
    And the current account has 3 "releases"
    And the current account has 1 "artifact" for each "release"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/artifacts/$0"
    Then the response status should be "401"
    And the response body should be an array of 1 error

  # Draft releases
  Scenario: Anonymous retrieves an artifact for a draft release
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 draft "release" for the last "product"
    And the current account has 1 "artifact" for the last "release"
    When I send a GET request to "/accounts/test1/artifacts/$0"
    Then the response status should be "404"

  Scenario: License retrieves an artifact for a draft release without a license for it
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 draft "release" for the last "product"
    And the current account has 1 "artifact" for the last "release"
    And the current account has 1 "license"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/artifacts/$0"
    Then the response status should be "404"

  Scenario: License retrieves an artifact for a draft release with a license for it
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 draft "release" for the last "product"
    And the current account has 1 "artifact" for the last "release"
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "license" for the last "policy"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/artifacts/$0"
    Then the response status should be "404"

  Scenario: User retrieves an artifact for a draft release without a license for it
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 draft "release" for the last "product"
    And the current account has 1 "artifact" for the last "release"
    And the current account has 1 "license"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    And the current user has 1 "license"
    When I send a GET request to "/accounts/test1/artifacts/$0"
    Then the response status should be "404"

  Scenario: User retrieves an artifact for a draft release with a license for it
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 draft "release" for the last "product"
    And the current account has 1 "artifact" for the last "release"
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "license" for the last "policy"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    And the current user has 1 "license"
    When I send a GET request to "/accounts/test1/artifacts/$0"
    Then the response status should be "404"

  Scenario: Product retrieves an artifact for a draft release
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 draft "release" for the last "product"
    And the current account has 1 "artifact" for the last "release"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/artifacts/$0"
    Then the response status should be "303"

  Scenario: Product retrieves an artifact for a draft release of another product
    Given the current account is "test1"
    And the current account has 2 "products"
    And the current account has 1 draft "release" for the second "product"
    And the current account has 1 "artifact" for the last "release"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/artifacts/$0"
    Then the response status should be "404"

  Scenario: Admin retrieves an artifact for a draft release
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 draft "release" for the last "product"
    And the current account has 1 "artifact" for the last "release"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/artifacts/$0"
    Then the response status should be "303"

  # Yanked releases
  Scenario: Anonymous retrieves an artifact for a yanked release
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 yanked "release" for the last "product"
    And the current account has 1 "artifact" for the last "release"
    When I send a GET request to "/accounts/test1/artifacts/$0"
    Then the response status should be "404"

  Scenario: License retrieves an artifact for a yanked release without a license for it
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 yanked "release" for the last "product"
    And the current account has 1 "artifact" for the last "release"
    And the current account has 1 "license"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/artifacts/$0"
    Then the response status should be "404"

  Scenario: License retrieves an artifact for a yanked release with a license for it
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 yanked "release" for the last "product"
    And the current account has 1 "artifact" for the last "release"
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "license" for the last "policy"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/artifacts/$0"
    Then the response status should be "404"

  Scenario: User retrieves an artifact for a yanked release without a license for it
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 yanked "release" for the last "product"
    And the current account has 1 "artifact" for the last "release"
    And the current account has 1 "license"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    And the current user has 1 "license"
    When I send a GET request to "/accounts/test1/artifacts/$0"
    Then the response status should be "404"

  Scenario: User retrieves an artifact for a yanked release with a license for it
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 yanked "release" for the last "product"
    And the current account has 1 "artifact" for the last "release"
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "license" for the last "policy"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    And the current user has 1 "license"
    When I send a GET request to "/accounts/test1/artifacts/$0"
    Then the response status should be "404"

  Scenario: Product retrieves an artifact for a yanked release
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 yanked "release" for the last "product"
    And the current account has 1 "artifact" for the last "release"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/artifacts/$0"
    Then the response status should be "200"

  Scenario: Product retrieves an artifact for a yanked release of another product
    Given the current account is "test1"
    And the current account has 2 "products"
    And the current account has 1 yanked "release" for the second "product"
    And the current account has 1 "artifact" for the last "release"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/artifacts/$0"
    Then the response status should be "404"

  Scenario: Admin retrieves an artifact for a yanked release
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 yanked "release" for the last "product"
    And the current account has 1 "artifact" for the last "release"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/artifacts/$0"
    Then the response status should be "200"

  # Waiting artifacts
  Scenario: Anonymous retrieves a waiting artifact
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "release" for the last "product"
    And the current account has 1 waiting "artifact" for the last "release"
    When I send a GET request to "/accounts/test1/artifacts/$0"
    Then the response status should be "404"

  Scenario: License retrieves a waiting artifact without a license for it
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "release" for the last "product"
    And the current account has 1 waiting "artifact" for the last "release"
    And the current account has 1 "license"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/artifacts/$0"
    Then the response status should be "404"

  Scenario: License retrieves a waiting artifact with a license for it
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "release" for the last "product"
    And the current account has 1 waiting "artifact" for the last "release"
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "license" for the last "policy"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/artifacts/$0"
    Then the response status should be "404"

  Scenario: User retrieves a waiting artifact without a license for it
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "release" for the last "product"
    And the current account has 1 waiting "artifact" for the last "release"
    And the current account has 1 "license"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    And the current user has 1 "license"
    When I send a GET request to "/accounts/test1/artifacts/$0"
    Then the response status should be "404"

  Scenario: User retrieves a waiting artifact with a license for it
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "release" for the last "product"
    And the current account has 1 waiting "artifact" for the last "release"
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "license" for the last "policy"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    And the current user has 1 "license"
    When I send a GET request to "/accounts/test1/artifacts/$0"
    Then the response status should be "404"

  Scenario: Product retrieves a waiting artifact
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "release" for the last "product"
    And the current account has 1 waiting "artifact" for the last "release"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/artifacts/$0"
    Then the response status should be "200"

  Scenario: Product retrieves a waiting artifact of another product
    Given the current account is "test1"
    And the current account has 2 "products"
    And the current account has 1 "release" for the second "product"
    And the current account has 1 waiting "artifact" for the last "release"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/artifacts/$0"
    Then the response status should be "404"

  Scenario: Admin retrieves a waiting artifact
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "release" for the last "product"
    And the current account has 1 waiting "artifact" for the last "release"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/artifacts/$0"
    Then the response status should be "200"

  # Failed artifacts
  Scenario: Anonymous retrieves a failed artifact
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "release" for the last "product"
    And the current account has 1 failed "artifact" for the last "release"
    When I send a GET request to "/accounts/test1/artifacts/$0"
    Then the response status should be "404"

  Scenario: License retrieves a failed artifact without a license for it
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "release" for the last "product"
    And the current account has 1 failed "artifact" for the last "release"
    And the current account has 1 "license"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/artifacts/$0"
    Then the response status should be "404"

  Scenario: License retrieves a failed artifact with a license for it
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "release" for the last "product"
    And the current account has 1 failed "artifact" for the last "release"
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "license" for the last "policy"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/artifacts/$0"
    Then the response status should be "404"

  Scenario: User retrieves a failed artifact without a license for it
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "release" for the last "product"
    And the current account has 1 failed "artifact" for the last "release"
    And the current account has 1 "license"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    And the current user has 1 "license"
    When I send a GET request to "/accounts/test1/artifacts/$0"
    Then the response status should be "404"

  Scenario: User retrieves a failed artifact with a license for it
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "release" for the last "product"
    And the current account has 1 failed "artifact" for the last "release"
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "license" for the last "policy"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    And the current user has 1 "license"
    When I send a GET request to "/accounts/test1/artifacts/$0"
    Then the response status should be "404"

  Scenario: Product retrieves a failed artifact
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "release" for the last "product"
    And the current account has 1 failed "artifact" for the last "release"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/artifacts/$0"
    Then the response status should be "200"

  Scenario: Product retrieves a failed artifact of another product
    Given the current account is "test1"
    And the current account has 2 "products"
    And the current account has 1 "release" for the second "product"
    And the current account has 1 failed "artifact" for the last "release"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/artifacts/$0"
    Then the response status should be "404"

  Scenario: Admin retrieves a failed artifact
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "release" for the last "product"
    And the current account has 1 failed "artifact" for the last "release"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/artifacts/$0"
    Then the response status should be "200"

  # Yanked artifacts
  Scenario: Anonymous retrieves a yanked artifact
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "release" for the last "product"
    And the current account has 1 yanked "artifact" for the last "release"
    When I send a GET request to "/accounts/test1/artifacts/$0"
    Then the response status should be "404"

  Scenario: License retrieves a yanked artifact without a license for it
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "release" for the last "product"
    And the current account has 1 yanked "artifact" for the last "release"
    And the current account has 1 "license"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/artifacts/$0"
    Then the response status should be "404"

  Scenario: License retrieves a yanked artifact with a license for it
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "release" for the last "product"
    And the current account has 1 yanked "artifact" for the last "release"
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "license" for the last "policy"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/artifacts/$0"
    Then the response status should be "404"

  Scenario: User retrieves a yanked artifact without a license for it
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "release" for the last "product"
    And the current account has 1 yanked "artifact" for the last "release"
    And the current account has 1 "license"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    And the current user has 1 "license"
    When I send a GET request to "/accounts/test1/artifacts/$0"
    Then the response status should be "404"

  Scenario: User retrieves a yanked artifact with a license for it
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "release" for the last "product"
    And the current account has 1 yanked "artifact" for the last "release"
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "license" for the last "policy"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    And the current user has 1 "license"
    When I send a GET request to "/accounts/test1/artifacts/$0"
    Then the response status should be "404"

  Scenario: Product retrieves a yanked artifact
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "release" for the last "product"
    And the current account has 1 yanked "artifact" for the last "release"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/artifacts/$0"
    Then the response status should be "200"

  Scenario: Product retrieves a yanked artifact of another product
    Given the current account is "test1"
    And the current account has 2 "products"
    And the current account has 1 "release" for the second "product"
    And the current account has 1 yanked "artifact" for the last "release"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/artifacts/$0"
    Then the response status should be "404"

  Scenario: Admin retrieves a yanked artifact
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "release" for the last "product"
    And the current account has 1 yanked "artifact" for the last "release"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/artifacts/$0"
    Then the response status should be "200"

  Scenario: Admin retrieves an artifact with an application/json accept header
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "release" for the last "product"
    And the current account has 1 "artifact" for the last "release"
    And I am an admin of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Accept": "application/json" }
      """
    When I send a GET request to "/accounts/test1/artifacts/$0"
    Then the response status should be "303"
    Then the response should contain the following headers:
      """
      { "Content-Type": "application/json; charset=utf-8" }
      """

  Scenario: Admin retrieves an artifact with an application/xml accept header
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "release" for the last "product"
    And the current account has 1 "artifact" for the last "release"
    And I am an admin of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Accept": "application/xml" }
      """
    When I send a GET request to "/accounts/test1/artifacts/$0"
    Then the response status should be "303"
    Then the response should contain the following headers:
      """
      { "Content-Type": "application/vnd.api+json; charset=utf-8" }
      """

  Scenario: Admin retrieves an artifact with an application/octet-stream accept header
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "release" for the last "product"
    And the current account has 1 "artifact" for the last "release"
    And I am an admin of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Accept": "application/octet-stream" }
      """
    When I send a GET request to "/accounts/test1/artifacts/$0"
    Then the response status should be "303"
    Then the response should contain the following headers:
      """
      { "Content-Type": "application/vnd.api+json; charset=utf-8" }
      """

  Scenario: Admin retrieves an artifact with a text/html accept header
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "release" for the last "product"
    And the current account has 1 "artifact" for the last "release"
    And I am an admin of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Accept": "text/html" }
      """
    When I send a GET request to "/accounts/test1/artifacts/$0"
    Then the response status should be "303"
    Then the response should contain the following headers:
      """
      { "Content-Type": "application/vnd.api+json; charset=utf-8" }
      """

  Scenario: Admin retrieves an artifact with a text/plain accept header
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "release" for the last "product"
    And the current account has 1 "artifact" for the last "release"
    And I am an admin of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Accept": "text/plain" }
      """
    When I send a GET request to "/accounts/test1/artifacts/$0"
    Then the response status should be "303"
    Then the response should contain the following headers:
      """
      { "Content-Type": "application/vnd.api+json; charset=utf-8" }
      """

  Scenario: Admin retrieves an artifact with a */* accept header
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "release" for the last "product"
    And the current account has 1 "artifact" for the last "release"
    And I am an admin of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Accept": "*/*" }
      """
    When I send a GET request to "/accounts/test1/artifacts/$0"
    Then the response status should be "303"
    Then the response should contain the following headers:
      """
      { "Content-Type": "application/vnd.api+json; charset=utf-8" }
      """

  Scenario: Admin retrieves an artifact with a * accept header
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "release" for the last "product"
    And the current account has 1 "artifact" for the last "release"
    And I am an admin of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Accept": "*" }
      """
    When I send a GET request to "/accounts/test1/artifacts/$0"
    Then the response status should be "303"
    Then the response should contain the following headers:
      """
      { "Content-Type": "application/vnd.api+json; charset=utf-8" }
      """
