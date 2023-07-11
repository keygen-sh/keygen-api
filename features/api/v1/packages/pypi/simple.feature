@api/v1
Feature: PyPI simple index
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
    When I send a GET request to "/accounts/test1/packages/pypi/simple/package1"
    Then the response status should be "403"

  Scenario: Endpoint should redirect to PyPI when package does not exist
    Given the current account is "test1"
    And the current account has 1 "product" with the following:
      """
      { "code": "package1" }
      """
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/packages/pypi/simple/package2"
    Then the response status should be "307"
    And the response should contain the following headers:
      """
      { "Location": "https://pypi.org/simple/package2" }
      """

  Scenario: Endpoint should return an index when package exists
    Given the current account is "test1"
    And the current account has 1 "product" with the following:
      """
      { "code": "package1" }
      """
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/packages/pypi/simple/package1"
    Then the response status should be "200"

  Scenario: Endpoint should return an index using product ID
    Given the current account is "test1"
    And the current account has 1 "product" with the following:
      """
      { "id": "297dd28f-6043-456b-a737-714b72e1a852", "code": "package1" }
      """
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/packages/pypi/simple/297dd28f-6043-456b-a737-714b72e1a852"
    Then the response status should be "200"

  Scenario: License requests an index for their product
    Given the current account is "test1"
    And the current account has 1 "product" with the following:
      """
      { "code": "package1" }
      """
    And the current account has 1 "policy" for the last "product" with the following:
      """
      { "authenticationStrategy": "LICENSE" }
      """
    And the current account has 1 "license" for the last "policy"
    And I am a license of account "test1"
    And I authenticate with my key
    When I send a GET request to "/accounts/test1/packages/pypi/simple/package1"
    Then the response status should be "200"

  Scenario: License requests an index for another product
    Given the current account is "test1"
    And the current account has 1 "product" with the following:
      """
      { "code": "package1" }
      """
    And the current account has 1 "policy" with the following:
      """
      { "authenticationStrategy": "LICENSE" }
      """
    And the current account has 1 "license" for the last "policy"
    And I am a license of account "test1"
    And I authenticate with my key
    When I send a GET request to "/accounts/test1/packages/pypi/simple/package1"
    Then the response status should be "307"
    And the response should contain the following headers:
      """
      { "Location": "https://pypi.org/simple/package1" }
      """

  Scenario: Anonymous requests an index
    Given the current account is "test1"
    And the current account has 1 "product" with the following:
      """
      { "code": "package1" }
      """
    When I send a GET request to "/accounts/test1/packages/pypi/simple/package1"
    Then the response status should be "307"
    And the response should contain the following headers:
      """
      { "Location": "https://pypi.org/simple/package1" }
      """
