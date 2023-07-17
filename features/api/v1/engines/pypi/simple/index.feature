@api/v1
Feature: PyPI simple package index
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
      | id                                   | product_id                           | engine | key |
      | 46e034fe-2312-40f8-bbeb-7d9957fb6fcf | 6198261a-48b5-4445-a045-9fed4afc7735 | pypi   | foo |
      | 2f8af04a-2424-4ca2-8480-6efe24318d1a | 6198261a-48b5-4445-a045-9fed4afc7735 | pypi   | bar |
      | 7b113ac2-ae81-406a-b44e-f356126e2faa | 6198261a-48b5-4445-a045-9fed4afc7735 | pypi   | baz |
      | 5666d47e-936e-4d48-8dd7-382d32462b4e | 6198261a-48b5-4445-a045-9fed4afc7735 | npm    | qux |
    And the current account has the following "release" rows:
      | id                                   | product_id                           | release_package_id                   | version      | channel  |
      | 757e0a41-835e-42ad-bad8-84cabd29c72a | 6198261a-48b5-4445-a045-9fed4afc7735 | 46e034fe-2312-40f8-bbeb-7d9957fb6fcf | 1.0.0        | stable   |
      | 3ff04fc6-9f10-4b84-b548-eb40f92ea331 | 6198261a-48b5-4445-a045-9fed4afc7735 | 46e034fe-2312-40f8-bbeb-7d9957fb6fcf | 1.0.1        | stable   |
      | 028a38a2-0d17-4871-acb8-c5e6f040fc12 | 6198261a-48b5-4445-a045-9fed4afc7735 | 46e034fe-2312-40f8-bbeb-7d9957fb6fcf | 1.1.0        | stable   |
      | 972aa5b8-b12c-49f4-8ba4-7c9ae053dfa2 | 6198261a-48b5-4445-a045-9fed4afc7735 | 2f8af04a-2424-4ca2-8480-6efe24318d1a | 1.0.0-beta.1 | beta     |
      | 28a6e16d-c2a6-4be7-8578-e236182ee5c3 | 6198261a-48b5-4445-a045-9fed4afc7735 | 7b113ac2-ae81-406a-b44e-f356126e2faa | 2.0.0        | stable   |
      | 70c40946-4b23-408c-aa1c-fa35421ff46a | 6198261a-48b5-4445-a045-9fed4afc7735 |                                      | 1.1.0        | stable   |
    And the current account has the following "artifact" rows:
      | release_id                           | filename                    | filetype |
      | 757e0a41-835e-42ad-bad8-84cabd29c72a | foo-1.0.0.tar.gz            | tar.gz   |
      | 757e0a41-835e-42ad-bad8-84cabd29c72a | foo-1.0.0-py3-none-any.wh   | wh       |
      | 3ff04fc6-9f10-4b84-b548-eb40f92ea331 | foo-1.0.1.tar.gz            | tar.gz   |
      | 3ff04fc6-9f10-4b84-b548-eb40f92ea331 | foo-1.0.1-py3-none-any.wh   | wh       |
      | 028a38a2-0d17-4871-acb8-c5e6f040fc12 | foo-1.1.0.tar.gz            | tar.gz   |
      | 028a38a2-0d17-4871-acb8-c5e6f040fc12 | foo-1.1.0-py3-none-any.wh   | wh       |
      | 972aa5b8-b12c-49f4-8ba4-7c9ae053dfa2 | bar-1.0.0b1.tar.gz          | tar.gz   |
      | 972aa5b8-b12c-49f4-8ba4-7c9ae053dfa2 | bar-1.0.0b1-py3-none-any.wh | wh       |
      | 28a6e16d-c2a6-4be7-8578-e236182ee5c3 | baz-2.0.0.tar.gz            | tar.gz   |
      | 28a6e16d-c2a6-4be7-8578-e236182ee5c3 | baz-2.0.0-py3-none-any.wh   | wh       |
      | 70c40946-4b23-408c-aa1c-fa35421ff46a | qux-1.1.0.tar.gz            | tar.gz   |
      | 70c40946-4b23-408c-aa1c-fa35421ff46a | qux-1.1.0-py3-none-any.wh   | wh       |
    And I send the following raw headers:
      """
      User-Agent: pip/23.1.2 {"ci":null,"cpu":"x86_64","distro":{"id":"focal","libc":{"lib":"glibc","version":"2.31"},"name":"Ubuntu","version":"20.04"},"implementation":{"name":"CPython","version":"3.8.10"},"installer":{"name":"pip","version":"23.1.2"},"openssl_version":"OpenSSL 1.1.1f  31 Mar 2020","python":"3.8.10","setuptools_version":"45.2.0","system":{"name":"Linux","release":"5.15.90.1-microsoft-standard-WSL2"}}
      Accept: application/vnd.pypi.simple.v1+json, application/vnd.pypi.simple.v1+html; q=0.1, text/html; q=0.01
      """

  Scenario: Endpoint should be inaccessible when account is disabled
    Given the account "test1" is canceled
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/engines/pypi/simple"
    Then the response status should be "403"

  Scenario: Endpoint should return an index of packages
    Given I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/engines/pypi/simple"
    Then the response status should be "200"
    And the response body should be an HTML document without the following xpaths:
      """
      /html/body/a[@href="https://api.keygen.sh/v1/accounts/$account/engines/pypi/simple/5666d47e-936e-4d48-8dd7-382d32462b4e/"]
      """
    And the response body should be an HTML document with the following xpaths:
      """
      /html/body/a[text()="foo" and @href="https://api.keygen.sh/v1/accounts/$account/engines/pypi/simple/46e034fe-2312-40f8-bbeb-7d9957fb6fcf/"]
      /html/body/a[text()="bar" and @href="https://api.keygen.sh/v1/accounts/$account/engines/pypi/simple/2f8af04a-2424-4ca2-8480-6efe24318d1a/"]
      /html/body/a[text()="baz" and @href="https://api.keygen.sh/v1/accounts/$account/engines/pypi/simple/7b113ac2-ae81-406a-b44e-f356126e2faa/"]
      """

  Scenario: Endpoint should only respond to HTML
    Given I am an admin of account "test1"
    And I use an authentication token
    And I send the following raw headers:
      """
      Accept: application/json
      """
    When I send a GET request to "/accounts/test1/engines/pypi/simple"
    Then the response status should be "400"

  Scenario: Endpoint should return an index with package metadata
    Given the first "package" has the following attributes:
      """
      {
        "metadata": {
          "key": "value"
        }
      }
      """
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/engines/pypi/simple"
    Then the response status should be "200"
    And the response body should be an HTML document without the following xpaths:
      """
      /html/body/a[@href="https://api.keygen.sh/v1/accounts/$account/engines/pypi/simple/2f8af04a-2424-4ca2-8480-6efe24318d1a/" and @data-key="value"]
      /html/body/a[@href="https://api.keygen.sh/v1/accounts/$account/engines/pypi/simple/7b113ac2-ae81-406a-b44e-f356126e2faa/" and @data-key="value"]
      """
    And the response body should be an HTML document with the following xpaths:
      """
      /html/body/a[@href="https://api.keygen.sh/v1/accounts/$account/engines/pypi/simple/46e034fe-2312-40f8-bbeb-7d9957fb6fcf/" and @data-key="value"]
      """

  Scenario: License requests an index for a licensed product
    Given the first "product" has the following attributes:
      """
      { "distributionStrategy": "LICENSED" }
      """
    And the current account has 1 "policy" for the last "product" with the following:
      """
      { "authenticationStrategy": "LICENSE" }
      """
    And the current account has 1 "license" for the last "policy"
    And I am a license of account "test1"
    And I authenticate with my key
    When I send a GET request to "/accounts/test1/engines/pypi/simple"
    Then the response status should be "200"
    And the response body should be an HTML document with the following xpaths:
      """
      /html/body/a[@href="https://api.keygen.sh/v1/accounts/$account/engines/pypi/simple/46e034fe-2312-40f8-bbeb-7d9957fb6fcf/"]
      /html/body/a[@href="https://api.keygen.sh/v1/accounts/$account/engines/pypi/simple/2f8af04a-2424-4ca2-8480-6efe24318d1a/"]
      /html/body/a[@href="https://api.keygen.sh/v1/accounts/$account/engines/pypi/simple/7b113ac2-ae81-406a-b44e-f356126e2faa/"]
      """

  Scenario: License requests an index for a closed product
    Given the first "product" has the following attributes:
      """
      { "distributionStrategy": "CLOSED" }
      """
    And the current account has 1 "policy" for the last "product" with the following:
      """
      { "authenticationStrategy": "LICENSE" }
      """
    And the current account has 1 "license" for the last "policy"
    And I am a license of account "test1"
    And I authenticate with my key
    When I send a GET request to "/accounts/test1/engines/pypi/simple"
    Then the response status should be "200"
    And the response body should be an HTML document without the following xpaths:
      """
      /html/body/a[@href="https://api.keygen.sh/v1/accounts/$account/engines/pypi/simple/46e034fe-2312-40f8-bbeb-7d9957fb6fcf/"]
      /html/body/a[@href="https://api.keygen.sh/v1/accounts/$account/engines/pypi/simple/2f8af04a-2424-4ca2-8480-6efe24318d1a/"]
      /html/body/a[@href="https://api.keygen.sh/v1/accounts/$account/engines/pypi/simple/7b113ac2-ae81-406a-b44e-f356126e2faa/"]
      """

  Scenario: License requests an index for an open product
    Given the first "product" has the following attributes:
      """
      { "distributionStrategy": "OPEN" }
      """
    And the current account has 1 "policy" for the last "product" with the following:
      """
      { "authenticationStrategy": "LICENSE" }
      """
    And the current account has 1 "license" for the last "policy"
    And I am a license of account "test1"
    And I authenticate with my key
    When I send a GET request to "/accounts/test1/engines/pypi/simple"
    Then the response status should be "200"
    And the response body should be an HTML document with the following xpaths:
      """
      /html/body/a[@href="https://api.keygen.sh/v1/accounts/$account/engines/pypi/simple/46e034fe-2312-40f8-bbeb-7d9957fb6fcf/"]
      /html/body/a[@href="https://api.keygen.sh/v1/accounts/$account/engines/pypi/simple/2f8af04a-2424-4ca2-8480-6efe24318d1a/"]
      /html/body/a[@href="https://api.keygen.sh/v1/accounts/$account/engines/pypi/simple/7b113ac2-ae81-406a-b44e-f356126e2faa/"]
      """

  Scenario: License requests an index for another licensed product
    Given the first "product" has the following attributes:
      """
      { "distributionStrategy": "LICENSED" }
      """
    And the current account has 1 "policy" with the following:
      """
      { "authenticationStrategy": "LICENSE" }
      """
    And the current account has 1 "license" for the last "policy"
    And I am a license of account "test1"
    And I authenticate with my key
    When I send a GET request to "/accounts/test1/engines/pypi/simple"
    Then the response status should be "200"
    And the response body should be an HTML document without the following xpaths:
      """
      /html/body/a[@href="https://api.keygen.sh/v1/accounts/$account/engines/pypi/simple/46e034fe-2312-40f8-bbeb-7d9957fb6fcf/"]
      /html/body/a[@href="https://api.keygen.sh/v1/accounts/$account/engines/pypi/simple/2f8af04a-2424-4ca2-8480-6efe24318d1a/"]
      /html/body/a[@href="https://api.keygen.sh/v1/accounts/$account/engines/pypi/simple/7b113ac2-ae81-406a-b44e-f356126e2faa/"]
      """

  Scenario: License requests an index for another closed product
    Given the first "product" has the following attributes:
      """
      { "distributionStrategy": "CLOSED" }
      """
    And the current account has 1 "policy" with the following:
      """
      { "authenticationStrategy": "LICENSE" }
      """
    And the current account has 1 "license" for the last "policy"
    And I am a license of account "test1"
    And I authenticate with my key
    When I send a GET request to "/accounts/test1/engines/pypi/simple"
    Then the response status should be "200"
    And the response body should be an HTML document without the following xpaths:
      """
      /html/body/a[@href="https://api.keygen.sh/v1/accounts/$account/engines/pypi/simple/46e034fe-2312-40f8-bbeb-7d9957fb6fcf/"]
      /html/body/a[@href="https://api.keygen.sh/v1/accounts/$account/engines/pypi/simple/2f8af04a-2424-4ca2-8480-6efe24318d1a/"]
      /html/body/a[@href="https://api.keygen.sh/v1/accounts/$account/engines/pypi/simple/7b113ac2-ae81-406a-b44e-f356126e2faa/"]
      """

  Scenario: License requests an index for another open product
    Given the first "product" has the following attributes:
      """
      { "distributionStrategy": "OPEN" }
      """
    And the current account has 1 "policy" with the following:
      """
      { "authenticationStrategy": "LICENSE" }
      """
    And the current account has 1 "license" for the last "policy"
    And I am a license of account "test1"
    And I authenticate with my key
    When I send a GET request to "/accounts/test1/engines/pypi/simple"
    Then the response status should be "200"
    And the response body should be an HTML document with the following xpaths:
      """
      /html/body/a[@href="https://api.keygen.sh/v1/accounts/$account/engines/pypi/simple/46e034fe-2312-40f8-bbeb-7d9957fb6fcf/"]
      /html/body/a[@href="https://api.keygen.sh/v1/accounts/$account/engines/pypi/simple/2f8af04a-2424-4ca2-8480-6efe24318d1a/"]
      /html/body/a[@href="https://api.keygen.sh/v1/accounts/$account/engines/pypi/simple/7b113ac2-ae81-406a-b44e-f356126e2faa/"]
      """

  Scenario: Anonymous requests an index for a licensed product
    Given the first "product" has the following attributes:
      """
      { "distributionStrategy": "LICENSED" }
      """
    When I send a GET request to "/accounts/test1/engines/pypi/simple"
    Then the response status should be "200"
    And the response body should be an HTML document without the following xpaths:
      """
      /html/body/a[@href="https://api.keygen.sh/v1/accounts/$account/engines/pypi/simple/46e034fe-2312-40f8-bbeb-7d9957fb6fcf/"]
      /html/body/a[@href="https://api.keygen.sh/v1/accounts/$account/engines/pypi/simple/2f8af04a-2424-4ca2-8480-6efe24318d1a/"]
      /html/body/a[@href="https://api.keygen.sh/v1/accounts/$account/engines/pypi/simple/7b113ac2-ae81-406a-b44e-f356126e2faa/"]
      """

  Scenario: Anonymous requests an index for a closed product
    Given the first "product" has the following attributes:
      """
      { "distributionStrategy": "CLOSED" }
      """
    When I send a GET request to "/accounts/test1/engines/pypi/simple"
    Then the response status should be "200"
    And the response body should be an HTML document without the following xpaths:
      """
      /html/body/a[@href="https://api.keygen.sh/v1/accounts/$account/engines/pypi/simple/46e034fe-2312-40f8-bbeb-7d9957fb6fcf/"]
      /html/body/a[@href="https://api.keygen.sh/v1/accounts/$account/engines/pypi/simple/2f8af04a-2424-4ca2-8480-6efe24318d1a/"]
      /html/body/a[@href="https://api.keygen.sh/v1/accounts/$account/engines/pypi/simple/7b113ac2-ae81-406a-b44e-f356126e2faa/"]
      """

  Scenario: Anonymous requests an index for an open product
    Given the first "product" has the following attributes:
      """
      { "distributionStrategy": "OPEN" }
      """
    When I send a GET request to "/accounts/test1/engines/pypi/simple"
    Then the response status should be "200"
    And the response body should be an HTML document with the following xpaths:
      """
      /html/body/a[@href="https://api.keygen.sh/v1/accounts/$account/engines/pypi/simple/46e034fe-2312-40f8-bbeb-7d9957fb6fcf/"]
      /html/body/a[@href="https://api.keygen.sh/v1/accounts/$account/engines/pypi/simple/2f8af04a-2424-4ca2-8480-6efe24318d1a/"]
      /html/body/a[@href="https://api.keygen.sh/v1/accounts/$account/engines/pypi/simple/7b113ac2-ae81-406a-b44e-f356126e2faa/"]
      """
