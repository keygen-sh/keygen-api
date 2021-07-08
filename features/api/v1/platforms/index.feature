@api/v1
Feature: List release platforms

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
    When I send a GET request to "/accounts/test1/platforms"
    Then the response status should be "403"

  Scenario: Admin retrieves the platforms for a product
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
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/platforms"
    Then the response status should be "200"
    And the JSON response should be an array with 3 "platforms"

  Scenario: Product retrieves the platforms for a product
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test 1 |
    And the current account has the following "release" rows:
      | product_id                           | version                    | filename                        | filetype | platform | channel  |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0-alpha.1              | Test-App-1.0.0-alpha.1.zip      | zip      | darwin   | alpha    |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0                      | Test-App-1.0.0.zip              | zip      | darwin   | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.1                      | Test-App-1.0.1.zip              | zip      | darwin   | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.2                      | Test-App-1.0.2.zip              | zip      | darwin   | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.3                      | Test-App-1.0.3.zip              | zip      | darwin   | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.0                      | Test-App-1.1.0.zip              | zip      | darwin   | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.1                      | Test-App-1.1.1.zip              | zip      | darwin   | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.2                      | Test-App-1.1.2.zip              | zip      | darwin   | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.2.0                      | Test-App-1.2.0.zip              | zip      | darwin   | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.3.0                      | Test-App-1.3.0.zip              | zip      | darwin   | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.4.0-beta.1               | Test-App-1.4.0-beta.1.zip       | zip      | darwin   | beta     |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.4.0-beta.2               | Test-App-1.4.0-beta.2.zip       | zip      | darwin   | beta     |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.4.0-beta.3               | Test-App-1.4.0-beta.3.zip       | zip      | darwin   | beta     |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.4.0                      | Test-App-1.4.0.zip              | zip      | darwin   | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.5.0                      | Test-App-1.5.0.zip              | zip      | darwin   | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.6.0                      | Test-App-1.6.0.zip              | zip      | darwin   | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.7.0-dev+build.1624653614 | Test-App-1624653614.zip         | zip      | darwin   | dev      |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.7.0                      | Test-App-1.7.0.zip              | zip      | darwin   | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0-dev+build.1624654615 | Test-App-macOS-1624654615.zip   | zip      | darwin   | dev      |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0-dev+build.1624654615 | Test-App-Windows-1624654615.zip | zip      | win32    | dev      |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 2.0.0-dev+build.1624654615 | Test-App-Linux-1624654615.zip   | zip      | linux    | dev      |
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/platforms"
    Then the response status should be "200"
    And the JSON response should be an array with 3 "platforms"

  Scenario: Product retrieves the platforms of another product
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
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/platforms"
    Then the response status should be "200"
    And the JSON response should be an array of 0 "platforms"

  Scenario: User attempts to retrieve the platforms for a product (licensed)
    Given the current account is "test1"
    And the current account has 1 "user"
    And the current account has 1 "product"
    And the current account has 1 "policy" for an existing "product"
    And the current account has 1 "license" for an existing "policy"
    And the current account has 1 "release" for an existing "product"
    And I am a user of account "test1"
    And the current user has 1 "license"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/platforms"
    Then the response status should be "200"
    And the JSON response should be an array of 1 "platform"

  Scenario: User attempts to retrieve the platforms for a product (unlicensed)
    Given the current account is "test1"
    And the current account has 1 "user"
    And the current account has 1 "product"
    And the current account has 1 "policy" for an existing "product"
    And the current account has 1 "license" for an existing "policy"
    And the current account has 1 "release" for an existing "product"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/platforms"
    Then the response status should be "200"
    And the JSON response should be an array of 0 "platforms"

  Scenario: License attempts to retrieve the platforms for their product
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "policy" for an existing "product"
    And the current account has 1 "license" for an existing "policy"
    And the current account has 3 "releases" for the first "product"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/platforms"
    Then the response status should be "200"
    And the JSON response should be an array of 1 "platform"

  Scenario: License attempts to retrieve the platforms for a different product
   Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "license"
    And the current account has 3 "releases" for the first "product"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/platforms"
    Then the response status should be "200"
    And the JSON response should be an array of 0 "platforms"

  Scenario: Admin attempts to retrieve the platforms for a product of another account
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test 1 |
    And the current account has the following "release" rows:
      | product_id                           | version      | filename              | filetype | platform | channel  |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0        | Test-App-1.0.0.dmg    | dmg      | macos    | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0        | Test-App-1.0.0.zip    | zip      | win32    | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0        | Test-App.1.0.0.tar.gz | tar.gz   | linux    | stable   |
    And I am an admin of account "test2"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/platforms"
    Then the response status should be "401"
