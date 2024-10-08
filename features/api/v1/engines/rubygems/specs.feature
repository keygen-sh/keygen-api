@api/v1
Feature: Rubygems simple package index
  Background:
    Given the following "accounts" exist:
      | name   | slug  |
      | Test 1 | test1 |
      | Test 2 | test2 |
    And the current account is "test1"
    And the current account has the following "product" rows:
      | id                                   | name |
      | 6198261a-48b5-4445-a045-9fed4afc7735 | Test |
    And the current account has the following "package" rows:
      | id                                   | product_id                           | engine   | key |
      | 46e034fe-2312-40f8-bbeb-7d9957fb6fcf | 6198261a-48b5-4445-a045-9fed4afc7735 | rubygems | foo |
      | 2f8af04a-2424-4ca2-8480-6efe24318d1a | 6198261a-48b5-4445-a045-9fed4afc7735 | rubygems | bar |
      | 7b113ac2-ae81-406a-b44e-f356126e2faa | 6198261a-48b5-4445-a045-9fed4afc7735 | rubygems | baz |
      | 5666d47e-936e-4d48-8dd7-382d32462b4e | 6198261a-48b5-4445-a045-9fed4afc7735 | npm      | qux |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | release_package_id                   | version      | channel  |
      | 757e0a41-835e-42ad-bad8-84cabd29c72a | 6198261a-48b5-4445-a045-9fed4afc7735 | 46e034fe-2312-40f8-bbeb-7d9957fb6fcf | 1.0.0        | stable   |
      | 3ff04fc6-9f10-4b84-b548-eb40f92ea331 | 6198261a-48b5-4445-a045-9fed4afc7735 | 46e034fe-2312-40f8-bbeb-7d9957fb6fcf | 1.0.1        | stable   |
      | 028a38a2-0d17-4871-acb8-c5e6f040fc12 | 6198261a-48b5-4445-a045-9fed4afc7735 | 46e034fe-2312-40f8-bbeb-7d9957fb6fcf | 1.1.0        | stable   |
      | 972aa5b8-b12c-49f4-8ba4-7c9ae053dfa2 | 6198261a-48b5-4445-a045-9fed4afc7735 | 2f8af04a-2424-4ca2-8480-6efe24318d1a | 1.0.0-beta.1 | beta     |
      | 28a6e16d-c2a6-4be7-8578-e236182ee5c3 | 6198261a-48b5-4445-a045-9fed4afc7735 | 7b113ac2-ae81-406a-b44e-f356126e2faa | 2.0.0        | stable   |
      | 70c40946-4b23-408c-aa1c-fa35421ff46a | 6198261a-48b5-4445-a045-9fed4afc7735 |                                      | 1.1.0        | stable   |
    And the current account has the following "artifact" rows:
      | release_id                           | filename            | filetype |
      | 757e0a41-835e-42ad-bad8-84cabd29c72a | foo-1.0.0.gem       | gem      |
      | 3ff04fc6-9f10-4b84-b548-eb40f92ea331 | foo-1.0.1.gem       | gem      |
      | 028a38a2-0d17-4871-acb8-c5e6f040fc12 | foo-1.1.0.gem       | gem      |
      | 972aa5b8-b12c-49f4-8ba4-7c9ae053dfa2 | bar-1.0.0-beta1.gem | gem      |
      | 28a6e16d-c2a6-4be7-8578-e236182ee5c3 | baz-2.0.0.gem       | gem      |
      | 70c40946-4b23-408c-aa1c-fa35421ff46a | qux-1.1.0.gem       | gem      |
    And I send the following raw headers:
      """
      User-Agent: Ruby, RubyGems/3.5.11 arm64-darwin-23 Ruby/3.3.4 (2024-07-09 patchlevel 94)
      Accept: text/html
      Content-Type: text/html
      """

  Scenario: Endpoint should be inaccessible when account is disabled
    Given the account "test1" is canceled
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/engines/rubygems/specs.4.8.gz"
    Then the response status should be "403"
    And the response should contain the following headers:
      """
      { "Content-Type": "text/html; charset=utf-8" }
      """

  Scenario: Endpoint should return gziped specs of released gems
    Given I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/engines/rubygems/specs.4.8.gz"
    Then the response status should be "200"
    And the response should contain gziped spec file with the following content:
      """
      [
        ["foo", #<Gem::Version "1.0.0">, "ruby"],
        ["foo", #<Gem::Version "1.0.1">, "ruby"],
        ["foo", #<Gem::Version "1.1.0">, "ruby"],
        ["baz", #<Gem::Version "2.0.0">, "ruby"]
      ]
      """

  Scenario: Endpoint should return gziped latest specs of released gems
    Given I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/engines/rubygems/latest_specs.4.8.gz"
    Then the response status should be "200"
    And the response should contain gziped spec file with the following content:
      """
      [
        ["foo", #<Gem::Version "1.1.0">, "ruby"],
        ["baz", #<Gem::Version "2.0.0">, "ruby"]
      ]
      """

  Scenario: Endpoint should return gziped specs of prereleased gems
    Given I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/engines/rubygems/prerelease_specs.4.8.gz"
    Then the response status should be "200"
    And the response should contain gziped spec file with the following content:
      """
      [
        ["bar", #<Gem::Version "1.0.0.pre.beta.1">, "ruby"]
      ]
      """

