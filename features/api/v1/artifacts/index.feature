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

  Scenario: Admin retrieves their release artifacts (all releases have artifacts)
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test 1 |
      | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | Test 2 |
    And the current account has the following "release" rows:
      | product_id                           | version      | filename                  | filetype | platform | channel  |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0        | Test-App-1.0.0.zip        | zip      | macos    | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.1        | Test-App-1.0.1.zip        | zip      | macos    | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.0        | Test-App-1.1.0.zip        | zip      | macos    | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.2.0-beta.1 | Test-App-1.2.0-beta.1.zip | zip      | macos    | beta     |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0-beta.1 | Test-App.1.0.0-beta.1.exe | exe      | win32    | beta     |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0-beta.2 | Test-App.1.0.0-beta.2.exe | exe      | win32    | beta     |
      | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | 1.0.0        | Test-App.1.0.0.tar.gz     | tar.gz   | linux    | stable   |
    And all "releases" have artifacts that are uploaded
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/artifacts"
    Then the response status should be "200"
    And the JSON response should be an array with 7 "artifacts"

  Scenario: Admin retrieves their release artifacts (some releases have artifacts)
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test 1 |
      | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | Test 2 |
    And the current account has the following "release" rows:
      | product_id                           | version      | filename                  | filetype | platform | channel  |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0        | Test-App-1.0.0.zip        | zip      | macos    | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0-beta.1 | Test-App.1.0.0-beta.1.exe | exe      | win32    | beta     |
      | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | 1.0.0        | Test-App.1.0.0.tar.gz     | tar.gz   | linux    | stable   |
    And the first "release" has an artifact that is uploaded
    And the third "release" has an artifact that is uploaded
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/artifacts"
    Then the response status should be "200"
    And the JSON response should be an array with 2 "artifacts"

  Scenario: Product retrieves their release artifacts
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test 1 |
      | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | Test 2 |
    And the current account has the following "release" rows:
      | product_id                           | version                    | filename                        | filetype | platform | channel  |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0-alpha.1              | Test-App-1.0.0-alpha.1.zip      | zip      | darwin   | alpha    |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0                      | Test-App-1.0.0.zip              | zip      | darwin   | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.1                      | Test-App-1.0.1.zip              | zip      | darwin   | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.2                      | Test-App-1.0.2.zip              | zip      | darwin   | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.3                      | Test-App-1.0.3.zip              | zip      | darwin   | stable   |
      | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | 1.1.0                      | Test-App-1.1.0.zip              | zip      | darwin   | stable   |
      | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | 1.1.1                      | Test-App-1.1.1.zip              | zip      | darwin   | stable   |
      | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | 1.1.2                      | Test-App-1.1.2.zip              | zip      | darwin   | stable   |
      | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | 1.2.0                      | Test-App-1.2.0.zip              | zip      | darwin   | stable   |
      | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | 1.3.0                      | Test-App-1.3.0.zip              | zip      | darwin   | stable   |
      | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | 1.4.0-beta.1               | Test-App-1.4.0-beta.1.zip       | zip      | darwin   | beta     |
      | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | 1.4.0-beta.2               | Test-App-1.4.0-beta.2.zip       | zip      | darwin   | beta     |
      | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | 1.4.0-beta.3               | Test-App-1.4.0-beta.3.zip       | zip      | darwin   | beta     |
      | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | 1.4.0                      | Test-App-1.4.0.zip              | zip      | darwin   | stable   |
      | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | 1.5.0                      | Test-App-1.5.0.zip              | zip      | darwin   | stable   |
      | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | 1.6.0                      | Test-App-1.6.0.zip              | zip      | darwin   | stable   |
      | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | 1.7.0-dev+build.1624653614 | Test-App-1624653614.zip         | zip      | darwin   | dev      |
      | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | 1.7.0                      | Test-App-1.7.0.zip              | zip      | darwin   | stable   |
      | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | 2.0.0-dev+build.1624654615 | Test-App-macOS-1624654615.zip   | zip      | darwin   | dev      |
      | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | 2.0.0-dev+build.1624654615 | Test-App-Windows-1624654615.zip | zip      | win32    | dev      |
      | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | 2.0.0-dev+build.1624654615 | Test-App-Linux-1624654615.zip   | zip      | linux    | dev      |
      | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | 1.0.0                      | Test-App-Android.apk            | apk      | android  | stable   |
    And all "releases" have artifacts that are uploaded
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/artifacts"
    Then the response status should be "200"
    And the JSON response should be an array with 5 "artifacts"

  Scenario: Product retrieves the artifacts of another product
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name   |
      | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | Test 1 |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test 2 |
    And the current account has the following "release" rows:
      | product_id                           | version      | filename              | filetype | platform | channel  |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0        | Test-App-1.0.0.dmg    | dmg      | macos    | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0        | Test-App-1.0.0.zip    | zip      | win32    | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0        | Test-App.1.0.0.tar.gz | tar.gz   | linux    | stable   |
    And all "releases" have artifacts that are uploaded
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/artifacts"
    Then the response status should be "200"
    And the JSON response should be an array of 0 "artifacts"

  Scenario: User attempts to retrieve the artifacts for a product (licensed)
    Given the current account is "test1"
    And the current account has 1 "user"
    And the current account has 1 "product"
    And the current account has 1 "policy" for an existing "product"
    And the current account has 1 "license" for an existing "policy"
    And the current account has 2 "releases" for an existing "product"
    And all "releases" have artifacts that are uploaded
    And I am a user of account "test1"
    And the current user has 1 "license"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/artifacts"
    Then the response status should be "200"
    And the JSON response should be an array of 2 "artifacts"

  Scenario: User attempts to retrieve the artifacts for a product (unlicensed)
    Given the current account is "test1"
    And the current account has 1 "user"
    And the current account has 1 "product"
    And the current account has 1 "policy" for an existing "product"
    And the current account has 1 "license" for an existing "policy"
    And the current account has 1 "release" for an existing "product"
    And all "releases" have artifacts that are uploaded
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/artifacts"
    Then the response status should be "200"
    And the JSON response should be an array of 0 "artifacts"

  Scenario: License attempts to retrieve the artifacts for their product
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "policy" for an existing "product"
    And the current account has 1 "license" for an existing "policy"
    And the current account has 3 "releases" for the first "product"
    And all "releases" have artifacts that are uploaded
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/artifacts"
    Then the response status should be "200"
    And the JSON response should be an array of 3 "artifacts"

  Scenario: License attempts to retrieve the artifacts for a different product
   Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "license"
    And the current account has 3 "releases" for the first "product"
    And all "releases" have artifacts that are uploaded
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/artifacts"
    Then the response status should be "200"
    And the JSON response should be an array of 0 "artifacts"

  Scenario: Admin attempts to retrieve the artifacts for a product of another account
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test 1 |
    And the current account has the following "release" rows:
      | product_id                           | version      | filename              | filetype | platform | channel  |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0        | Test-App-1.0.0.dmg    | dmg      | macos    | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0        | Test-App-1.0.0.zip    | zip      | win32    | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0        | Test-App.1.0.0.tar.gz | tar.gz   | linux    | stable   |
    And all "releases" have artifacts that are uploaded
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
    And all "releases" have artifacts that are uploaded
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
    And all "releases" have artifacts that are uploaded
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
    And all "releases" have artifacts that are uploaded
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
    And all "releases" have artifacts that are uploaded
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
    And all "releases" have artifacts that are uploaded
    And the current account has 1 "policy" for the first "product"
    And the current account has 1 "license" for the first "policy"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    And the current user has 1 "license"
    When I send a GET request to "/accounts/test1/artifacts?product=$products[0]"
    Then the response status should be "200"
    And the JSON response should be an array with 3 "artifacts"
