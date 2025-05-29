@api/v1
Feature: List releases
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
      | id                                   | name     |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test App |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | version      | channel  |
      | 757e0a41-835e-42ad-bad8-84cabd29c72a | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0        | stable   |
      | 3ff04fc6-9f10-4b84-b548-eb40f92ea331 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.1        | stable   |
      | 028a38a2-0d17-4871-acb8-c5e6f040fc12 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.0        | stable   |
      | 972aa5b8-b12c-49f4-8ba4-7c9ae053dfa2 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.2.0-beta.1 | beta     |
      | 28a6e16d-c2a6-4be7-8578-e236182ee5c3 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0-beta.1 | beta     |
      | 70c40946-4b23-408c-aa1c-fa35421ff46a | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0-beta.2 | beta     |
    And the current account has the following "artifact" rows:
      | release_id                           | filename                  | filetype | platform |
      | 757e0a41-835e-42ad-bad8-84cabd29c72a | Test-App-1.0.0.dmg        | dmg      | macos    |
      | 3ff04fc6-9f10-4b84-b548-eb40f92ea331 | Test-App-1.0.1.dmg        | dmg      | macos    |
      | 028a38a2-0d17-4871-acb8-c5e6f040fc12 | Test-App-1.1.0.dmg        | dmg      | macos    |
      | 972aa5b8-b12c-49f4-8ba4-7c9ae053dfa2 | Test-App-1.2.0-beta.1.dmg | dmg      | macos    |
      | 28a6e16d-c2a6-4be7-8578-e236182ee5c3 | Test-App.1.0.0-beta.1.exe | exe      | win32    |
      | 70c40946-4b23-408c-aa1c-fa35421ff46a | Test-App.1.0.0-beta.2.exe | exe      | win32    |
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases"
    Then the response status should be "200"
    And the response body should be an array with 6 "releases"
    And the first "release" should have the following relationships:
      """
      {
        "artifacts": {
          "links": { "related": "/v1/accounts/$account/releases/70c40946-4b23-408c-aa1c-fa35421ff46a/artifacts" }
        }
      }
      """
    And the second "release" should have the following relationships:
      """
      {
        "artifacts": {
          "links": { "related": "/v1/accounts/$account/releases/28a6e16d-c2a6-4be7-8578-e236182ee5c3/artifacts" }
        }
      }
      """
    And the third "release" should have the following relationships:
      """
      {
        "artifacts": {
          "links": { "related": "/v1/accounts/$account/releases/972aa5b8-b12c-49f4-8ba4-7c9ae053dfa2/artifacts" }
        }
      }
      """

  Scenario: Admin retrieves all releases for their account (v1.1)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "releases"
    And the current account has 1 "artifact" for the first "release"
    And I use an authentication token
    And I use API version "1.1"
    When I send a GET request to "/accounts/test1/releases"
    Then the response status should be "200"
    And the response body should be an array with 2 "releases"
    And the first "release" should have the following relationships:
      """
      {
        "artifacts": {
          "links": { "related": "/v1/accounts/$account/releases/$releases[1]/artifacts" }
        }
      }
      """
    And the second "release" should have the following relationships:
      """
      {
        "artifacts": {
          "links": { "related": "/v1/accounts/$account/releases/$releases[0]/artifacts" }
        }
      }
      """
    Then the response should contain the following headers:
      """
      { "Keygen-Version": "1.1" }
      """

  Scenario: Admin retrieves all releases for their account (v1.0)
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has 2 "releases"
    And the current account has 1 "artifact" for the first "release"
    And I use an authentication token
    And I use API version "1.0"
    When I send a GET request to "/accounts/test1/releases"
    Then the response status should be "200"
    And the response body should be an array with 2 "releases"
    And the first "release" should have the following relationships:
      """
      {
        "artifact": {
          "links": { "related": "/v1/accounts/$account/releases/$releases[1]/artifact" },
          "data": null
        }
      }
      """
    And the second "release" should have the following relationships:
      """
      {
        "artifact": {
          "links": { "related": "/v1/accounts/$account/releases/$releases[0]/artifact" },
          "data": { "type": "artifacts", "id": "$artifacts[0]" }
        }
      }
      """
    Then the response should contain the following headers:
      """
      { "Keygen-Version": "1.0" }
      """

  Scenario: Admin retrieves all beta releases filtered by platform
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name     |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test App |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | version      | channel  |
      | 757e0a41-835e-42ad-bad8-84cabd29c72a | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0        | stable   |
      | 3ff04fc6-9f10-4b84-b548-eb40f92ea331 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.1        | stable   |
      | 028a38a2-0d17-4871-acb8-c5e6f040fc12 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.0        | stable   |
      | 972aa5b8-b12c-49f4-8ba4-7c9ae053dfa2 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.2.0-beta.1 | beta     |
      | 28a6e16d-c2a6-4be7-8578-e236182ee5c3 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0-beta.1 | beta     |
      | 70c40946-4b23-408c-aa1c-fa35421ff46a | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0-beta.2 | beta     |
    And the current account has the following "artifact" rows:
      | release_id                           | filename                  | filetype | platform |
      | 757e0a41-835e-42ad-bad8-84cabd29c72a | Test-App-1.0.0.dmg        | dmg      | macos    |
      | 3ff04fc6-9f10-4b84-b548-eb40f92ea331 | Test-App-1.0.1.dmg        | dmg      | macos    |
      | 028a38a2-0d17-4871-acb8-c5e6f040fc12 | Test-App-1.1.0.dmg        | dmg      | macos    |
      | 972aa5b8-b12c-49f4-8ba4-7c9ae053dfa2 | Test-App-1.2.0-beta.1.dmg | dmg      | macos    |
      | 28a6e16d-c2a6-4be7-8578-e236182ee5c3 | Test-App.1.0.0-beta.1.exe | exe      | win32    |
      | 70c40946-4b23-408c-aa1c-fa35421ff46a | Test-App.1.0.0-beta.2.exe | exe      | win32    |
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases?channel=beta&platform=win32"
    Then the response status should be "200"
    And the response body should be an array with 6 "releases"

  Scenario: Admin retrieves all releases filtered by arch
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name     |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test App |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | version      | channel  |
      | 757e0a41-835e-42ad-bad8-84cabd29c72a | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0        | stable   |
      | 3ff04fc6-9f10-4b84-b548-eb40f92ea331 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.1        | stable   |
      | 028a38a2-0d17-4871-acb8-c5e6f040fc12 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.0        | stable   |
      | 972aa5b8-b12c-49f4-8ba4-7c9ae053dfa2 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.2.0-beta.1 | beta     |
      | 28a6e16d-c2a6-4be7-8578-e236182ee5c3 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0-beta.1 | beta     |
      | 70c40946-4b23-408c-aa1c-fa35421ff46a | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0-beta.2 | beta     |
    And the current account has the following "artifact" rows:
      | release_id                           | filename                  | filetype | platform | arch |
      | 757e0a41-835e-42ad-bad8-84cabd29c72a | Test-App-1.0.0.dmg        | dmg      | macos    | x86  |
      | 3ff04fc6-9f10-4b84-b548-eb40f92ea331 | Test-App-1.0.1.dmg        | dmg      | macos    | x86  |
      | 028a38a2-0d17-4871-acb8-c5e6f040fc12 | Test-App-1.1.0.dmg        | dmg      | macos    | x86  |
      | 972aa5b8-b12c-49f4-8ba4-7c9ae053dfa2 | Test-App-1.2.0-beta.1.dmg | dmg      | macos    | x86  |
      | 28a6e16d-c2a6-4be7-8578-e236182ee5c3 | Test-App.1.0.0-beta.1.exe | exe      | win32    | x64  |
      | 70c40946-4b23-408c-aa1c-fa35421ff46a | Test-App.1.0.0-beta.2.exe | exe      | win32    | x86  |
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases?arch=x64"
    Then the response status should be "200"
    And the response body should be an array with 6 "releases"

  Scenario: Admin retrieves all win32 product releases for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name    |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Mac App |
      | 121f9da8-dbe6-4d51-ac6c-dbbb024725ec | Win App |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | version      | channel  |
      | 757e0a41-835e-42ad-bad8-84cabd29c72a | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0        | stable   |
      | 3ff04fc6-9f10-4b84-b548-eb40f92ea331 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.1        | stable   |
      | 028a38a2-0d17-4871-acb8-c5e6f040fc12 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.0        | stable   |
      | 972aa5b8-b12c-49f4-8ba4-7c9ae053dfa2 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.2.0-beta.1 | beta     |
      | 28a6e16d-c2a6-4be7-8578-e236182ee5c3 | 121f9da8-dbe6-4d51-ac6c-dbbb024725ec | 1.0.0-beta.1 | beta     |
      | 70c40946-4b23-408c-aa1c-fa35421ff46a | 121f9da8-dbe6-4d51-ac6c-dbbb024725ec | 1.0.0-beta.2 | beta     |
    And the current account has the following "artifact" rows:
      | release_id                           | filename                  | filetype | platform |
      | 757e0a41-835e-42ad-bad8-84cabd29c72a | Test-App-1.0.0.dmg        | dmg      | macos    |
      | 3ff04fc6-9f10-4b84-b548-eb40f92ea331 | Test-App-1.0.1.dmg        | dmg      | macos    |
      | 028a38a2-0d17-4871-acb8-c5e6f040fc12 | Test-App-1.1.0.dmg        | dmg      | macos    |
      | 972aa5b8-b12c-49f4-8ba4-7c9ae053dfa2 | Test-App-1.2.0-beta.1.dmg | dmg      | macos    |
      | 28a6e16d-c2a6-4be7-8578-e236182ee5c3 | Test-App.1.0.0-beta.1.exe | exe      | win32    |
      | 70c40946-4b23-408c-aa1c-fa35421ff46a | Test-App.1.0.0-beta.2.exe | exe      | win32    |
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases?product=121f9da8-dbe6-4d51-ac6c-dbbb024725ec&channel=alpha"
    Then the response status should be "200"
    And the response body should be an array with 2 "releases"

  Scenario: Admin retrieves all stable releases for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name    |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Mac App |
      | 121f9da8-dbe6-4d51-ac6c-dbbb024725ec | Win App |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | version       | channel  |
      | 757e0a41-835e-42ad-bad8-84cabd29c72a | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0         | stable   |
      | 3ff04fc6-9f10-4b84-b548-eb40f92ea331 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.1         | stable   |
      | 028a38a2-0d17-4871-acb8-c5e6f040fc12 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.0         | stable   |
      | 571114ac-af22-4d4b-99ce-f0e3d921c192 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.2.0-rc.1    | rc       |
      | 972aa5b8-b12c-49f4-8ba4-7c9ae053dfa2 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.2.0-beta.1  | beta     |
      | 28a6e16d-c2a6-4be7-8578-e236182ee5c3 | 121f9da8-dbe6-4d51-ac6c-dbbb024725ec | 1.0.0-alpha.1 | alpha    |
      | 70c40946-4b23-408c-aa1c-fa35421ff46a | 121f9da8-dbe6-4d51-ac6c-dbbb024725ec | 1.0.0-alpha.2 | alpha    |
      | ab9a4dcd-9ef8-48f7-985e-53534540f73f | 121f9da8-dbe6-4d51-ac6c-dbbb024725ec | 1.0.0-beta.1  | beta     |
      | 2d2e4756-0ff8-4142-8132-762f836a0c76 | 121f9da8-dbe6-4d51-ac6c-dbbb024725ec | 1.0.0-beta.2  | beta     |
      | 7cad471e-cc3c-4378-847e-8a5b821d0ca1 | 121f9da8-dbe6-4d51-ac6c-dbbb024725ec | 1.0.0-dev.1   | dev      |
    And the current account has the following "artifact" rows:
      | release_id                           | filename                   | filetype | platform |
      | 757e0a41-835e-42ad-bad8-84cabd29c72a | Test-App-1.0.0.dmg         | dmg      | macos    |
      | 3ff04fc6-9f10-4b84-b548-eb40f92ea331 | Test-App-1.0.1.dmg         | dmg      | macos    |
      | 028a38a2-0d17-4871-acb8-c5e6f040fc12 | Test-App-1.1.0.dmg         | dmg      | macos    |
      | 571114ac-af22-4d4b-99ce-f0e3d921c192 | Test-App-1.2.0-rc.1.dmg    | dmg      | macos    |
      | 972aa5b8-b12c-49f4-8ba4-7c9ae053dfa2 | Test-App-1.2.0-beta.1.dmg  | dmg      | macos    |
      | 28a6e16d-c2a6-4be7-8578-e236182ee5c3 | Test-App.1.0.0-alpha.1.exe | exe      | win32    |
      | 70c40946-4b23-408c-aa1c-fa35421ff46a | Test-App.1.0.0-alpha.2.exe | exe      | win32    |
      | ab9a4dcd-9ef8-48f7-985e-53534540f73f | Test-App.1.0.0-beta.1.exe  | exe      | win32    |
      | 2d2e4756-0ff8-4142-8132-762f836a0c76 | Test-App.1.0.0-beta.2.exe  | exe      | win32    |
      | 7cad471e-cc3c-4378-847e-8a5b821d0ca1 | Test-App.1.0.0-dev.1.exe   | exe      | win32    |
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases?channel=stable"
    Then the response status should be "200"
    And the response body should be an array with 3 "releases"
    And the first "release" should have the following data:
      """
      { "id": "028a38a2-0d17-4871-acb8-c5e6f040fc12" }
      """
    And the second "release" should have the following data:
      """
      { "id": "3ff04fc6-9f10-4b84-b548-eb40f92ea331" }
      """
    And the third "release" should have the following data:
      """
      { "id": "757e0a41-835e-42ad-bad8-84cabd29c72a" }
      """

  Scenario: Admin retrieves all beta releases for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name    |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Mac App |
      | 121f9da8-dbe6-4d51-ac6c-dbbb024725ec | Win App |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | version       | channel  |
      | 757e0a41-835e-42ad-bad8-84cabd29c72a | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0         | stable   |
      | 3ff04fc6-9f10-4b84-b548-eb40f92ea331 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.1         | stable   |
      | 028a38a2-0d17-4871-acb8-c5e6f040fc12 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.0         | stable   |
      | 571114ac-af22-4d4b-99ce-f0e3d921c192 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.2.0-rc.1    | rc       |
      | 972aa5b8-b12c-49f4-8ba4-7c9ae053dfa2 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.2.0-beta.1  | beta     |
      | 28a6e16d-c2a6-4be7-8578-e236182ee5c3 | 121f9da8-dbe6-4d51-ac6c-dbbb024725ec | 1.0.0-alpha.1 | alpha    |
      | 70c40946-4b23-408c-aa1c-fa35421ff46a | 121f9da8-dbe6-4d51-ac6c-dbbb024725ec | 1.0.0-alpha.2 | alpha    |
      | ab9a4dcd-9ef8-48f7-985e-53534540f73f | 121f9da8-dbe6-4d51-ac6c-dbbb024725ec | 1.0.0-beta.1  | beta     |
      | 2d2e4756-0ff8-4142-8132-762f836a0c76 | 121f9da8-dbe6-4d51-ac6c-dbbb024725ec | 1.0.0-beta.2  | beta     |
      | 7cad471e-cc3c-4378-847e-8a5b821d0ca1 | 121f9da8-dbe6-4d51-ac6c-dbbb024725ec | 1.0.0-dev.1   | dev      |
    And the current account has the following "artifact" rows:
      | release_id                           | filename                   | filetype | platform |
      | 757e0a41-835e-42ad-bad8-84cabd29c72a | Test-App-1.0.0.dmg         | dmg      | macos    |
      | 3ff04fc6-9f10-4b84-b548-eb40f92ea331 | Test-App-1.0.1.dmg         | dmg      | macos    |
      | 028a38a2-0d17-4871-acb8-c5e6f040fc12 | Test-App-1.1.0.dmg         | dmg      | macos    |
      | 571114ac-af22-4d4b-99ce-f0e3d921c192 | Test-App-1.2.0-rc.1.dmg    | dmg      | macos    |
      | 972aa5b8-b12c-49f4-8ba4-7c9ae053dfa2 | Test-App-1.2.0-beta.1.dmg  | dmg      | macos    |
      | 28a6e16d-c2a6-4be7-8578-e236182ee5c3 | Test-App.1.0.0-alpha.1.exe | exe      | win32    |
      | 70c40946-4b23-408c-aa1c-fa35421ff46a | Test-App.1.0.0-alpha.2.exe | exe      | win32    |
      | ab9a4dcd-9ef8-48f7-985e-53534540f73f | Test-App.1.0.0-beta.1.exe  | exe      | win32    |
      | 2d2e4756-0ff8-4142-8132-762f836a0c76 | Test-App.1.0.0-beta.2.exe  | exe      | win32    |
      | 7cad471e-cc3c-4378-847e-8a5b821d0ca1 | Test-App.1.0.0-dev.1.exe   | exe      | win32    |
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases?channel=beta"
    Then the response status should be "200"
    And the response body should be an array with 7 "releases"
    And the first "release" should have the following data:
      """
      { "id": "2d2e4756-0ff8-4142-8132-762f836a0c76" }
      """
    And the second "release" should have the following data:
      """
      { "id": "ab9a4dcd-9ef8-48f7-985e-53534540f73f" }
      """
    And the third "release" should have the following data:
      """
      { "id": "972aa5b8-b12c-49f4-8ba4-7c9ae053dfa2" }
      """
    And the fourth "release" should have the following data:
      """
      { "id": "571114ac-af22-4d4b-99ce-f0e3d921c192" }
      """
    And the fifth "release" should have the following data:
      """
      { "id": "028a38a2-0d17-4871-acb8-c5e6f040fc12" }
      """

  Scenario: Admin retrieves all rc releases for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name    |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Mac App |
      | 121f9da8-dbe6-4d51-ac6c-dbbb024725ec | Win App |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | version       | channel  |
      | 757e0a41-835e-42ad-bad8-84cabd29c72a | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0         | stable   |
      | 3ff04fc6-9f10-4b84-b548-eb40f92ea331 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.1         | stable   |
      | 028a38a2-0d17-4871-acb8-c5e6f040fc12 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.0         | stable   |
      | 571114ac-af22-4d4b-99ce-f0e3d921c192 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.2.0-rc.1    | rc       |
      | 972aa5b8-b12c-49f4-8ba4-7c9ae053dfa2 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.2.0-beta.1  | beta     |
      | 28a6e16d-c2a6-4be7-8578-e236182ee5c3 | 121f9da8-dbe6-4d51-ac6c-dbbb024725ec | 1.0.0-alpha.1 | alpha    |
      | 70c40946-4b23-408c-aa1c-fa35421ff46a | 121f9da8-dbe6-4d51-ac6c-dbbb024725ec | 1.0.0-alpha.2 | alpha    |
      | ab9a4dcd-9ef8-48f7-985e-53534540f73f | 121f9da8-dbe6-4d51-ac6c-dbbb024725ec | 1.0.0-beta.1  | beta     |
      | 2d2e4756-0ff8-4142-8132-762f836a0c76 | 121f9da8-dbe6-4d51-ac6c-dbbb024725ec | 1.0.0-beta.2  | beta     |
      | 7cad471e-cc3c-4378-847e-8a5b821d0ca1 | 121f9da8-dbe6-4d51-ac6c-dbbb024725ec | 1.0.0-dev.1   | dev      |
    And the current account has the following "artifact" rows:
      | release_id                           | filename                   | filetype | platform |
      | 757e0a41-835e-42ad-bad8-84cabd29c72a | Test-App-1.0.0.dmg         | dmg      | macos    |
      | 3ff04fc6-9f10-4b84-b548-eb40f92ea331 | Test-App-1.0.1.dmg         | dmg      | macos    |
      | 028a38a2-0d17-4871-acb8-c5e6f040fc12 | Test-App-1.1.0.dmg         | dmg      | macos    |
      | 571114ac-af22-4d4b-99ce-f0e3d921c192 | Test-App-1.2.0-rc.1.dmg    | dmg      | macos    |
      | 972aa5b8-b12c-49f4-8ba4-7c9ae053dfa2 | Test-App-1.2.0-beta.1.dmg  | dmg      | macos    |
      | 28a6e16d-c2a6-4be7-8578-e236182ee5c3 | Test-App.1.0.0-alpha.1.exe | exe      | win32    |
      | 70c40946-4b23-408c-aa1c-fa35421ff46a | Test-App.1.0.0-alpha.2.exe | exe      | win32    |
      | ab9a4dcd-9ef8-48f7-985e-53534540f73f | Test-App.1.0.0-beta.1.exe  | exe      | win32    |
      | 2d2e4756-0ff8-4142-8132-762f836a0c76 | Test-App.1.0.0-beta.2.exe  | exe      | win32    |
      | 7cad471e-cc3c-4378-847e-8a5b821d0ca1 | Test-App.1.0.0-dev.1.exe   | exe      | win32    |
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases?channel=rc"
    Then the response status should be "200"
    And the response body should be an array with 4 "releases"
    And the first "release" should have the following data:
      """
      { "id": "571114ac-af22-4d4b-99ce-f0e3d921c192" }
      """
    And the second "release" should have the following data:
      """
      { "id": "028a38a2-0d17-4871-acb8-c5e6f040fc12" }
      """
    And the third "release" should have the following data:
      """
      { "id": "3ff04fc6-9f10-4b84-b548-eb40f92ea331" }
      """
    And the fourth "release" should have the following data:
      """
      { "id": "757e0a41-835e-42ad-bad8-84cabd29c72a" }
      """

  Scenario: Admin retrieves all alpha releases for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name    |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Mac App |
      | 121f9da8-dbe6-4d51-ac6c-dbbb024725ec | Win App |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | version       | channel  |
      | 757e0a41-835e-42ad-bad8-84cabd29c72a | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0         | stable   |
      | 3ff04fc6-9f10-4b84-b548-eb40f92ea331 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.1         | stable   |
      | 028a38a2-0d17-4871-acb8-c5e6f040fc12 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.0         | stable   |
      | 571114ac-af22-4d4b-99ce-f0e3d921c192 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.2.0-rc.1    | rc       |
      | 972aa5b8-b12c-49f4-8ba4-7c9ae053dfa2 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.2.0-beta.1  | beta     |
      | 28a6e16d-c2a6-4be7-8578-e236182ee5c3 | 121f9da8-dbe6-4d51-ac6c-dbbb024725ec | 1.0.0-alpha.1 | alpha    |
      | 70c40946-4b23-408c-aa1c-fa35421ff46a | 121f9da8-dbe6-4d51-ac6c-dbbb024725ec | 1.0.0-alpha.2 | alpha    |
      | ab9a4dcd-9ef8-48f7-985e-53534540f73f | 121f9da8-dbe6-4d51-ac6c-dbbb024725ec | 1.0.0-beta.1  | beta     |
      | 2d2e4756-0ff8-4142-8132-762f836a0c76 | 121f9da8-dbe6-4d51-ac6c-dbbb024725ec | 1.0.0-beta.2  | beta     |
      | 7cad471e-cc3c-4378-847e-8a5b821d0ca1 | 121f9da8-dbe6-4d51-ac6c-dbbb024725ec | 1.0.0-dev.1   | dev      |
    And the current account has the following "artifact" rows:
      | release_id                           | filename                   | filetype | platform |
      | 757e0a41-835e-42ad-bad8-84cabd29c72a | Test-App-1.0.0.dmg         | dmg      | macos    |
      | 3ff04fc6-9f10-4b84-b548-eb40f92ea331 | Test-App-1.0.1.dmg         | dmg      | macos    |
      | 028a38a2-0d17-4871-acb8-c5e6f040fc12 | Test-App-1.1.0.dmg         | dmg      | macos    |
      | 571114ac-af22-4d4b-99ce-f0e3d921c192 | Test-App-1.2.0-rc.1.dmg    | dmg      | macos    |
      | 972aa5b8-b12c-49f4-8ba4-7c9ae053dfa2 | Test-App-1.2.0-beta.1.dmg  | dmg      | macos    |
      | 28a6e16d-c2a6-4be7-8578-e236182ee5c3 | Test-App.1.0.0-alpha.1.exe | exe      | win32    |
      | 70c40946-4b23-408c-aa1c-fa35421ff46a | Test-App.1.0.0-alpha.2.exe | exe      | win32    |
      | ab9a4dcd-9ef8-48f7-985e-53534540f73f | Test-App.1.0.0-beta.1.exe  | exe      | win32    |
      | 2d2e4756-0ff8-4142-8132-762f836a0c76 | Test-App.1.0.0-beta.2.exe  | exe      | win32    |
      | 7cad471e-cc3c-4378-847e-8a5b821d0ca1 | Test-App.1.0.0-dev.1.exe   | exe      | win32    |
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases?channel=alpha"
    Then the response status should be "200"
    And the response body should be an array with 9 "releases"

  Scenario: Admin retrieves all dev releases for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name    |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Mac App |
      | 121f9da8-dbe6-4d51-ac6c-dbbb024725ec | Win App |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | version       | channel  |
      | 757e0a41-835e-42ad-bad8-84cabd29c72a | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.0         | stable   |
      | 3ff04fc6-9f10-4b84-b548-eb40f92ea331 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.0.1         | stable   |
      | 028a38a2-0d17-4871-acb8-c5e6f040fc12 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.1.0         | stable   |
      | 571114ac-af22-4d4b-99ce-f0e3d921c192 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.2.0-rc.1    | rc       |
      | 972aa5b8-b12c-49f4-8ba4-7c9ae053dfa2 | 6198261a-48b5-4445-a045-9fed4afc7735 | 1.2.0-beta.1  | beta     |
      | 28a6e16d-c2a6-4be7-8578-e236182ee5c3 | 121f9da8-dbe6-4d51-ac6c-dbbb024725ec | 1.0.0-alpha.1 | alpha    |
      | 70c40946-4b23-408c-aa1c-fa35421ff46a | 121f9da8-dbe6-4d51-ac6c-dbbb024725ec | 1.0.0-alpha.2 | alpha    |
      | ab9a4dcd-9ef8-48f7-985e-53534540f73f | 121f9da8-dbe6-4d51-ac6c-dbbb024725ec | 1.0.0-beta.1  | beta     |
      | 2d2e4756-0ff8-4142-8132-762f836a0c76 | 121f9da8-dbe6-4d51-ac6c-dbbb024725ec | 1.0.0-beta.2  | beta     |
      | 7cad471e-cc3c-4378-847e-8a5b821d0ca1 | 121f9da8-dbe6-4d51-ac6c-dbbb024725ec | 1.0.0-dev.1   | dev      |
    And the current account has the following "artifact" rows:
      | release_id                           | filename                   | filetype | platform |
      | 757e0a41-835e-42ad-bad8-84cabd29c72a | Test-App-1.0.0.dmg         | dmg      | macos    |
      | 3ff04fc6-9f10-4b84-b548-eb40f92ea331 | Test-App-1.0.1.dmg         | dmg      | macos    |
      | 028a38a2-0d17-4871-acb8-c5e6f040fc12 | Test-App-1.1.0.dmg         | dmg      | macos    |
      | 571114ac-af22-4d4b-99ce-f0e3d921c192 | Test-App-1.2.0-rc.1.dmg    | dmg      | macos    |
      | 972aa5b8-b12c-49f4-8ba4-7c9ae053dfa2 | Test-App-1.2.0-beta.1.dmg  | dmg      | macos    |
      | 28a6e16d-c2a6-4be7-8578-e236182ee5c3 | Test-App.1.0.0-alpha.1.exe | exe      | win32    |
      | 70c40946-4b23-408c-aa1c-fa35421ff46a | Test-App.1.0.0-alpha.2.exe | exe      | win32    |
      | ab9a4dcd-9ef8-48f7-985e-53534540f73f | Test-App.1.0.0-beta.1.exe  | exe      | win32    |
      | 2d2e4756-0ff8-4142-8132-762f836a0c76 | Test-App.1.0.0-beta.2.exe  | exe      | win32    |
      | 7cad471e-cc3c-4378-847e-8a5b821d0ca1 | Test-App.1.0.0-dev.1.exe   | exe      | win32    |
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases?channel=dev"
    Then the response status should be "200"
    And the response body should be an array with 1 "release"
    And the first "release" should have the following relationships:
      """
      {
        "artifacts": {
          "links": { "related": "/v1/accounts/$account/releases/7cad471e-cc3c-4378-847e-8a5b821d0ca1/artifacts" }
        }
      }
      """

  Scenario: Admin retrieves all releases filtered by version
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name     |
      | 850b55ca-f0a1-4a66-9d29-aa199d62db0c | Test App |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | version       | channel  |
      | 757e0a41-835e-42ad-bad8-84cabd29c72a | 850b55ca-f0a1-4a66-9d29-aa199d62db0c | 1.0.0         | stable   |
      | 3ff04fc6-9f10-4b84-b548-eb40f92ea331 | 850b55ca-f0a1-4a66-9d29-aa199d62db0c | 1.1.0         | stable   |
      | 028a38a2-0d17-4871-acb8-c5e6f040fc12 | 850b55ca-f0a1-4a66-9d29-aa199d62db0c | 1.2.0-beta.1  | beta     |
      | 571114ac-af22-4d4b-99ce-f0e3d921c192 | 850b55ca-f0a1-4a66-9d29-aa199d62db0c | 1.0.0-alpha.2 | alpha    |
      | 972aa5b8-b12c-49f4-8ba4-7c9ae053dfa2 | 850b55ca-f0a1-4a66-9d29-aa199d62db0c | 1.0.0-beta.1  | beta     |
    And the current account has the following "artifact" rows:
      | release_id                           | filename                   | filetype | platform |
      | 757e0a41-835e-42ad-bad8-84cabd29c72a | Test-App-1.0.0.dmg         | dmg      | macos    |
      | 757e0a41-835e-42ad-bad8-84cabd29c72a | Test-App.1.0.0.exe         | exe      | win32    |
      | 3ff04fc6-9f10-4b84-b548-eb40f92ea331 | Test-App-1.1.0.dmg         | dmg      | macos    |
      | 028a38a2-0d17-4871-acb8-c5e6f040fc12 | Test-App-1.2.0-beta.1.dmg  | dmg      | macos    |
      | 571114ac-af22-4d4b-99ce-f0e3d921c192 | Test-App.1.0.0-alpha.2.exe | exe      | win32    |
      | 972aa5b8-b12c-49f4-8ba4-7c9ae053dfa2 | Test-App.1.0.0-beta.1.exe  | exe      | win32    |
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases?version=1.0.0"
    Then the response status should be "200"
    And the response body should be an array with 5 "releases"

  Scenario: Admin retrieves all releases filtered by filetype
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name     |
      | 850b55ca-f0a1-4a66-9d29-aa199d62db0c | Test App |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | version       | channel  |
      | 757e0a41-835e-42ad-bad8-84cabd29c72a | 850b55ca-f0a1-4a66-9d29-aa199d62db0c | 1.0.0         | stable   |
      | 3ff04fc6-9f10-4b84-b548-eb40f92ea331 | 850b55ca-f0a1-4a66-9d29-aa199d62db0c | 1.1.0         | stable   |
      | 028a38a2-0d17-4871-acb8-c5e6f040fc12 | 850b55ca-f0a1-4a66-9d29-aa199d62db0c | 1.2.0-beta.1  | beta     |
      | 571114ac-af22-4d4b-99ce-f0e3d921c192 | 850b55ca-f0a1-4a66-9d29-aa199d62db0c | 1.0.0-alpha.2 | alpha    |
      | 972aa5b8-b12c-49f4-8ba4-7c9ae053dfa2 | 850b55ca-f0a1-4a66-9d29-aa199d62db0c | 1.0.0-beta.1  | beta     |
    And the current account has the following "artifact" rows:
      | release_id                           | filename                   | filetype | platform |
      | 757e0a41-835e-42ad-bad8-84cabd29c72a | Test-App-1.0.0.dmg         | dmg      | macos    |
      | 757e0a41-835e-42ad-bad8-84cabd29c72a | Test-App.1.0.0.exe         | exe      | win32    |
      | 3ff04fc6-9f10-4b84-b548-eb40f92ea331 | Test-App-1.1.0.dmg         | dmg      | macos    |
      | 028a38a2-0d17-4871-acb8-c5e6f040fc12 | Test-App-1.2.0-beta.1.dmg  | dmg      | macos    |
      | 571114ac-af22-4d4b-99ce-f0e3d921c192 | Test-App.1.0.0-alpha.2.exe | exe      | win32    |
      | 972aa5b8-b12c-49f4-8ba4-7c9ae053dfa2 | Test-App.1.0.0-beta.1.exe  | exe      | win32    |
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases?filetype=tar.gz"
    Then the response status should be "200"
    And the response body should be an array with 5 "releases"

  Scenario: Admin retrieves all non-yanked stable releases for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name     |
      | 850b55ca-f0a1-4a66-9d29-aa199d62db0c | Test App |
    And the current account has the following "release" rows:
      | product_id                           | version       | channel | status    |
      | 850b55ca-f0a1-4a66-9d29-aa199d62db0c | 1.0.0         | stable  | PUBLISHED |
      | 850b55ca-f0a1-4a66-9d29-aa199d62db0c | 1.1.0         | stable  | PUBLISHED |
      | 850b55ca-f0a1-4a66-9d29-aa199d62db0c | 1.2.0-beta.1  | beta    | YANKED    |
      | 850b55ca-f0a1-4a66-9d29-aa199d62db0c | 1.2.0         | stable  | PUBLISHED |
      | 850b55ca-f0a1-4a66-9d29-aa199d62db0c | 1.0.0-alpha.2 | alpha   | DRAFT     |
      | 850b55ca-f0a1-4a66-9d29-aa199d62db0c | 1.0.0-beta.1  | beta    | DRAFT     |
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases?yanked=false&channel=stable"
    Then the response status should be "200"
    And the response body should be an array with 3 "releases"

  Scenario: Admin retrieves all non-yanked releases for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name     |
      | 850b55ca-f0a1-4a66-9d29-aa199d62db0c | Test App |
    And the current account has the following "release" rows:
      | product_id                           | version       | channel | status    |
      | 850b55ca-f0a1-4a66-9d29-aa199d62db0c | 1.0.0         | stable  | PUBLISHED |
      | 850b55ca-f0a1-4a66-9d29-aa199d62db0c | 1.1.0         | stable  | PUBLISHED |
      | 850b55ca-f0a1-4a66-9d29-aa199d62db0c | 1.2.0-beta.1  | beta    | YANKED    |
      | 850b55ca-f0a1-4a66-9d29-aa199d62db0c | 1.2.0         | stable  | PUBLISHED |
      | 850b55ca-f0a1-4a66-9d29-aa199d62db0c | 1.0.0-alpha.2 | alpha   | DRAFT     |
      | 850b55ca-f0a1-4a66-9d29-aa199d62db0c | 1.0.0-beta.1  | beta    | DRAFT     |
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases?yanked=false"
    Then the response status should be "200"
    And the response body should be an array with 5 "releases"

  Scenario: Admin retrieves all yanked stable releases for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name     |
      | 850b55ca-f0a1-4a66-9d29-aa199d62db0c | Test App |
    And the current account has the following "release" rows:
      | product_id                           | version       | channel | status    |
      | 850b55ca-f0a1-4a66-9d29-aa199d62db0c | 1.0.0         | stable  | PUBLISHED |
      | 850b55ca-f0a1-4a66-9d29-aa199d62db0c | 1.1.0         | stable  | PUBLISHED |
      | 850b55ca-f0a1-4a66-9d29-aa199d62db0c | 1.2.0-beta.1  | beta    | YANKED    |
      | 850b55ca-f0a1-4a66-9d29-aa199d62db0c | 1.2.0         | stable  | PUBLISHED |
      | 850b55ca-f0a1-4a66-9d29-aa199d62db0c | 1.0.0-alpha.2 | alpha   | DRAFT     |
      | 850b55ca-f0a1-4a66-9d29-aa199d62db0c | 1.0.0-beta.1  | beta    | DRAFT     |
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases?yanked=true&channel=stable"
    Then the response status should be "200"
    And the response body should be an array with 0 "releases"

  Scenario: Admin retrieves all yanked releases for their account
    Given I am an admin of account "test1"
    And the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name     |
      | 850b55ca-f0a1-4a66-9d29-aa199d62db0c | Test App |
    And the current account has the following "release" rows:
      | product_id                           | version       | channel | status    |
      | 850b55ca-f0a1-4a66-9d29-aa199d62db0c | 1.0.0         | stable  | PUBLISHED |
      | 850b55ca-f0a1-4a66-9d29-aa199d62db0c | 1.1.0         | stable  | PUBLISHED |
      | 850b55ca-f0a1-4a66-9d29-aa199d62db0c | 1.2.0-beta.1  | beta    | YANKED    |
      | 850b55ca-f0a1-4a66-9d29-aa199d62db0c | 1.2.0         | stable  | PUBLISHED |
      | 850b55ca-f0a1-4a66-9d29-aa199d62db0c | 1.0.0-alpha.2 | alpha   | DRAFT     |
      | 850b55ca-f0a1-4a66-9d29-aa199d62db0c | 1.0.0-beta.1  | beta    | DRAFT     |
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases?yanked=true"
    Then the response status should be "200"
    And the response body should be an array with 1 "release"

  @ee
  Scenario: Environment retrieves all shared releases
    Given the current account is "test1"
    And the current account has 1 shared "environment"
    And the current account has 3 isolated "releases"
    And the current account has 3 shared "releases"
    And the current account has 3 global "releases"
    And I am an environment of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases?environment=shared"
    Then the response status should be "200"
    And the response body should be an array with 6 "releases"

  Scenario: Product retrieves all releases
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 2 "releases" for the last "product"
    And the current account has 2 "releases"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases"
    Then the response status should be "200"
    And the response body should be an array with 2 "release"

  Scenario: User retrieves all releases for their license (license owner)
    Given the current account is "test1"
    And the current account has 1 "user"
    And the current account has 2 "products"
    And the current account has 3 "releases" for the first "product"
    And the current account has 7 "releases" for the second "product"
    And the current account has 1 "policy" for the first "product"
    And the current account has 1 "license" for the first "policy"
    And the first "license" has the following attributes:
      """
      { "userId": "$users[1]" }
      """
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases"
    Then the response status should be "200"
    And the response body should be an array with 3 "releases"

  Scenario: User retrieves all releases for their license (license user)
    Given the current account is "test1"
    And the current account has 1 "user"
    And the current account has 2 "products"
    And the current account has 3 "releases" for the first "product"
    And the current account has 7 "releases" for the second "product"
    And the current account has 1 "policy" for the first "product"
    And the current account has 1 "license" for the first "policy"
    And the current account has 1 "license-user" for the last "license" and the last "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases"
    Then the response status should be "200"
    And the response body should be an array with 3 "releases"

  Scenario: License retrieves all releases for their product
    Given the current account is "test1"
    And the current account has 2 "products"
    And the current account has 9 "releases" for the first "product"
    And the current account has 5 "releases" for the second "product"
    And the current account has 1 "policy" for the first "product"
    And the current account has 1 "license" for the first "policy"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases"
    Then the response status should be "200"
    And the response body should be an array with 9 "releases"

  Scenario: Anonymous attempts to retrieve all accessible releases
    Given the current account is "test1"
    And the current account has 3 "products"
    And the first "product" has the following attributes:
      """
      { "distributionStrategy": "OPEN" }
      """
    And the second "product" has the following attributes:
      """
      { "distributionStrategy": "LICENSED" }
      """
    And the third "product" has the following attributes:
      """
      { "distributionStrategy": "CLOSED" }
      """
    And the current account has 5 "releases" for the first "product"
    And the current account has 3 "constraints" for the second "release"
    And the current account has 3 "releases" for the second "product"
    And the current account has 7 "releases" for the third "product"
    When I send a GET request to "/accounts/test1/releases"
    Then the response status should be "200"
    And the response body should be an array with 4 "releases"

  Scenario: License attempts to retrieve all draft releases
    Given the current account is "test1"
    And the current account has 1 "product"
    And the first "product" has the following attributes:
      """
      { "distributionStrategy": "LICENSED" }
      """
    And the current account has 3 "releases" for the first "product"
    And the first "release" has the following attributes:
      """
      { "status": "DRAFT" }
      """
    And the second "release" has the following attributes:
      """
      { "status": "YANKED" }
      """
    And the third "release" has the following attributes:
      """
      { "status": "PUBLISHED" }
      """
    And the current account has 1 "artifact" for the third "release"
    And the current account has 1 "policy" for the first "product"
    And the current account has 1 "license" for the first "policy"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases?status=DRAFT"
    Then the response status should be "200"
    And the response body should be an array with 0 "releases"

  Scenario: License attempts to retrieve all published releases
    Given the current account is "test1"
    And the current account has 1 "product"
    And the first "product" has the following attributes:
      """
      { "distributionStrategy": "LICENSED" }
      """
    And the current account has 4 "releases" for the first "product"
    And the current account has 1 "artifact" for the first "release"
    And the current account has 1 "artifact" for the third "release"
    And the first "release" has the following attributes:
      """
      { "status": "PUBLISHED" }
      """
    And the second "release" has the following attributes:
      """
      { "status": "DRAFT" }
      """
    And the third "release" has the following attributes:
      """
      { "status": "PUBLISHED" }
      """
    And the fourth "release" has the following attributes:
      """
      { "status": "YANKED" }
      """
    And the current account has 1 "policy" for the first "product"
    And the current account has 1 "license" for the first "policy"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases?status=PUBLISHED"
    Then the response status should be "200"
    And the response body should be an array with 2 "releases"

  Scenario: License attempts to retrieve all yanked releases
    Given the current account is "test1"
    And the current account has 1 "product"
    And the first "product" has the following attributes:
      """
      { "distributionStrategy": "LICENSED" }
      """
    And the current account has 3 "releases" for the first "product"
    And the first "release" has the following attributes:
      """
      { "status": "DRAFT" }
      """
    And the second "release" has the following attributes:
      """
      { "status": "YANKED" }
      """
    And the third "release" has the following attributes:
      """
      { "status": "PUBLISHED" }
      """
    And the current account has 1 "policy" for the first "product"
    And the current account has 1 "license" for the first "policy"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases?status=YANKED"
    Then the response status should be "200"
    And the response body should be an array with 0 "release"

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
    And the current account has 1 "policy" for the first "product"
    And the current account has 1 "license" for the first "policy"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases"
    Then the response status should be "200"
    And the response body should be an array with 8 "releases"

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
    And the current account has 1 "policy" for the first "product"
    And the current account has 1 "license" for the first "policy"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases?product=$products[0]"
    Then the response status should be "200"
    And the response body should be an array with 3 "releases"

  Scenario: User attempts to retrieve all accessible releases
    Given the current account is "test1"
    And the current account has 1 "user"
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
    And the current account has 1 "policy" for the first "product"
    And the current account has 1 "license" for the first "policy"
    And the first "license" has the following attributes:
      """
      { "userId": "$users[1]" }
      """
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases"
    Then the response status should be "200"
    And the response body should be an array with 8 "releases"

  Scenario: User attempts to retrieve all accessible releases (limit)
    Given the current account is "test1"
    And the current account has 1 "user"
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
    And the current account has 1 "release" for the first "product"
    And the current account has 1 "release" for the second "product"
    And the current account has 1 "release" for the third "product"
    And the current account has 1 "policy" for the first "product"
    And the current account has 1 "license" for the first "policy"
    And the first "license" has the following attributes:
      """
      { "userId": "$users[1]" }
      """
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases?limit=1"
    Then the response status should be "200"
    And the response body should be an array with 1 "release"

  Scenario: User attempts to retrieve all accessible releases (filtered)
    Given the current account is "test1"
    And the current account has 1 "user"
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
    And the current account has 1 "policy" for the first "product"
    And the current account has 1 "license" for the first "policy"
    And the first "license" has the following attributes:
      """
      { "userId": "$users[1]" }
      """
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases?product=$products[1]"
    Then the response status should be "200"
    And the response body should be an array with 5 "releases"

  Scenario: Admin attempts to retrieve releases for another account
    Given I am an admin of account "test2"
    But the current account is "test1"
    And the account "test1" has 2 "releases"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases"
    Then the response status should be "401"
    And the response body should be an array of 1 error

  # Draft releases
  Scenario: Anonymous retrieves draft releases
    Given the current account is "test1"
    And the current account has 1 open "product"
    And the current account has 3 draft "releases" for the last "product"
    When I send a GET request to "/accounts/test1/releases"
    Then the response status should be "200"
    And the response body should be an array with 0 "releases"

  Scenario: License retrieves draft releases without a license for any
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 3 draft "releases" for the last "product"
    And the current account has 1 "license"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases"
    Then the response status should be "200"
    And the response body should be an array with 0 "releases"

  Scenario: License retrieves draft releases with a license for them
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 3 draft "releases" for the last "product"
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "license" for the last "policy"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases"
    Then the response status should be "200"
    And the response body should be an array with 0 "releases"

  Scenario: User retrieves draft releases without a license for any
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 3 draft "releases" for the last "product"
    And the current account has 1 "license"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases"
    Then the response status should be "200"
    And the response body should be an array with 0 "releases"

  Scenario: User retrieves draft releases with a license for them
    Given the current account is "test1"
    And the current account has 1 "user"
    And the current account has 1 "product"
    And the current account has 1 draft "release" for the last "product"
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "license" for the last "policy"
    And the last "license" has the following attributes:
      """
      { "userId": "$users[1]" }
      """
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases"
    Then the response status should be "200"
    And the response body should be an array with 0 "releases"

  Scenario: Product retrieves draft releases
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 3 draft "releases" for the last "product"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases"
    Then the response status should be "200"
    And the response body should be an array with 3 "releases"

  Scenario: Product retrieves draft releases of another product
    Given the current account is "test1"
    And the current account has 2 "products"
    And the current account has 3 draft "releases" for the second "product"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases"
    Then the response status should be "200"
    And the response body should be an array with 0 "releases"

  Scenario: Admin retrieves draft releases
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 3 draft "releases" for the last "product"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases"
    Then the response status should be "200"
    And the response body should be an array with 3 "releases"

  # Yanked releases
  Scenario: Anonymous retrieves yanked releases
    Given the current account is "test1"
    And the current account has 1 open "product"
    And the current account has 3 yanked "releases" for the last "product"
    When I send a GET request to "/accounts/test1/releases"
    Then the response status should be "200"
    And the response body should be an array with 0 "releases"

  Scenario: License retrieves yanked releases without a license for any
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 3 yanked "releases" for the last "product"
    And the current account has 1 "license"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases"
    Then the response status should be "200"
    And the response body should be an array with 0 "releases"

  Scenario: License retrieves yanked releases with a license for them
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 3 yanked "releases" for the last "product"
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "license" for the last "policy"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases"
    Then the response status should be "200"
    And the response body should be an array with 0 "releases"

  Scenario: User retrieves yanked releases without a license for any
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 3 yanked "releases" for the last "product"
    And the current account has 1 "license"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases"
    Then the response status should be "200"
    And the response body should be an array with 0 "releases"

  Scenario: User retrieves yanked releases with a license for them
    Given the current account is "test1"
    And the current account has 1 "user"
    And the current account has 1 "product"
    And the current account has 1 yanked "release" for the last "product"
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "license" for the last "policy"
    And the last "license" has the following attributes:
      """
      { "userId": "$users[1]" }
      """
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases"
    Then the response status should be "200"
    And the response body should be an array with 0 "releases"

  Scenario: Product retrieves yanked releases
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 3 yanked "releases" for the last "product"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases"
    Then the response status should be "200"
    And the response body should be an array with 3 "releases"

  Scenario: Product retrieves yanked releases of another product
    Given the current account is "test1"
    And the current account has 2 "products"
    And the current account has 3 yanked "releases" for the second "product"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases"
    Then the response status should be "200"
    And the response body should be an array with 0 "releases"

  Scenario: Admin retrieves yanked releases
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 3 yanked "releases" for the last "product"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases"
    Then the response status should be "200"
    And the response body should be an array with 3 "releases"

  Scenario: Admin retrieves releases filtered by constraint
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 3 "releases" for the last "product"
    And the current account has 1 "constraint" for each "release"
    And the current account has 1 "release" for the last "product"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases?constraints[]=$entitlements[0].code"
    Then the response status should be "200"
    And the response body should be an array with 2 "releases"

  Scenario: Admin retrieves releases filtered by entitlement
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 3 "releases" for the last "product"
    And the current account has 1 "constraint" for each "release"
    And the current account has 1 "release" for the last "product"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases?entitlements[]=$entitlements[0].code"
    Then the response status should be "200"
    And the response body should be an array with 2 "releases"

  Scenario: License retrieves their product releases with constraints (no entitlements)
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 3 "releases" for the last "product"
    And the current account has 1 "constraint" for the last "release"
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "license" for the last "policy"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases"
    Then the response status should be "200"
    And the response body should be an array with 2 "releases"

  Scenario: License retrieves their product releases with constraints (some entitlements)
    Given the current account is "test1"
    And the current account has 3 "entitlements"
    And the current account has 1 "product"
    And the current account has 3 "releases" for the last "product"
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "license" for the last "policy"
    And the current account has 1 "license-entitlement" with the following:
      """
      {
        "entitlementId": "$entitlements[0]",
        "licenseId": "$licenses[0]"
      }
      """
    And the current account has 1 "policy-entitlement" with the following:
      """
      {
        "entitlementId": "$entitlements[1]",
        "policyId": "$policies[0]"
      }
      """
    And the current account has 1 "release-entitlement-constraint" with the following:
      """
      {
        "entitlementId": "$entitlements[2]",
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
    When I send a GET request to "/accounts/test1/releases"
    Then the response status should be "200"
    And the response body should be an array with 2 "releases"

  Scenario: License retrieves their product releases with constraints (all entitlements)
    Given the current account is "test1"
    And the current account has 3 "entitlements"
    And the current account has 1 "product"
    And the current account has 3 "releases" for the last "product"
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "license" for the last "policy"
    And the current account has 1 "license-entitlement" with the following:
      """
      {
        "entitlementId": "$entitlements[0]",
        "licenseId": "$licenses[0]"
      }
      """
    And the current account has 1 "policy-entitlement" with the following:
      """
      {
        "entitlementId": "$entitlements[1]",
        "policyId": "$policies[0]"
      }
      """
    And the current account has 1 "policy-entitlement" with the following:
      """
      {
        "entitlementId": "$entitlements[2]",
        "policyId": "$policies[0]"
      }
      """
    And the current account has 1 "release-entitlement-constraint" with the following:
      """
      {
        "entitlementId": "$entitlements[2]",
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
    When I send a GET request to "/accounts/test1/releases"
    Then the response status should be "200"
    And the response body should be an array with 3 "releases"

  Scenario: User retrieves their product releases with constraints (no entitlements)
    Given the current account is "test1"
    And the current account has 1 "user"
    And the current account has 1 "product"
    And the current account has 3 "releases" for the last "product"
    And the current account has 1 "constraint" for the last "release"
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "license" for the last "policy"
    And the last "license" has the following attributes:
      """
      { "userId": "$users[1]" }
      """
    And I am a user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases"
    Then the response status should be "200"
    And the response body should be an array with 2 "releases"

  Scenario: User retrieves their product releases with constraints (some entitlements)
    Given the current account is "test1"
    And the current account has 3 "entitlements"
    And the current account has 1 "user"
    And the current account has 1 "product"
    And the current account has 3 "releases" for the last "product"
    And the current account has 1 "policy" for the last "product"
    And the current account has 2 "licenses" for the last "policy"
    And all "licenses" have the following attributes:
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
    And the current account has 1 "policy-entitlement" with the following:
      """
      {
        "entitlementId": "$entitlements[1]",
        "policyId": "$policies[0]"
      }
      """
    And the current account has 1 "release-entitlement-constraint" with the following:
      """
      {
        "entitlementId": "$entitlements[2]",
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
    When I send a GET request to "/accounts/test1/releases"
    Then the response status should be "200"
    And the response body should be an array with 2 "releases"

  Scenario: User retrieves their product releases with constraints (all entitlements)
    Given the current account is "test1"
    And the current account has 3 "entitlements"
    And the current account has 1 "user"
    And the current account has 1 "product"
    And the current account has 3 "releases" for the last "product"
    And the current account has 1 "policy" for the last "product"
    And the current account has 2 "licenses" for the last "policy"
    And all "licenses" have the following attributes:
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
        "entitlementId": "$entitlements[2]",
        "licenseId": "$licenses[0]"
      }
      """
    And the current account has 1 "policy-entitlement" with the following:
      """
      {
        "entitlementId": "$entitlements[1]",
        "policyId": "$policies[0]"
      }
      """
    And the current account has 1 "release-entitlement-constraint" with the following:
      """
      {
        "entitlementId": "$entitlements[2]",
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
    When I send a GET request to "/accounts/test1/releases"
    Then the response status should be "200"
    And the response body should be an array with 3 "releases"

  Scenario: License retrieves their releases with an expired license (REVOKE_ACCESS)
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 4 "releases" for the last "product"
    And the first "release" has the following attributes:
      """
      { "createdAt": "2024-04-01T00:00:00Z" }
      """
    And the second "release" has the following attributes:
      """
      { "createdAt": "2024-04-02T00:00:00Z" }
      """
    And the third "release" has the following attributes:
      """
      { "createdAt": "2024-04-03T00:00:00Z" }
      """
    And the fourth "release" has the following attributes:
      """
      {
        "backdatedTo": "2024-04-01T00:00:00Z",
        "createdAt": "2024-04-03T00:00:00Z"
      }
      """
    And the current account has 1 "policy" for the last "product"
    And the last "policy" has the following attributes:
      """
      { "expirationStrategy": "REVOKE_ACCESS", "authenticationStrategy": "LICENSE" }
      """
    And the current account has 1 "license" for the last "policy"
    And the last "license" has the following attributes:
      """
      { "expiry": "2024-04-02T00:00:00Z" }
      """
    And I am the last license of account "test1"
    And I authenticate with my key
    When I send a GET request to "/accounts/test1/releases"
    Then the response status should be "403"

  Scenario: License retrieves their releases with an expired license (RESTRICT_ACCESS)
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 4 "releases" for the last "product"
    And the first "release" has the following attributes:
      """
      { "createdAt": "2024-04-01T00:00:00Z" }
      """
    And the second "release" has the following attributes:
      """
      { "createdAt": "2024-04-02T00:00:00Z" }
      """
    And the third "release" has the following attributes:
      """
      { "createdAt": "2024-04-03T00:00:00Z" }
      """
    And the fourth "release" has the following attributes:
      """
      {
        "backdatedTo": "2024-04-01T00:00:00Z",
        "createdAt": "2024-04-03T00:00:00Z"
      }
      """
    And the current account has 1 "policy" for the last "product"
    And the last "policy" has the following attributes:
      """
      { "expirationStrategy": "RESTRICT_ACCESS", "authenticationStrategy": "LICENSE" }
      """
    And the current account has 1 "license" for the last "policy"
    And the last "license" has the following attributes:
      """
      { "expiry": "2024-04-02T00:00:00Z" }
      """
    And I am the last license of account "test1"
    And I authenticate with my key
    When I send a GET request to "/accounts/test1/releases"
    Then the response status should be "200"
    And the response body should be an array with 3 "releases"

  Scenario: License retrieves their releases with an expired license (MAINTAIN_ACCESS)
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 4 "releases" for the last "product"
    And the first "release" has the following attributes:
      """
      { "createdAt": "2024-04-01T00:00:00Z" }
      """
    And the second "release" has the following attributes:
      """
      { "createdAt": "2024-04-02T00:00:00Z" }
      """
    And the third "release" has the following attributes:
      """
      { "createdAt": "2024-04-03T00:00:00Z" }
      """
    And the fourth "release" has the following attributes:
      """
      {
        "backdatedTo": "2024-04-01T00:00:00Z",
        "createdAt": "2024-04-03T00:00:00Z"
      }
      """
    And the current account has 1 "policy" for the last "product"
    And the last "policy" has the following attributes:
      """
      { "expirationStrategy": "MAINTAIN_ACCESS", "authenticationStrategy": "LICENSE" }
      """
    And the current account has 1 "license" for the last "policy"
    And the last "license" has the following attributes:
      """
      { "expiry": "2024-04-02T00:00:00Z" }
      """
    And I am the last license of account "test1"
    And I authenticate with my key
    When I send a GET request to "/accounts/test1/releases"
    Then the response status should be "200"
    And the response body should be an array with 3 "releases"

  Scenario: License retrieves their releases with an expired license (ALLOW_ACCESS)
    Given the current account is "test1"
    And the current account has 1 "product"
    And the current account has 4 "releases" for the last "product"
    And the first "release" has the following attributes:
      """
      { "createdAt": "2024-04-01T00:00:00Z" }
      """
    And the second "release" has the following attributes:
      """
      { "createdAt": "2024-04-02T00:00:00Z" }
      """
    And the third "release" has the following attributes:
      """
      { "createdAt": "2024-04-03T00:00:00Z" }
      """
    And the fourth "release" has the following attributes:
      """
      {
        "backdatedTo": "2024-04-01T00:00:00Z",
        "createdAt": "2024-04-03T00:00:00Z"
      }
      """
    And the current account has 1 "policy" for the last "product"
    And the last "policy" has the following attributes:
      """
      { "expirationStrategy": "ALLOW_ACCESS", "authenticationStrategy": "LICENSE" }
      """
    And the current account has 1 "license" for the last "policy"
    And the last "license" has the following attributes:
      """
      { "expiry": "2024-04-02T00:00:00Z" }
      """
    And I am the last license of account "test1"
    And I authenticate with my key
    When I send a GET request to "/accounts/test1/releases"
    Then the response status should be "200"
    And the response body should be an array with 4 "releases"

  Scenario: User retrieves their releases with an expired license (REVOKE_ACCESS)
    Given the current account is "test1"
    And the current account has 1 "user"
    And the current account has 2 "products"
    And the current account has 3 "releases" for the first "product"
    And the current account has 5 "releases" for the second "product"
    And the first "release" has the following attributes:
      """
      { "createdAt": "2024-04-01T00:00:00Z" }
      """
    And the second "release" has the following attributes:
      """
      { "createdAt": "2024-04-02T00:00:00Z" }
      """
    And the third "release" has the following attributes:
      """
      { "createdAt": "2024-04-03T00:00:00Z" }
      """
    And the current account has 1 "policy" for the first "product"
    And the current account has 1 "policy" for the second "product"
    And the first "policy" has the following attributes:
      """
      { "expirationStrategy": "REVOKE_ACCESS", "authenticationStrategy": "LICENSE" }
      """
    And the current account has 1 "license" for the first "policy"
    And the current account has 1 "license" for the second "policy" and the last "user" as "owner"
    And the first "license" has the following attributes:
      """
      { "expiry": "2024-04-02T00:00:00Z" }
      """
    And the current account has 1 "license-user" for the first "license" and the last "user"
    And I am the last user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases"
    Then the response status should be "200"
    And the response body should be an array with 5 "releases"

  Scenario: User retrieves their releases with an expired license (RESTRICT_ACCESS)
    Given the current account is "test1"
    And the current account has 1 "user"
    And the current account has 2 "products"
    And the current account has 3 "releases" for the first "product"
    And the current account has 5 "releases" for the second "product"
    And the first "release" has the following attributes:
      """
      { "createdAt": "2024-04-01T00:00:00Z" }
      """
    And the second "release" has the following attributes:
      """
      { "createdAt": "2024-04-02T00:00:00Z" }
      """
    And the third "release" has the following attributes:
      """
      { "createdAt": "2024-04-03T00:00:00Z" }
      """
    And the current account has 1 "policy" for the first "product"
    And the current account has 1 "policy" for the second "product"
    And the first "policy" has the following attributes:
      """
      { "expirationStrategy": "RESTRICT_ACCESS", "authenticationStrategy": "LICENSE" }
      """
    And the current account has 1 "license" for the first "policy"
    And the current account has 1 "license" for the second "policy" and the last "user" as "owner"
    And the first "license" has the following attributes:
      """
      { "expiry": "2024-04-02T00:00:00Z" }
      """
    And the current account has 1 "license-user" for the first "license" and the last "user"
    And I am the last user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases"
    Then the response status should be "200"
    And the response body should be an array with 7 "releases"

  Scenario: User retrieves their releases with an expired license (MAINTAIN_ACCESS)
    Given the current account is "test1"
    And the current account has 1 "user"
    And the current account has 2 "products"
    And the current account has 3 "releases" for the first "product"
    And the current account has 5 "releases" for the second "product"
    And the first "release" has the following attributes:
      """
      { "createdAt": "2024-04-01T00:00:00Z" }
      """
    And the second "release" has the following attributes:
      """
      { "createdAt": "2024-04-02T00:00:00Z" }
      """
    And the third "release" has the following attributes:
      """
      { "createdAt": "2024-04-03T00:00:00Z" }
      """
    And the current account has 1 "policy" for the first "product"
    And the current account has 1 "policy" for the second "product"
    And the first "policy" has the following attributes:
      """
      { "expirationStrategy": "MAINTAIN_ACCESS", "authenticationStrategy": "LICENSE" }
      """
    And the current account has 1 "license" for the first "policy"
    And the current account has 1 "license" for the second "policy" and the last "user" as "owner"
    And the first "license" has the following attributes:
      """
      { "expiry": "2024-04-02T00:00:00Z" }
      """
    And the current account has 1 "license-user" for the first "license" and the last "user"
    And I am the last user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases"
    Then the response status should be "200"
    And the response body should be an array with 7 "releases"

  Scenario: User retrieves their releases with an expired license (ALLOW_ACCESS)
    Given the current account is "test1"
    And the current account has 1 "user"
    And the current account has 2 "products"
    And the current account has 3 "releases" for the first "product"
    And the current account has 5 "releases" for the second "product"
    And the first "release" has the following attributes:
      """
      { "createdAt": "2024-04-01T00:00:00Z" }
      """
    And the second "release" has the following attributes:
      """
      { "createdAt": "2024-04-02T00:00:00Z" }
      """
    And the third "release" has the following attributes:
      """
      { "createdAt": "2024-04-03T00:00:00Z" }
      """
    And the current account has 1 "policy" for the first "product"
    And the current account has 1 "policy" for the second "product"
    And the first "policy" has the following attributes:
      """
      { "expirationStrategy": "ALLOW_ACCESS", "authenticationStrategy": "LICENSE" }
      """
    And the current account has 1 "license" for the first "policy"
    And the current account has 1 "license" for the second "policy" and the last "user" as "owner"
    And the first "license" has the following attributes:
      """
      { "expiry": "2024-04-02T00:00:00Z" }
      """
    And the current account has 1 "license-user" for the first "license" and the last "user"
    And I am the last user of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/releases"
    Then the response status should be "200"
    And the response body should be an array with 8 "releases"
