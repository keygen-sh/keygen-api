@api/v1.0 @deprecated
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
    And I use API version "1.0"
    When I send a POST request to "/accounts/test1/releases"
    Then the response status should be "403"

  Scenario: Admin retrieves all v1.0.0 releases for their account
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
    And I use API version "1.0"
    When I send a GET request to "/accounts/test1/releases?version=1.0.0"
    Then the response status should be "200"
    And the response body should be an array with 1 "release"

  Scenario: Admin retrieves all tar.gz releases for their account
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
    And I use API version "1.0"
    When I send a GET request to "/accounts/test1/releases?filetype=tar.gz"
    Then the response status should be "200"
    And the response body should be an array with 0 "releases"

  Scenario: Admin retrieves all exe releases for their account
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
    And I use API version "1.0"
    When I send a GET request to "/accounts/test1/releases?filetype=exe"
    Then the response status should be "200"
    And the response body should be an array with 3 "releases"

  Scenario: Admin retrieves all dmg releases for their account
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
    And I use API version "1.0"
    When I send a GET request to "/accounts/test1/releases?filetype=dmg&channel=alpha"
    Then the response status should be "200"
    And the response body should be an array with 3 "releases"

  Scenario: Admin retrieves all macos releases for their account
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
    And I use API version "1.0"
    When I send a GET request to "/accounts/test1/releases?platform=macos&channel=beta"
    Then the response status should be "200"
    And the response body should be an array with 3 "releases"

  Scenario: Admin retrieves all win32 releases for their account
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
    And I use API version "1.0"
    When I send a GET request to "/accounts/test1/releases?platform=win32&channel=stable"
    Then the response status should be "200"
    And the response body should be an array with 1 "release"

  Scenario: Admin retrieves all linux releases for their account
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
    And I use API version "1.0"
    When I send a GET request to "/accounts/test1/releases?platform=linux"
    Then the response status should be "200"
    And the response body should be an array with 0 "releases"

  Scenario: Admin retrieves all win32 beta releases for their account
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
    And I use API version "1.0"
    When I send a GET request to "/accounts/test1/releases?channel=beta&platform=win32"
    Then the response status should be "200"
    And the response body should be an array with 2 "releases"

  Scenario: Admin retrieves all x86 releases for their account
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
    And I use API version "1.0"
    When I send a GET request to "/accounts/test1/releases?arch=x64"
    Then the response status should be "200"
    And the response body should be an array with 1 "release"
