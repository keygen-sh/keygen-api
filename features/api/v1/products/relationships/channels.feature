@api/v1
Feature: Product channels relationship

  Background:
    Given the following "accounts" exist:
      | Name    | Slug  |
      | Test 1  | test1 |
      | Test 2  | test2 |
    And I send and accept JSON

  Scenario: Endpoint should be inaccessible when account is disabled
    Given the account "test1" is canceled
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "product"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products/$0/channels"
    Then the response status should be "403"

  Scenario: Admin retrieves the channels for a product
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test 1 |
      | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | Test 2 |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | version      | channel |
      | e7ac958a-7828-4d8e-8ac3-ef56021ea3c6 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0        | stable  |
      | c09699a3-5cee-4188-8e3c-51483d418a19 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.1        | stable  |
      | f1f7fe53-b502-4ec3-ab70-9ca1d1d0ccbd | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.0        | stable  |
      | 2df89d07-fe67-4944-b5b7-4e0da855ba82 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.2.0-beta.1 | beta    |
      | 12d53d5f-33c7-4d4a-9a68-715c3368cc86 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0-beta.1 | beta    |
      | f5734806-48a9-4dd1-a2ba-e672fe8a2b31 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0-beta.2 | beta    |
      | 23f65e0f-ca86-42f0-b427-91cc1e4d5bba | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | 1.0.0        | stable  |
    And the current account has the following "artifact" rows:
      | release_id                           | filename                  | filetype | platform |
      | e7ac958a-7828-4d8e-8ac3-ef56021ea3c6 | Test-App-1.0.0.zip        | zip      | macos    |
      | c09699a3-5cee-4188-8e3c-51483d418a19 | Test-App-1.0.1.zip        | zip      | macos    |
      | f1f7fe53-b502-4ec3-ab70-9ca1d1d0ccbd | Test-App-1.1.0.zip        | zip      | macos    |
      | 2df89d07-fe67-4944-b5b7-4e0da855ba82 | Test-App-1.2.0-beta.1.zip | zip      | macos    |
      | 12d53d5f-33c7-4d4a-9a68-715c3368cc86 | Test-App.1.0.0-beta.1.exe | exe      | win32    |
      | f5734806-48a9-4dd1-a2ba-e672fe8a2b31 | Test-App.1.0.0-beta.2.exe | exe      | win32    |
      | 23f65e0f-ca86-42f0-b427-91cc1e4d5bba | Test-App.1.0.0.tar.gz     | tar.gz   | linux    |
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products/$0/channels"
    Then the response status should be "200"
    And the response body should be an array with 2 "channels"

  @ee
  Scenario: Environment retrieves the channels for an isolated product
    Given the current account is "test1"
    And the current account has the following "environment" rows:
      | id                                   | name     | code     | isolation_strategy |
      | bf20fe24-351d-47d0-b3c3-2c576a63d22f | Isolated | isolated | ISOLATED           |
      | 60e7f35f-5401-4cc2-abd3-999b2a758ee1 | Shared   | shared   | SHARED             |
    And the current account has the following "product" rows:
      | id                                   | environment_id                       | name     |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | Isolated |
      | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | 60e7f35f-5401-4cc2-abd3-999b2a758ee1 | Shared   |
    And the current account has the following "release" rows:
      | id                                   | environment_id                       | product_id                           | version      | channel |
      | e7ac958a-7828-4d8e-8ac3-ef56021ea3c6 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0        | stable  |
      | c09699a3-5cee-4188-8e3c-51483d418a19 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.1        | stable  |
      | f1f7fe53-b502-4ec3-ab70-9ca1d1d0ccbd | bf20fe24-351d-47d0-b3c3-2c576a63d22f | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.0        | stable  |
      | 2df89d07-fe67-4944-b5b7-4e0da855ba82 | 60e7f35f-5401-4cc2-abd3-999b2a758ee1 | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | 1.2.0-beta.1 | beta    |
    And the current account has the following "artifact" rows:
      | release_id                           | environment_id                       | filename                  | filetype | platform | arch  |
      | e7ac958a-7828-4d8e-8ac3-ef56021ea3c6 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | Test-App-1.0.0.zip        | zip      | macos    | amd64 |
      | c09699a3-5cee-4188-8e3c-51483d418a19 | bf20fe24-351d-47d0-b3c3-2c576a63d22f | Test-App-1.0.1.zip        | zip      | macos    | amd64 |
      | f1f7fe53-b502-4ec3-ab70-9ca1d1d0ccbd | bf20fe24-351d-47d0-b3c3-2c576a63d22f | Test-App-1.1.0.zip        | zip      | macos    | amd64 |
      | 2df89d07-fe67-4944-b5b7-4e0da855ba82 | 60e7f35f-5401-4cc2-abd3-999b2a758ee1 | Test-App-1.2.0-beta.1.zip | zip      | macos    | x86   |
    And I am an environment of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products/$0/channels?environment=isolated"
    Then the response status should be "200"
    And the response body should be an array with 1 "channel"

  @ee
  Scenario: Environment retrieves the channels for a mixed product
    Given the current account is "test1"
    And the current account has the following "environment" rows:
      | id                                   | name     | code   | isolation_strategy |
      | 60e7f35f-5401-4cc2-abd3-999b2a758ee1 | Shared   | shared | SHARED             |
    And the current account has the following "product" rows:
      | id                                   | environment_id                       | name   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 |                                      | Global |
    And the current account has the following "release" rows:
      | id                                   | environment_id                       | product_id                           | version      | channel |
      | e7ac958a-7828-4d8e-8ac3-ef56021ea3c6 |                                      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0        | stable  |
      | c09699a3-5cee-4188-8e3c-51483d418a19 |                                      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.1        | stable  |
      | f1f7fe53-b502-4ec3-ab70-9ca1d1d0ccbd |                                      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.0        | stable  |
      | 2df89d07-fe67-4944-b5b7-4e0da855ba82 | 60e7f35f-5401-4cc2-abd3-999b2a758ee1 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.2.0-beta.1 | beta    |
    And the current account has the following "artifact" rows:
      | release_id                           | environment_id                       | filename                  | filetype | platform | arch  |
      | e7ac958a-7828-4d8e-8ac3-ef56021ea3c6 |                                      | Test-App-1.0.0.zip        | zip      | macos    | amd64 |
      | c09699a3-5cee-4188-8e3c-51483d418a19 |                                      | Test-App-1.0.1.zip        | zip      | macos    | amd64 |
      | f1f7fe53-b502-4ec3-ab70-9ca1d1d0ccbd |                                      | Test-App-1.1.0.zip        | zip      | macos    | amd64 |
      | 2df89d07-fe67-4944-b5b7-4e0da855ba82 | 60e7f35f-5401-4cc2-abd3-999b2a758ee1 | Test-App-1.2.0-beta.1.zip | zip      | macos    | x86   |
    And I am an environment of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products/$0/channels?environment=shared"
    Then the response status should be "200"
    And the response body should be an array with 2 "channels"

  Scenario: Product retrieves the channels for a product
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
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products/$0/channels"
    Then the response status should be "200"
    And the response body should be an array with 5 "channels"

  Scenario: Admin retrieves a channel for a product
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test 1 |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | version | channel |
      | e7ac958a-7828-4d8e-8ac3-ef56021ea3c6 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0   | stable  |
    And the current account has the following "artifact" rows:
      | release_id                           | filename              | filetype | platform |
      | e7ac958a-7828-4d8e-8ac3-ef56021ea3c6 | Test-App-1.0.0.dmg    | dmg      | macos    |
      | e7ac958a-7828-4d8e-8ac3-ef56021ea3c6 | Test-App-1.0.0.zip    | zip      | win32    |
      | e7ac958a-7828-4d8e-8ac3-ef56021ea3c6 | Test-App.1.0.0.tar.gz | tar.gz   | linux    |
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products/$0/channels/$0"
    Then the response status should be "200"
    And the response body should be a "channel"

  Scenario: Product retrieves a channel for their product
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test 1 |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | version | channel |
      | e7ac958a-7828-4d8e-8ac3-ef56021ea3c6 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0   | stable  |
    And the current account has the following "artifact" rows:
      | release_id                           | filename              | filetype | platform |
      | e7ac958a-7828-4d8e-8ac3-ef56021ea3c6 | Test-App-1.0.0.dmg    | dmg      | macos    |
      | e7ac958a-7828-4d8e-8ac3-ef56021ea3c6 | Test-App-1.0.0.zip    | zip      | win32    |
      | e7ac958a-7828-4d8e-8ac3-ef56021ea3c6 | Test-App.1.0.0.tar.gz | tar.gz   | linux    |
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products/$0/channels/$0"
    Then the response status should be "200"
    And the response body should be a "channel"

  Scenario: Product retrieves the channels of another product
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name   |
      | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | Test 1 |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test 2 |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | version | channel |
      | e7ac958a-7828-4d8e-8ac3-ef56021ea3c6 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0   | stable  |
    And the current account has the following "artifact" rows:
      | release_id                           | filename              | filetype | platform |
      | e7ac958a-7828-4d8e-8ac3-ef56021ea3c6 | Test-App-1.0.0.dmg    | dmg      | macos    |
      | e7ac958a-7828-4d8e-8ac3-ef56021ea3c6 | Test-App-1.0.0.zip    | zip      | win32    |
      | e7ac958a-7828-4d8e-8ac3-ef56021ea3c6 | Test-App.1.0.0.tar.gz | tar.gz   | linux    |
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products/$1/channels"
    Then the response status should be "404"

  Scenario: User attempts to retrieve the channels for a product (licensed)
    Given the current account is "test1"
    And the current account has 1 "user"
    And the current account has 1 "product"
    And the current account has 1 "policy" for an existing "product"
    And the current account has 1 "license" for an existing "policy"
    And the current account has 1 "release" for an existing "product"
    And the current account has 1 "artifact" for each "release"
    And I am a user of account "test1"
    And the current user has 1 "license" as "owner"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products/$0/channels"
    Then the response status should be "200"
    And the response body should be an array with 1 "channel"

  Scenario: User attempts to retrieve the channels for a product (unlicensed)
    Given the current account is "test1"
    And the current account has 1 "user"
    And the current account has 1 "product"
    And the current account has 1 "policy" for an existing "product"
    And the current account has 1 "license" for an existing "policy"
    And the current account has 1 "release" for an existing "product"
    And the current account has 1 "artifact" for each "release"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products/$0/channels"
    Then the response status should be "404"

  Scenario: License attempts to retrieve the channels for their product
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "policy" for an existing "product"
    And the current account has 1 "license" for an existing "policy"
    And the current account has 3 "releases" for the first "product"
    And the current account has 1 "artifact" for each "release"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products/$0/channels"
    Then the response status should be "200"
    And the response body should be an array with 1 "channel"

  Scenario: License attempts to retrieve the channels for a different product
   Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "license"
    And the current account has 3 "releases" for the first "product"
    And the current account has 1 "artifact" for each "release"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products/$0/channels"
    Then the response status should be "404"

  Scenario: Admin attempts to retrieve the channels for a product of another account
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test 1 |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | version | channel |
      | e7ac958a-7828-4d8e-8ac3-ef56021ea3c6 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0   | stable  |
    And the current account has the following "artifact" rows:
      | release_id                           | filename              | filetype | platform |
      | e7ac958a-7828-4d8e-8ac3-ef56021ea3c6 | Test-App-1.0.0.dmg    | dmg      | macos    |
      | e7ac958a-7828-4d8e-8ac3-ef56021ea3c6 | Test-App-1.0.0.zip    | zip      | win32    |
      | e7ac958a-7828-4d8e-8ac3-ef56021ea3c6 | Test-App.1.0.0.tar.gz | tar.gz   | linux    |
    And I am an admin of account "test2"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products/$0/channels"
    Then the response status should be "401"
