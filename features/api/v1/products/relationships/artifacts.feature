@api/v1
Feature: Product artifacts relationship

  Background:
    Given the following "accounts" exist:
      | Name    | Slug  |
      | Test 1  | test1 |
      | Test 2  | test2 |
    And I send and accept JSON

  # List artifacts
  Scenario: Endpoint should be inaccessible when account is disabled
    Given the account "test1" is canceled
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "product"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products/$0/artifacts"
    Then the response status should be "403"

  Scenario: Admin retrieves the artifacts for a product (all artifacts are uploaded)
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test 1 |
      | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | Test 2 |
    And the current account has the following "release" rows:
      | product_id                           | version      | filename                  | filetype | platform | channel  |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0        | Test-App-1.0.0.dmg        | dmg      | macos    | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.1        | Test-App-1.0.1.dmg        | dmg      | macos    | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.0        | Test-App-1.1.0.dmg        | dmg      | macos    | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.2.0-beta.1 | Test-App-1.2.0-beta.1.dmg | dmg      | macos    | beta     |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0-beta.1 | Test-App.1.0.0-beta.1.exe | exe      | win32    | beta     |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0-beta.2 | Test-App.1.0.0-beta.2.exe | exe      | win32    | beta     |
      | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | 1.0.0        | Test-App.1.0.0.tar.gz     | tar.gz   | linux    | stable   |
    And all "releases" have artifacts that are uploaded
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products/$0/artifacts"
    Then the response status should be "200"
    And the JSON response should be an array with 6 "artifacts"

  Scenario: Admin retrieves the artifacts for a product (some artifacts are uploaded)
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test 1 |
      | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | Test 2 |
    And the current account has the following "release" rows:
      | product_id                           | version      | filename                  | filetype | platform | channel  |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0        | Test-App-1.0.0.dmg        | dmg      | macos    | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.1        | Test-App-1.0.1.dmg        | dmg      | macos    | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.0        | Test-App-1.1.0.dmg        | dmg      | macos    | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.2.0-beta.1 | Test-App-1.2.0-beta.1.dmg | dmg      | macos    | beta     |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0-beta.1 | Test-App.1.0.0-beta.1.exe | exe      | win32    | beta     |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0-beta.2 | Test-App.1.0.0-beta.2.exe | exe      | win32    | beta     |
      | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | 1.0.0        | Test-App.1.0.0.tar.gz     | tar.gz   | linux    | stable   |
    And the first "release" has an artifacts that is uploaded
    And the second "release" has an artifacts that is uploaded
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products/$0/artifacts"
    Then the response status should be "200"
    And the JSON response should be an array with 2 "artifacts"

  Scenario: Product retrieves the artifacts for their product
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
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products/$0/artifacts"
    Then the response status should be "200"
    And the JSON response should be an array with 3 "artifacts"

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
    When I send a GET request to "/accounts/test1/products/$1/artifacts"
    Then the response status should be "403"

  Scenario: User attempts to retrieve the artifacts for a product (licensed)
    Given the current account is "test1"
    And the current account has 1 "user"
    And the current account has 1 "product"
    And the current account has 1 "policy" for an existing "product"
    And the current account has 1 "license" for an existing "policy"
    And the current account has 1 "release" for an existing "product"
    And all "releases" have artifacts that are uploaded
    And I am a user of account "test1"
    And the current user has 1 "license"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products/$0/artifacts"
    Then the response status should be "403"

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
    When I send a GET request to "/accounts/test1/products/$0/artifacts"
    Then the response status should be "403"

  Scenario: License attempts to retrieve the artifacts for their product
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "policy" for an existing "product"
    And the current account has 1 "license" for an existing "policy"
    And the current account has 3 "releases" for the first "product"
    And all "releases" have artifacts that are uploaded
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products/$0/artifacts"
    Then the response status should be "403"

  Scenario: License attempts to retrieve the artifacts for a different product
   Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "license"
    And the current account has 3 "releases" for the first "product"
    And all "releases" have artifacts that are uploaded
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products/$0/artifacts"
    Then the response status should be "403"

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
    When I send a GET request to "/accounts/test1/products/$0/artifacts"
    Then the response status should be "401"

  # Show artifact
  Scenario: Admin retrieves an artifact for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "product"
    And the current account has 3 "releases" for the first "product"
    And all "releases" have artifacts that are uploaded
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products/$0/artifacts/$0"
    Then the response status should be "303"
    And the JSON response should be an "artifact"

  Scenario: Developer retrieves an artifact for their account
    Given the current account is "test1"
    And the current account has 1 "developer"
    And I am a developer of account "test1"
    And the current account has 3 "releases"
    And all "releases" have artifacts that are uploaded
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products/$0/artifacts/$0"
    Then the response status should be "303"

  Scenario: Sales retrieves an artifact for their account
    Given the current account is "test1"
    And the current account has 1 "sales-agent"
    And I am a sales agent of account "test1"
    And the current account has 3 "releases"
    And all "releases" have artifacts that are uploaded
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products/$0/artifacts/$0"
    Then the response status should be "303"

  Scenario: Support retrieves an artifact for their account
    Given the current account is "test1"
    And the current account has 1 "support-agent"
    And I am a support agent of account "test1"
    And the current account has 3 "releases"
    And all "releases" have artifacts that are uploaded
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products/$0/artifacts/$0"
    Then the response status should be "303"

  Scenario: Admin retrieves an invalid artifact for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 1 "product"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products/$0/artifacts/invalid"
    Then the response status should be "404"
    And the first error should have the following properties:
      """
      {
        "title": "Not found",
        "detail": "The requested release artifact 'invalid' was not found"
      }
      """

  Scenario: Product retrieves an artifact for their product
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "release" for an existing "product"
    And the first "release" has an artifact that is uploaded
    And I am a product of account "test1"
    And I use an authentication token
    And the current product has 1 "release"
    When I send a GET request to "/accounts/test1/products/$0/artifacts/$0"
    Then the response status should be "303"
    And the JSON response should be an "artifact"

  Scenario: Product retrieves an artifact for another product
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "release"
    And the first "release" has an artifact that is uploaded
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products/$1/artifacts/$0"
    Then the response status should be "403"

  Scenario: User retrieves an artifact without a license for it
    Given the current account is "test1"
    And the current account has 1 "user"
    And the current account has 1 "release"
    And the first "release" has an artifact that is uploaded
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products/$0/artifacts/$0"
    Then the response status should be "403"

  Scenario: User retrieves an artifact with a license for it
    Given the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name   |
      | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | Test 1 |
    And the current account has the following "release" rows:
      | product_id                           | version      | filename              | filetype | platform | channel  |
      | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | 1.0.0        | Test-App-1.0.0.dmg    | dmg      | macos    | stable   |
      | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | 1.0.0        | Test-App-1.0.0.zip    | zip      | win32    | stable   |
      | 54a44eaf-6a83-4bb4-b3c1-17600dfdd77c | 1.0.0        | Test-App.1.0.0.tar.gz | tar.gz   | linux    | stable   |
    And the current account has 1 "policy" for an existing "product"
    And the current account has 1 "license" for an existing "policy"
    And the first "release" has an artifact that is uploaded
    And I am a user of account "test1"
    And I use an authentication token
    And the current user has 1 "license"
    When I send a GET request to "/accounts/test1/products/$0/artifacts/$0"
    Then the response status should be "403"

  Scenario: License retrieves an artifact of a different product
    Given the current account is "test1"
    And the current account has 1 "license"
    And the current account has 1 "release"
    And the first "release" has an artifact that is uploaded
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products/$0/artifacts/$0"
    Then the response status should be "403"

  Scenario: License retrieves an artifact of their product
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 1 "release" for an existing "product"
    And the current account has 1 "policy" for an existing "product"
    And the current account has 1 "license" for an existing "policy"
    And the first "release" has an artifact that is uploaded
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products/$0/artifacts/$0"
    Then the response status should be "403"

  Scenario: Anonymous retrieves an artifact
    Given the current account is "test1"
    And the current account has 1 "release"
    And the first "release" has an artifact that is uploaded
    When I send a GET request to "/accounts/test1/products/$0/artifacts/$0"
    Then the response status should be "401"

  Scenario: Admin attempts to retrieve an artifact for another account
    Given I am an admin of account "test2"
    But the current account is "test1"
    And the account "test1" has 3 "releases"
    And all "releases" have artifacts that are uploaded
    And I use an authentication token
    When I send a GET request to "/accounts/test1/products/$0/artifacts/$0"
    Then the response status should be "401"
    And the JSON response should be an array of 1 error

