@api/v1
Feature: List release artifacts

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
    When I send a GET request to "/accounts/test1/artifacts"
    Then the response status should be "403"

  Scenario: Admin retrieves all release artifacts
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test 1 |
      | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | Test 2 |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | version      | channel  |
      | fffa0764-3a19-48ea-beb3-8950563c7357 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0        | stable   |
      | 165d5389-e535-4f36-9232-ed59c67375d1 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.1        | stable   |
      | e4fa628e-593d-48bc-8e3e-5e4dda1f2c3a | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.0        | stable   |
      | fd10ab0c-c52a-412f-b34f-180eebd7325d | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.2.0-beta.1 | beta     |
      | f98d8c17-5fad-4361-ad89-43b0c6f6fa00 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0-beta.1 | beta     |
      | 077ca1f2-6125-4a77-bdf0-3161a0fc278e | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0-beta.2 | beta     |
      | 0a027f00-0860-4fa7-bd37-5900c8866818 | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | 1.0.0        | stable   |
    And the current account has the following "artifact" rows:
      | release_id                           | filename                  | filetype | platform |
      | fffa0764-3a19-48ea-beb3-8950563c7357 | Test-App-1.0.0.zip        | zip      | macos    |
      | 165d5389-e535-4f36-9232-ed59c67375d1 | Test-App-1.0.1.zip        | zip      | macos    |
      | e4fa628e-593d-48bc-8e3e-5e4dda1f2c3a | Test-App-1.1.0.zip        | zip      | macos    |
      | fd10ab0c-c52a-412f-b34f-180eebd7325d | Test-App-1.2.0-beta.1.zip | zip      | macos    |
      | f98d8c17-5fad-4361-ad89-43b0c6f6fa00 | Test-App.1.0.0-beta.1.exe | exe      | win32    |
      | 077ca1f2-6125-4a77-bdf0-3161a0fc278e | Test-App.1.0.0-beta.2.exe | exe      | win32    |
      | 0a027f00-0860-4fa7-bd37-5900c8866818 | Test-App.1.0.0.tar.gz     | tar.gz   | linux    |
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/artifacts"
    Then the response status should be "200"
    And the JSON response should be an array with 7 "artifacts"

  Scenario: Admin retrieves all stable release artifacts
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test 1 |
      | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | Test 2 |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | version      | channel  |
      | fffa0764-3a19-48ea-beb3-8950563c7357 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0        | stable   |
      | 165d5389-e535-4f36-9232-ed59c67375d1 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.1        | stable   |
      | e4fa628e-593d-48bc-8e3e-5e4dda1f2c3a | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.0        | stable   |
      | fd10ab0c-c52a-412f-b34f-180eebd7325d | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.2.0-beta.1 | beta     |
      | f98d8c17-5fad-4361-ad89-43b0c6f6fa00 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0-beta.1 | beta     |
      | 077ca1f2-6125-4a77-bdf0-3161a0fc278e | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0-beta.2 | beta     |
      | 0a027f00-0860-4fa7-bd37-5900c8866818 | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | 1.0.0        | stable   |
    And the current account has the following "artifact" rows:
      | release_id                           | filename                  | filetype | platform |
      | fffa0764-3a19-48ea-beb3-8950563c7357 | Test-App-1.0.0.zip        | zip      | macos    |
      | 165d5389-e535-4f36-9232-ed59c67375d1 | Test-App-1.0.1.zip        | zip      | macos    |
      | e4fa628e-593d-48bc-8e3e-5e4dda1f2c3a | Test-App-1.1.0.zip        | zip      | macos    |
      | fd10ab0c-c52a-412f-b34f-180eebd7325d | Test-App-1.2.0-beta.1.zip | zip      | macos    |
      | f98d8c17-5fad-4361-ad89-43b0c6f6fa00 | Test-App.1.0.0-beta.1.exe | exe      | win32    |
      | 077ca1f2-6125-4a77-bdf0-3161a0fc278e | Test-App.1.0.0-beta.2.exe | exe      | win32    |
      | 0a027f00-0860-4fa7-bd37-5900c8866818 | Test-App.1.0.0.tar.gz     | tar.gz   | linux    |
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/artifacts?channel=stable"
    Then the response status should be "200"
    And the JSON response should be an array with 4 "artifacts"

  Scenario: Admin retrieves all beta release artifacts
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test 1 |
      | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | Test 2 |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | version      | channel  |
      | fffa0764-3a19-48ea-beb3-8950563c7357 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0        | stable   |
      | 165d5389-e535-4f36-9232-ed59c67375d1 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.1        | stable   |
      | e4fa628e-593d-48bc-8e3e-5e4dda1f2c3a | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.0        | stable   |
      | fd10ab0c-c52a-412f-b34f-180eebd7325d | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.2.0-beta.1 | beta     |
      | f98d8c17-5fad-4361-ad89-43b0c6f6fa00 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0-beta.1 | beta     |
      | 077ca1f2-6125-4a77-bdf0-3161a0fc278e | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0-beta.2 | beta     |
      | 0a027f00-0860-4fa7-bd37-5900c8866818 | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | 1.0.0        | stable   |
    And the current account has the following "artifact" rows:
      | release_id                           | filename                  | filetype | platform |
      | fffa0764-3a19-48ea-beb3-8950563c7357 | Test-App-1.0.0.zip        | zip      | macos    |
      | 165d5389-e535-4f36-9232-ed59c67375d1 | Test-App-1.0.1.zip        | zip      | macos    |
      | e4fa628e-593d-48bc-8e3e-5e4dda1f2c3a | Test-App-1.1.0.zip        | zip      | macos    |
      | fd10ab0c-c52a-412f-b34f-180eebd7325d | Test-App-1.2.0-beta.1.zip | zip      | macos    |
      | f98d8c17-5fad-4361-ad89-43b0c6f6fa00 | Test-App.1.0.0-beta.1.exe | exe      | win32    |
      | 077ca1f2-6125-4a77-bdf0-3161a0fc278e | Test-App.1.0.0-beta.2.exe | exe      | win32    |
      | 0a027f00-0860-4fa7-bd37-5900c8866818 | Test-App.1.0.0.tar.gz     | tar.gz   | linux    |
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/artifacts?channel=beta"
    Then the response status should be "200"
    And the JSON response should be an array with 7 "artifacts"

  Scenario: Admin retrieves all alpha release artifacts
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test 1 |
      | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | Test 2 |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | version       | channel  |
      | fffa0764-3a19-48ea-beb3-8950563c7357 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0         | stable   |
      | 165d5389-e535-4f36-9232-ed59c67375d1 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.1         | stable   |
      | e4fa628e-593d-48bc-8e3e-5e4dda1f2c3a | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.0         | stable   |
      | fd10ab0c-c52a-412f-b34f-180eebd7325d | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.2.0-beta.1  | beta     |
      | f98d8c17-5fad-4361-ad89-43b0c6f6fa00 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0-beta.1  | beta     |
      | 077ca1f2-6125-4a77-bdf0-3161a0fc278e | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0-alpha.1 | alpha    |
      | 0a027f00-0860-4fa7-bd37-5900c8866818 | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | 1.0.0         | stable   |
    And the current account has the following "artifact" rows:
      | release_id                           | filename                  | filetype | platform |
      | fffa0764-3a19-48ea-beb3-8950563c7357 | Test-App-1.0.0.zip        | zip      | macos    |
      | f98d8c17-5fad-4361-ad89-43b0c6f6fa00 | Test-App.1.0.0-beta.1.exe | exe      | win32    |
      | 0a027f00-0860-4fa7-bd37-5900c8866818 | Test-App.1.0.0.tar.gz     | tar.gz   | linux    |
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/artifacts?channel=alpha"
    Then the response status should be "200"
    And the JSON response should be an array with 3 "artifacts"

  Scenario: Product retrieves their release artifacts
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test 1 |
      | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | Test 2 |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | version                    | channel  |
      | da0242e7-a81e-4cbd-8bb6-21df9f42491e | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0-alpha.1              | alpha    |
      | adf4ac18-e17c-46ec-b467-56762b2cd862 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0                      | stable   |
      | 0f26a7db-3d15-4f78-b3d5-b13a2c916480 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.1                      | stable   |
      | 8b107e71-d926-4c99-a139-955dc77203be | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.2                      | stable   |
      | 349e6ef7-a24d-4aca-af1d-dba8aed3629f | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.3                      | stable   |
      | f15405fb-9124-49fa-b7a4-8dfa6497c9e9 | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | 1.1.0                      | stable   |
      | 2d0a64cb-13d2-43b9-8669-f4e23765311b | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | 1.1.1                      | stable   |
      | 2af8c310-ae1e-4da4-88cd-e06b63b1e353 | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | 1.1.2                      | stable   |
      | 359d4964-2e93-4590-8350-e83f00571918 | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | 1.2.0                      | stable   |
      | d584e9a7-c0a8-424c-b0ac-8efc0243df52 | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | 1.3.0                      | stable   |
      | 891cb839-f101-46ba-8b12-8eab05e7e9f5 | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | 1.4.0-beta.1               | beta     |
      | 14839d41-9612-4bbf-8865-408d2f22a73e | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | 1.4.0-beta.2               | beta     |
      | 95a32135-f349-4e12-919a-d421565e4656 | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | 1.4.0-beta.3               | beta     |
      | e7f24b70-a7f1-4450-9dc1-bf0c4c51e65d | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | 1.4.0                      | stable   |
      | 6344460b-b43c-4aa8-a76c-2086f9f526cc | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | 1.5.0                      | stable   |
      | cf72bfd4-771d-4889-8132-dc6ba8b66fa9 | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | 1.6.0                      | stable   |
      | e314ba5d-c760-4e54-81c4-fa01af68ff66 | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | 1.7.0-dev+build.1624653614 | dev      |
      | e26e9fef-d1ce-43d3-a15c-c8fc94429709 | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | 1.7.0                      | stable   |
      | c8b55f91-e66f-4093-ae4d-7f3d390eae8d | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | 2.0.0-dev+build.1651683471 | dev      |
      | dde54ea8-731d-4375-9d57-186ef01f3fcb | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | 2.0.0-dev+build.1651683478 | dev      |
      | ff04d1c4-cc04-4d19-985a-cb113827b821 | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | 2.0.0-dev+build.1651683483 | dev      |
      | a7fad100-04eb-418f-8af9-e5eac497ad5a | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | 1.0.0                      | stable   |
    And the current account has the following "artifact" rows:
      | release_id                           | filename                        | filetype | platform |
      | da0242e7-a81e-4cbd-8bb6-21df9f42491e | Test-App-1.0.0-alpha.1.zip      | zip      | darwin   |
      | adf4ac18-e17c-46ec-b467-56762b2cd862 | Test-App-1.0.0.zip              | zip      | darwin   |
      | 0f26a7db-3d15-4f78-b3d5-b13a2c916480 | Test-App-1.0.1.zip              | zip      | darwin   |
      | 8b107e71-d926-4c99-a139-955dc77203be | Test-App-1.0.2.zip              | zip      | darwin   |
      | 349e6ef7-a24d-4aca-af1d-dba8aed3629f | Test-App-1.0.3.zip              | zip      | darwin   |
      | f15405fb-9124-49fa-b7a4-8dfa6497c9e9 | Test-App-1.1.0.zip              | zip      | darwin   |
      | 2d0a64cb-13d2-43b9-8669-f4e23765311b | Test-App-1.1.1.zip              | zip      | darwin   |
      | 2af8c310-ae1e-4da4-88cd-e06b63b1e353 | Test-App-1.1.2.zip              | zip      | darwin   |
      | 359d4964-2e93-4590-8350-e83f00571918 | Test-App-1.2.0.zip              | zip      | darwin   |
      | d584e9a7-c0a8-424c-b0ac-8efc0243df52 | Test-App-1.3.0.zip              | zip      | darwin   |
      | 891cb839-f101-46ba-8b12-8eab05e7e9f5 | Test-App-1.4.0-beta.1.zip       | zip      | darwin   |
      | 14839d41-9612-4bbf-8865-408d2f22a73e | Test-App-1.4.0-beta.2.zip       | zip      | darwin   |
      | 95a32135-f349-4e12-919a-d421565e4656 | Test-App-1.4.0-beta.3.zip       | zip      | darwin   |
      | e7f24b70-a7f1-4450-9dc1-bf0c4c51e65d | Test-App-1.4.0.zip              | zip      | darwin   |
      | 6344460b-b43c-4aa8-a76c-2086f9f526cc | Test-App-1.5.0.zip              | zip      | darwin   |
      | cf72bfd4-771d-4889-8132-dc6ba8b66fa9 | Test-App-1.6.0.zip              | zip      | darwin   |
      | e314ba5d-c760-4e54-81c4-fa01af68ff66 | Test-App-1624653614.zip         | zip      | darwin   |
      | e26e9fef-d1ce-43d3-a15c-c8fc94429709 | Test-App-1.7.0.zip              | zip      | darwin   |
      | ff04d1c4-cc04-4d19-985a-cb113827b821 | Test-App-macOS-1651683471.zip   | zip      | darwin   |
      | c8b55f91-e66f-4093-ae4d-7f3d390eae8d | Test-App-Windows-1651683478.zip | zip      | win32    |
      | dde54ea8-731d-4375-9d57-186ef01f3fcb | Test-App-Linux-1651683483.zip   | zip      | linux    |
      | a7fad100-04eb-418f-8af9-e5eac497ad5a | Test-App-Android.apk            | apk      | android  |
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/artifacts?channel=alpha"
    Then the response status should be "200"
    And the JSON response should be an array with 5 "artifacts"

  Scenario: Product retrieves the artifacts of another product
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name   |
      | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | Test 1 |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test 2 |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | version | channel |
      | da0242e7-a81e-4cbd-8bb6-21df9f42491e | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0   | stable  |
    And the current account has the following "artifact" rows:
      | release_id                           | filename              | filetype | platform |
      | da0242e7-a81e-4cbd-8bb6-21df9f42491e | Test-App-1.0.0.dmg    | dmg      | macos    |
      | da0242e7-a81e-4cbd-8bb6-21df9f42491e | Test-App-1.0.0.zip    | zip      | win32    |
      | da0242e7-a81e-4cbd-8bb6-21df9f42491e | Test-App.1.0.0.tar.gz | tar.gz   | linux    |
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/artifacts"
    Then the response status should be "200"
    And the JSON response should be an array of 0 "artifacts"

  Scenario: User attempts to retrieve the artifacts for the last product (licensed)
    Given the current account is "test1"
    And the current account has 1 "user"
    And the current account has 1 "product"
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "license" for the last "policy"
    And the current account has 2 "releases" for the last "product"
    And the current account has 2 "artifacts" for existing "releases"
    And I am a user of account "test1"
    And the current user has 1 "license"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/artifacts"
    Then the response status should be "200"
    And the JSON response should be an array of 2 "artifacts"

  Scenario: User attempts to retrieve the artifacts for the last product (unlicensed)
    Given the current account is "test1"
    And the current account has 1 "user"
    And the current account has 1 "product"
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "license" for the last "policy"
    And the current account has 1 "release" for the last "product"
    And the current account has 3 "artifacts" for the last "release"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/artifacts"
    Then the response status should be "200"
    And the JSON response should be an array of 0 "artifacts"

  Scenario: License attempts to retrieve the artifacts for their product
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "license" for the last "policy"
    And the current account has 3 "releases" for the last "product"
    And the current account has 3 "artifacts" for existing "releases"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/artifacts"
    Then the response status should be "200"
    And the JSON response should be an array of 3 "artifacts"

  Scenario: License attempts to retrieve the artifacts for the last different product
   Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "license"
    And the current account has 3 "releases" for the first "product"
    And the current account has 5 "artifacts" for existing "releases"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/artifacts"
    Then the response status should be "200"
    And the JSON response should be an array of 0 "artifacts"

  Scenario: Admin attempts to retrieve the artifacts for the last product of another account
    Given the current account is "test1"
     And the current account has the following "product" rows:
      | id                                   | name   |
      | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | Test 1 |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test 2 |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | version | channel |
      | da0242e7-a81e-4cbd-8bb6-21df9f42491e | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0   | stable  |
    And the current account has the following "artifact" rows:
      | release_id                           | filename              | filetype | platform |
      | da0242e7-a81e-4cbd-8bb6-21df9f42491e | Test-App-1.0.0.dmg    | dmg      | macos    |
      | da0242e7-a81e-4cbd-8bb6-21df9f42491e | Test-App-1.0.0.zip    | zip      | win32    |
      | da0242e7-a81e-4cbd-8bb6-21df9f42491e | Test-App.1.0.0.tar.gz | tar.gz   | linux    |
    And I am an admin of account "test2"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/artifacts"
    Then the response status should be "401"

  Scenario: Anonymous attempts to retrieve all accessible releases
    Given the current account is "test1"
    And the current account has 3 "products"
    And the first "product" has the following attributes:
      """
      { "distributionStrategy": "LICENSED" }
      """
    And the second "product" has the following attributes:
      """
      { "distributionStrategy": "OPEN" }
      """
    And the third "product" has the following attributes:
      """
      { "distributionStrategy": "CLOSED" }
      """
    And the current account has 3 "releases" for the first "product"
    And the current account has 5 "releases" for the second "product"
    And the current account has 7 "releases" for the third "product"
    And the current account has 1 "artifact" for each "release"
    When I send a GET request to "/accounts/test1/artifacts"
    Then the response status should be "200"
    And the JSON response should be an array with 5 "artifacts"

  Scenario: License attempts to retrieve all accessible releases
    Given the current account is "test1"
    And the current account has 3 "products"
    And the first "product" has the following attributes:
      """
      { "distributionStrategy": "LICENSED" }
      """
    And the second "product" has the following attributes:
      """
      { "distributionStrategy": "OPEN" }
      """
    And the third "product" has the following attributes:
      """
      { "distributionStrategy": "CLOSED" }
      """
    And the current account has 3 "releases" for the first "product"
    And the current account has 5 "releases" for the second "product"
    And the current account has 7 "releases" for the third "product"
    And the current account has 1 "artifact" for each "release"
    And the current account has 1 "policy" for the first "product"
    And the current account has 1 "license" for the first "policy"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/artifacts"
    Then the response status should be "200"
    And the JSON response should be an array with 8 "artifacts"

  Scenario: License attempts to retrieve all accessible releases (filtered)
    Given the current account is "test1"
    And the current account has 3 "products"
    And the first "product" has the following attributes:
      """
      { "distributionStrategy": "LICENSED" }
      """
    And the second "product" has the following attributes:
      """
      { "distributionStrategy": "OPEN" }
      """
    And the third "product" has the following attributes:
      """
      { "distributionStrategy": "CLOSED" }
      """
    And the current account has 3 "releases" for the first "product"
    And the current account has 5 "releases" for the second "product"
    And the current account has 7 "releases" for the third "product"
    And the current account has 1 "artifact" for each "release"
    And the current account has 1 "policy" for the first "product"
    And the current account has 1 "license" for the first "policy"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/artifacts?product=$products[1]"
    Then the response status should be "200"
    And the JSON response should be an array with 5 "artifacts"

  Scenario: User attempts to retrieve all accessible releases
    Given the current account is "test1"
    And the current account has 3 "products"
    And the first "product" has the following attributes:
      """
      { "distributionStrategy": "LICENSED" }
      """
    And the second "product" has the following attributes:
      """
      { "distributionStrategy": "OPEN" }
      """
    And the third "product" has the following attributes:
      """
      { "distributionStrategy": "CLOSED" }
      """
    And the current account has 3 "releases" for the first "product"
    And the current account has 5 "releases" for the second "product"
    And the current account has 7 "releases" for the third "product"
    And the current account has 1 "artifact" for each "release"
    And the current account has 1 "policy" for the first "product"
    And the current account has 1 "license" for the first "policy"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    And the current user has 1 "license"
    When I send a GET request to "/accounts/test1/artifacts"
    Then the response status should be "200"
    And the JSON response should be an array with 8 "artifacts"

  Scenario: User attempts to retrieve all accessible releases (filtered)
    Given the current account is "test1"
    And the current account has 3 "products"
    And the first "product" has the following attributes:
      """
      { "distributionStrategy": "LICENSED" }
      """
    And the second "product" has the following attributes:
      """
      { "distributionStrategy": "OPEN" }
      """
    And the third "product" has the following attributes:
      """
      { "distributionStrategy": "CLOSED" }
      """
    And the current account has 3 "releases" for the first "product"
    And the current account has 5 "releases" for the second "product"
    And the current account has 7 "releases" for the third "product"
    And the current account has 1 "artifact" for each "release"
    And the current account has 1 "policy" for the first "product"
    And the current account has 1 "license" for the first "policy"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    And the current user has 1 "license"
    When I send a GET request to "/accounts/test1/artifacts?product=$products[0]"
    Then the response status should be "200"
    And the JSON response should be an array with 3 "artifacts"
