@api/v1
Feature: List releases

  Background:
    Given the following "accounts" exist:
      | Name    | Slug  |
      | Test 1  | test1 |
      | Test 2  | test2 |
    And I send and accept JSON

  Scenario: Endpoint should be inaccessible when account is disabled
    Given the account "test1" is canceled
    And I am an admin of account "test1"
    And the current account is "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases"
    Then the response status should be "403"

  Scenario: Endpoint should be accessible when account is on free tier
    Given the account "test1" is on a free tier
    And the account "test1" is subscribed
    And I am an admin of account "test1"
    And the current account is "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases"
    Then the response status should be "200"

  Scenario: Admin retrieves all releases for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has the following "product" rows:
      | ID                                   | Name     |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test App |
    And the current account has the following "release" rows:
      | Product                              | Version      | Filename                  | Filetype | Platform | Channel  |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0        | Test-App-1.0.0.dmg        | dmg      | macos    | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.1        | Test-App-1.0.1.dmg        | dmg      | macos    | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.0        | Test-App-1.1.0.dmg        | dmg      | macos    | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.2.0-beta.1 | Test-App-1.2.0-beta.1.dmg | dmg      | macos    | beta     |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0-beta.1 | Test-App.1.0.0-beta.1.exe | exe      | win32    | beta     |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0-beta.2 | Test-App.1.0.0-beta.2.exe | exe      | win32    | beta     |
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases"
    Then the response status should be "200"
    And the JSON response should be an array with 6 "releases"

  Scenario: Admin retrieves all win32 beta releases for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has the following "product" rows:
      | ID                                   | Name     |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test App |
    And the current account has the following "release" rows:
      | Product                              | Version      | Filename                  | Filetype | Platform | Channel  |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0        | Test-App-1.0.0.dmg        | dmg      | macos    | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.1        | Test-App-1.0.1.dmg        | dmg      | macos    | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.0        | Test-App-1.1.0.dmg        | dmg      | macos    | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.2.0-beta.1 | Test-App-1.2.0-beta.1.dmg | dmg      | macos    | beta     |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0-beta.1 | Test-App.1.0.0-beta.1.exe | exe      | win32    | beta     |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0-beta.2 | Test-App.1.0.0-beta.2.exe | exe      | win32    | beta     |
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases?channel=beta&platform=win32"
    Then the response status should be "200"
    And the JSON response should be an array with 2 "releases"

  Scenario: Admin retrieves all win32 product releases for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has the following "product" rows:
      | ID                                   | Name    |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Mac App |
      | 121f9da8-dbe6-4d51-ac6c-dbbb024725ec | Win App |
    And the current account has the following "release" rows:
      | Product                              | Version      | Filename                  | Filetype | Platform | Channel  |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0        | Test-App-1.0.0.dmg        | dmg      | macos    | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.1        | Test-App-1.0.1.dmg        | dmg      | macos    | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.0        | Test-App-1.1.0.dmg        | dmg      | macos    | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.2.0-beta.1 | Test-App-1.2.0-beta.1.dmg | dmg      | macos    | beta     |
      | 121f9da8-dbe6-4d51-ac6c-dbbb024725ec | 1.0.0-beta.1 | Test-App.1.0.0-beta.1.exe | exe      | win32    | beta     |
      | 121f9da8-dbe6-4d51-ac6c-dbbb024725ec | 1.0.0-beta.2 | Test-App.1.0.0-beta.2.exe | exe      | win32    | beta     |
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases?product=121f9da8-dbe6-4d51-ac6c-dbbb024725ec"
    Then the response status should be "200"
    And the JSON response should be an array with 2 "releases"

  Scenario: Admin retrieves all stable releases for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has the following "product" rows:
      | ID                                   | Name    |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Mac App |
      | 121f9da8-dbe6-4d51-ac6c-dbbb024725ec | Win App |
    And the current account has the following "release" rows:
      | Product                              | Version       | Filename                   | Filetype | Platform | Channel  |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0         | Test-App-1.0.0.dmg         | dmg      | macos    | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.1         | Test-App-1.0.1.dmg         | dmg      | macos    | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.0         | Test-App-1.1.0.dmg         | dmg      | macos    | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.2.0-beta.1  | Test-App-1.2.0-beta.1.dmg  | dmg      | macos    | beta     |
      | 121f9da8-dbe6-4d51-ac6c-dbbb024725ec | 1.0.0-alpha.1 | Test-App.1.0.0-alpha.1.exe | exe      | win32    | alpha    |
      | 121f9da8-dbe6-4d51-ac6c-dbbb024725ec | 1.0.0-alpha.2 | Test-App.1.0.0-alpha.2.exe | exe      | win32    | alpha    |
      | 121f9da8-dbe6-4d51-ac6c-dbbb024725ec | 1.0.0-beta.1  | Test-App.1.0.0-beta.1.exe  | exe      | win32    | beta     |
      | 121f9da8-dbe6-4d51-ac6c-dbbb024725ec | 1.0.0-beta.2  | Test-App.1.0.0-beta.2.exe  | exe      | win32    | beta     |
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases?channel=stable"
    Then the response status should be "200"
    And the JSON response should be an array with 3 "releases"

  Scenario: Admin retrieves all beta releases for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has the following "product" rows:
      | ID                                   | Name    |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Mac App |
      | 121f9da8-dbe6-4d51-ac6c-dbbb024725ec | Win App |
    And the current account has the following "release" rows:
      | Product                              | Version       | Filename                   | Filetype | Platform | Channel  |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0         | Test-App-1.0.0.dmg         | dmg      | macos    | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.1         | Test-App-1.0.1.dmg         | dmg      | macos    | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.0         | Test-App-1.1.0.dmg         | dmg      | macos    | stable   |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.2.0-beta.1  | Test-App-1.2.0-beta.1.dmg  | dmg      | macos    | beta     |
      | 121f9da8-dbe6-4d51-ac6c-dbbb024725ec | 1.0.0-alpha.1 | Test-App.1.0.0-alpha.1.exe | exe      | win32    | alpha    |
      | 121f9da8-dbe6-4d51-ac6c-dbbb024725ec | 1.0.0-alpha.2 | Test-App.1.0.0-alpha.2.exe | exe      | win32    | alpha    |
      | 121f9da8-dbe6-4d51-ac6c-dbbb024725ec | 1.0.0-beta.1  | Test-App.1.0.0-beta.1.exe  | exe      | win32    | beta     |
      | 121f9da8-dbe6-4d51-ac6c-dbbb024725ec | 1.0.0-beta.2  | Test-App.1.0.0-beta.2.exe  | exe      | win32    | beta     |
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases?channel=beta"
    Then the response status should be "200"
    And the JSON response should be an array with 6 "releases"

  Scenario: Admin retrieves all v1.0.0 releases for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has the following "product" rows:
      | ID                                   | Name     |
      | 850b55ca-f0a1-4a66-9d29-aa199d62db0c | Test App |
    And the current account has the following "release" rows:
      | Product                              | Version       | Filename                   | Filetype | Platform | Channel  |
      | 850b55ca-f0a1-4a66-9d29-aa199d62db0c | 1.0.0         | Test-App-1.0.0.dmg         | dmg      | macos    | stable   |
      | 850b55ca-f0a1-4a66-9d29-aa199d62db0c | 1.1.0         | Test-App-1.1.0.dmg         | dmg      | macos    | stable   |
      | 850b55ca-f0a1-4a66-9d29-aa199d62db0c | 1.2.0-beta.1  | Test-App-1.2.0-beta.1.dmg  | dmg      | macos    | beta     |
      | 850b55ca-f0a1-4a66-9d29-aa199d62db0c | 1.0.0-alpha.2 | Test-App.1.0.0-alpha.2.exe | exe      | win32    | alpha    |
      | 850b55ca-f0a1-4a66-9d29-aa199d62db0c | 1.0.0-beta.1  | Test-App.1.0.0-beta.1.exe  | exe      | win32    | beta     |
      | 850b55ca-f0a1-4a66-9d29-aa199d62db0c | 1.0.0         | Test-App.1.0.0.exe         | exe      | win32    | stable   |
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases?version=1.0.0"
    Then the response status should be "200"
    And the JSON response should be an array with 2 "releases"
