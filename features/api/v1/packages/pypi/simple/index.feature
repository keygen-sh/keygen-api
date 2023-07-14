@api/v1
Feature: PyPI simple package index
  Background:
    Given the following "accounts" exist:
      | Name    | Slug  |
      | Test 1  | test1 |
      | Test 2  | test2 |
    And I send the following raw headers:
      """
      User-Agent: pip/23.1.2 {"ci":null,"cpu":"x86_64","distro":{"id":"focal","libc":{"lib":"glibc","version":"2.31"},"name":"Ubuntu","version":"20.04"},"implementation":{"name":"CPython","version":"3.8.10"},"installer":{"name":"pip","version":"23.1.2"},"openssl_version":"OpenSSL 1.1.1f  31 Mar 2020","python":"3.8.10","setuptools_version":"45.2.0","system":{"name":"Linux","release":"5.15.90.1-microsoft-standard-WSL2"}}
      Accept: application/vnd.pypi.simple.v1+json, application/vnd.pypi.simple.v1+html; q=0.1, text/html; q=0.01
      """

  Scenario: Endpoint should be inaccessible when account is disabled
    Given the account "test1" is canceled
    And the current account is "test1"
    And the current account has 1 "product" with the following:
      """
      { "code": "package1" }
      """
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/packages/pypi/simple"
    Then the response status should be "403"

  Scenario: Endpoint should return an index of packages
    Given the current account is "test1"
    And the current account has 1 "product" with the following:
      """
      {
        "distributionEngine": null,
        "code": "package2"
      }
      """
    And the current account has 1 "product" with the following:
      """
      {
        "distributionEngine": "PYPI",
        "code": "package1"
      }
      """
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/packages/pypi/simple"
    Then the response status should be "200"
    And the response body should be an HTML document without the following xpaths:
      """
      /html/body/a[@href="https://api.keygen.sh/v1/accounts/$account/packages/pypi/simple/$products[0]/"]
      """
    And the response body should be an HTML document with the following xpaths:
      """
      /html/body/a[@href="https://api.keygen.sh/v1/accounts/$account/packages/pypi/simple/$products[1]/"]
      """

  Scenario: Endpoint should return an index with product metadata
    Given the current account is "test1"
    And the current account has 1 "product" with the following:
      """
      {
        "distributionEngine": "PYPI",
        "code": "package1",
        "metadata": {
          "key": "value"
        }
      }
      """
    And the current account has 1 "release" for the last "product"
    And the current account has 1 "artifact" for the last "release" with the following:
      """
      {
        "metadata": {
          "requiresPython": ">=3.0.0"
        }
      }
      """
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/packages/pypi/simple"
    Then the response status should be "200"
    And the response body should be an HTML document with the following xpaths:
      """
      /html/body/a[@href="https://api.keygen.sh/v1/accounts/$account/packages/pypi/simple/$products[0]/" and @data-key="value"]
      """

  Scenario: License requests an index for a licensed product
    Given the current account is "test1"
    And the current account has 1 "product" with the following:
      """
      {
        "distributionStrategy": "LICENSED",
        "distributionEngine": "PYPI",
        "code": "package1"
      }
      """
    And the current account has 1 "policy" for the last "product" with the following:
      """
      { "authenticationStrategy": "LICENSE" }
      """
    And the current account has 1 "license" for the last "policy"
    And I am a license of account "test1"
    And I authenticate with my key
    When I send a GET request to "/accounts/test1/packages/pypi/simple"
    Then the response status should be "200"
    And the response body should be an HTML document with the following xpaths:
      """
      /html/body/a[@href="https://api.keygen.sh/v1/accounts/$account/packages/pypi/simple/$products[0]/"]
      """

  Scenario: License requests an index for a closed product
    Given the current account is "test1"
    And the current account has 1 "product" with the following:
      """
      {
        "distributionStrategy": "CLOSED",
        "distributionEngine": "PYPI",
        "code": "package1"
      }
      """
    And the current account has 1 "policy" for the last "product" with the following:
      """
      { "authenticationStrategy": "LICENSE" }
      """
    And the current account has 1 "license" for the last "policy"
    And I am a license of account "test1"
    And I authenticate with my key
    When I send a GET request to "/accounts/test1/packages/pypi/simple"
    Then the response status should be "200"
    And the response body should be an HTML document without the following xpaths:
      """
      /html/body/a[@href="https://api.keygen.sh/v1/accounts/$account/packages/pypi/simple/$products[0]/"]
      """

  Scenario: License requests an index for an open product
    Given the current account is "test1"
    And the current account has 1 "product" with the following:
      """
      {
        "distributionStrategy": "OPEN",
        "distributionEngine": "PYPI",
        "code": "package1"
      }
      """
    And the current account has 1 "policy" for the last "product" with the following:
      """
      { "authenticationStrategy": "LICENSE" }
      """
    And the current account has 1 "license" for the last "policy"
    And I am a license of account "test1"
    And I authenticate with my key
    When I send a GET request to "/accounts/test1/packages/pypi/simple"
    Then the response status should be "200"
    And the response body should be an HTML document with the following xpaths:
      """
      /html/body/a[@href="https://api.keygen.sh/v1/accounts/$account/packages/pypi/simple/$products[0]/"]
      """

  Scenario: License requests an index for another licensed product
    Given the current account is "test1"
    And the current account has 1 "product" with the following:
      """
      {
        "distributionStrategy": "LICENSED",
        "distributionEngine": "PYPI",
        "code": "package1"
      }
      """
    And the current account has 1 "policy" with the following:
      """
      { "authenticationStrategy": "LICENSE" }
      """
    And the current account has 1 "license" for the last "policy"
    And I am a license of account "test1"
    And I authenticate with my key
    When I send a GET request to "/accounts/test1/packages/pypi/simple"
    Then the response status should be "200"
    And the response body should be an HTML document without the following xpaths:
      """
      /html/body/a[@href="https://api.keygen.sh/v1/accounts/$account/packages/pypi/simple/$products[0]/"]
      """

  Scenario: License requests an index for another closed product
    Given the current account is "test1"
    And the current account has 1 "product" with the following:
      """
      {
        "distributionStrategy": "CLOSED",
        "distributionEngine": "PYPI",
        "code": "package1"
      }
      """
    And the current account has 1 "policy" with the following:
      """
      { "authenticationStrategy": "LICENSE" }
      """
    And the current account has 1 "license" for the last "policy"
    And I am a license of account "test1"
    And I authenticate with my key
    When I send a GET request to "/accounts/test1/packages/pypi/simple"
    Then the response status should be "200"
    And the response body should be an HTML document without the following xpaths:
      """
      /html/body/a[@href="https://api.keygen.sh/v1/accounts/$account/packages/pypi/simple/$products[0]/"]
      """

  Scenario: License requests an index for another open product
    Given the current account is "test1"
    And the current account has 1 "product" with the following:
      """
      {
        "distributionStrategy": "OPEN",
        "distributionEngine": "PYPI",
        "code": "package1"
      }
      """
    And the current account has 1 "policy" with the following:
      """
      { "authenticationStrategy": "LICENSE" }
      """
    And the current account has 1 "license" for the last "policy"
    And I am a license of account "test1"
    And I authenticate with my key
    When I send a GET request to "/accounts/test1/packages/pypi/simple"
    Then the response status should be "200"
    And the response body should be an HTML document with the following xpaths:
      """
      /html/body/a[@href="https://api.keygen.sh/v1/accounts/$account/packages/pypi/simple/$products[0]/"]
      """

  Scenario: Anonymous requests an index for a licensed product
    Given the current account is "test1"
    And the current account has 1 "product" with the following:
      """
      {
        "distributionStrategy": "LICENSED",
        "distributionEngine": "PYPI",
        "code": "package1"
      }
      """
    When I send a GET request to "/accounts/test1/packages/pypi/simple"
    Then the response status should be "200"
    And the response body should be an HTML document without the following xpaths:
      """
      /html/body/a[@href="https://api.keygen.sh/v1/accounts/$account/packages/pypi/simple/$products[0]/"]
      """

  Scenario: Anonymous requests an index for a closed product
    Given the current account is "test1"
    And the current account has 1 "product" with the following:
      """
      {
        "distributionStrategy": "CLOSED",
        "distributionEngine": "PYPI",
        "code": "package1"
      }
      """
    When I send a GET request to "/accounts/test1/packages/pypi/simple"
    Then the response status should be "200"
    And the response body should be an HTML document without the following xpaths:
      """
      /html/body/a[@href="https://api.keygen.sh/v1/accounts/$account/packages/pypi/simple/$products[0]/"]
      """

  Scenario: Anonymous requests an index for an open product
    Given the current account is "test1"
    And the current account has 1 "product" with the following:
      """
      {
        "distributionStrategy": "OPEN",
        "distributionEngine": "PYPI",
        "code": "package1"
      }
      """
    When I send a GET request to "/accounts/test1/packages/pypi/simple"
    Then the response status should be "200"
    And the response body should be an HTML document with the following xpaths:
      """
      /html/body/a[@href="https://api.keygen.sh/v1/accounts/$account/packages/pypi/simple/$products[0]/"]
      """
