@api/v1
Feature: PyPI simple package files
  Background:
    Given the following "accounts" exist:
      | id                                   | slug  | name   |
      | 14c038fd-b57e-432d-8c09-f50ebcd6a7bc | test1 | Test 1 |
      | b8cd8416-6dfb-44dd-9b69-1d73ee65baed | test2 | Test 2 |
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
      | 70c40946-4b23-408c-aa1c-fa35421ff46a | 6198261a-48b5-4445-a045-9fed4afc7735 | 5666d47e-936e-4d48-8dd7-382d32462b4e | 1.1.0        | stable   |
    And the current account has the following "artifact" rows:
      | id                                   | release_id                           | filename                    | filetype | created_at               | updated_at               |
      | 1f63d6ec-8147-4bf0-bcd2-5d4f0e5eab8f | 757e0a41-835e-42ad-bad8-84cabd29c72a | foo-1.0.0.tar.gz            | tar.gz   | 2024-01-01T01:01:01.000Z | 2024-01-01T01:01:01.000Z |
      | 948f9b83-9e0d-469d-8982-e49213efe85e | 757e0a41-835e-42ad-bad8-84cabd29c72a | foo-1.0.0-py3-none-any.whl  | whl      | 2024-02-02T02:02:02.000Z | 2024-02-02T02:02:02.000Z |
      | c1f8705e-68cd-4312-b2b1-72e19df47bd1 | 3ff04fc6-9f10-4b84-b548-eb40f92ea331 | foo-1.0.1.tar.gz            | tar.gz   | 2024-03-03T03:03:03.000Z | 2024-03-03T03:03:03.000Z |
      | 2fd19ae7-e0cf-4de0-ad4a-1ca65db75c87 | 3ff04fc6-9f10-4b84-b548-eb40f92ea331 | foo-1.0.1-py3-none-any.whl  | whl      | 2024-04-04T04:04:04.000Z | 2024-04-04T04:04:04.000Z |
      | a8e49ea6-17df-4798-937f-e4756e331db5 | 028a38a2-0d17-4871-acb8-c5e6f040fc12 | foo-1.1.0.tar.gz            | tar.gz   | 2024-05-05T05:05:05.000Z | 2024-05-05T05:05:05.000Z |
      | adce1d8b-7120-43b6-a42a-a64c24ed2a25 | 028a38a2-0d17-4871-acb8-c5e6f040fc12 | foo-1.1.0-py3-none-any.whl  | whl      | 2024-06-06T06:06:06.000Z | 2024-06-06T06:06:06.000Z |
      | fa773c2b-1c3a-4bd8-83fe-546480e92098 | 972aa5b8-b12c-49f4-8ba4-7c9ae053dfa2 | bar-1.0.0b1.tar.gz          | tar.gz   | 2024-07-07T07:07:07.000Z | 2024-07-07T07:07:07.000Z |
      | 56277838-ddb5-4c54-a3d2-0fad8bdfefe1 | 972aa5b8-b12c-49f4-8ba4-7c9ae053dfa2 | bar-1.0.0b1-py3-none-any.whl| whl      | 2024-08-08T08:08:08.000Z | 2024-08-08T08:08:08.000Z |
      | 1cccff81-8b49-40b2-9453-3456f2ca04ac | 28a6e16d-c2a6-4be7-8578-e236182ee5c3 | baz-2.0.0.tar.gz            | tar.gz   | 2024-09-09T09:09:09.000Z | 2024-09-09T09:09:09.000Z |
      | ab3f9749-3ea7-4057-92ec-d647784ff097 | 28a6e16d-c2a6-4be7-8578-e236182ee5c3 | baz-2.0.0-py3-none-any.whl  | whl      | 2024-10-10T10:10:10.000Z | 2024-10-10T10:10:10.000Z |
      | d7e01e53-4f9c-48a5-96cb-13207fc25cfe | 70c40946-4b23-408c-aa1c-fa35421ff46a | qux-1.1.0.tar.gz            | tar.gz   | 2024-11-11T11:11:11.000Z | 2024-11-11T11:11:11.000Z |
    And I send the following raw headers:
      """
      User-Agent: pip/23.1.2 {"ci":null,"cpu":"x86_64","distro":{"id":"focal","libc":{"lib":"glibc","version":"2.31"},"name":"Ubuntu","version":"20.04"},"implementation":{"name":"CPython","version":"3.8.10"},"installer":{"name":"pip","version":"23.1.2"},"openssl_version":"OpenSSL 1.1.1f  31 Mar 2020","python":"3.8.10","setuptools_version":"45.2.0","system":{"name":"Linux","release":"5.15.90.1-microsoft-standard-WSL2"}}
      Accept: application/vnd.pypi.simple.v1+json, application/vnd.pypi.simple.v1+html; q=0.1, text/html; q=0.01
      """

  Scenario: Endpoint should be inaccessible when account is disabled
    Given the account "test1" is canceled
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/engines/pypi/simple/foo"
    Then the response status should be "403"
    And the response should contain the following headers:
      """
      { "Content-Type": "text/html; charset=utf-8" }
      """

  @mp
  Scenario: Endpoint should be accessible from subdomain (short)
    Given I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "//pypi.pkg.keygen.sh/test1/simple/bar"
    Then the response status should be "200"
    And the response body should be an HTML document with the following xpaths:
      """
      /html/body/a[text()="bar-1.0.0b1-py3-none-any.whl" and @href="https://pypi.pkg.keygen.sh/v1/accounts/$account/artifacts/56277838-ddb5-4c54-a3d2-0fad8bdfefe1/bar-1.0.0b1-py3-none-any.whl"]
      /html/body/a[text()="bar-1.0.0b1.tar.gz" and @href="https://pypi.pkg.keygen.sh/v1/accounts/$account/artifacts/fa773c2b-1c3a-4bd8-83fe-546480e92098/bar-1.0.0b1.tar.gz"]
      """

  @sp
  Scenario: Endpoint should be accessible from subdomain (short)
    Given I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "//pypi.pkg.keygen.sh/simple/bar"
    Then the response status should be "200"
    And the response body should be an HTML document with the following xpaths:
      """
      /html/body/a[text()="bar-1.0.0b1-py3-none-any.whl" and @href="https://pypi.pkg.keygen.sh/v1/accounts/$account/artifacts/56277838-ddb5-4c54-a3d2-0fad8bdfefe1/bar-1.0.0b1-py3-none-any.whl"]
      /html/body/a[text()="bar-1.0.0b1.tar.gz" and @href="https://pypi.pkg.keygen.sh/v1/accounts/$account/artifacts/fa773c2b-1c3a-4bd8-83fe-546480e92098/bar-1.0.0b1.tar.gz"]
      """

  Scenario: Endpoint should be accessible from subdomain (long)
    Given I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "//pypi.pkg.keygen.sh/v1/accounts/test1/engines/pypi/simple/bar"
    Then the response status should be "200"
    And the response body should be an HTML document with the following xpaths:
      """
      /html/body/a[text()="bar-1.0.0b1-py3-none-any.whl" and @href="https://pypi.pkg.keygen.sh/v1/accounts/$account/artifacts/56277838-ddb5-4c54-a3d2-0fad8bdfefe1/bar-1.0.0b1-py3-none-any.whl"]
      /html/body/a[text()="bar-1.0.0b1.tar.gz" and @href="https://pypi.pkg.keygen.sh/v1/accounts/$account/artifacts/fa773c2b-1c3a-4bd8-83fe-546480e92098/bar-1.0.0b1.tar.gz"]
      """

  Scenario: Endpoint should redirect to PyPI when package does not exist
    Given I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/engines/pypi/simple/qux"
    Then the response status should be "307"
    And the response should contain the following headers:
      """
      { "Location": "https://pypi.org/simple/qux" }
      """

  Scenario: Endpoint should return versions when package exists (PyPI engine)
    Given I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/engines/pypi/simple/foo"
    Then the response status should be "200"
    And the response body should be an HTML document with the following xpaths:
      """
      /html/body/a[text()="foo-1.0.0-py3-none-any.whl" and @href="https://api.keygen.sh/v1/accounts/$account/artifacts/948f9b83-9e0d-469d-8982-e49213efe85e/foo-1.0.0-py3-none-any.whl"]
      /html/body/a[text()="foo-1.0.0.tar.gz" and @href="https://api.keygen.sh/v1/accounts/$account/artifacts/1f63d6ec-8147-4bf0-bcd2-5d4f0e5eab8f/foo-1.0.0.tar.gz"]
      """

  Scenario: Endpoint should return versions when package exists (npm engine)
    Given I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/engines/pypi/simple/qux"
    And the response should contain the following headers:
      """
      { "Location": "https://pypi.org/simple/qux" }
      """

  Scenario: Endpoint should return versions using package ID
    Given I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/engines/pypi/simple/2f8af04a-2424-4ca2-8480-6efe24318d1a"
    Then the response status should be "200"
    And the response body should be an HTML document with the following xpaths:
      """
      /html/body/a[text()="bar-1.0.0b1-py3-none-any.whl" and @href="https://api.keygen.sh/v1/accounts/$account/artifacts/56277838-ddb5-4c54-a3d2-0fad8bdfefe1/bar-1.0.0b1-py3-none-any.whl"]
      /html/body/a[text()="bar-1.0.0b1.tar.gz" and @href="https://api.keygen.sh/v1/accounts/$account/artifacts/fa773c2b-1c3a-4bd8-83fe-546480e92098/bar-1.0.0b1.tar.gz"]
      """

  Scenario: Endpoint should return versions with artifact metadata
    Given the first "artifact" has the following attributes:
      """
      {
        "metadata": {
          "requiresPython": ">=3.0.0"
        }
      }
      """
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/engines/pypi/simple/foo"
    Then the response status should be "200"
    And the response body should be an HTML document with the following xpaths:
      """
      /html/body/a[@data-requires-python=">=3.0.0" and @href="https://api.keygen.sh/v1/accounts/$account/artifacts/1f63d6ec-8147-4bf0-bcd2-5d4f0e5eab8f/foo-1.0.0.tar.gz"]
      """

  Scenario: Endpoint should return versions with artifact checksum (SHA512)
    Given the first "artifact" has the following attributes:
      """
      { "checksum": "f7fbba6e0636f890e56fbbf3283e524c6fa3204ae298382d624741d0dc6638326e282c41be5e4254d8820772c5518a2c5a8c0c7f7eda19594a7eb539453e1ed7" }
      """
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/engines/pypi/simple/foo"
    Then the response status should be "200"
    And the response body should be an HTML document with the following xpaths:
      """
      /html/body/a[@href="https://api.keygen.sh/v1/accounts/$account/artifacts/1f63d6ec-8147-4bf0-bcd2-5d4f0e5eab8f/foo-1.0.0.tar.gz#sha512=f7fbba6e0636f890e56fbbf3283e524c6fa3204ae298382d624741d0dc6638326e282c41be5e4254d8820772c5518a2c5a8c0c7f7eda19594a7eb539453e1ed7"]
      """

  Scenario: Endpoint should return versions with artifact checksum (SHA256)
    Given the first "artifact" has the following attributes:
      """
      { "checksum": "2c26b46b68ffc68ff99b453c1d30413413422d706483bfa0f98a5e886266e7ae" }
      """
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/engines/pypi/simple/foo"
    Then the response status should be "200"
    And the response body should be an HTML document with the following xpaths:
      """
      /html/body/a[@href="https://api.keygen.sh/v1/accounts/$account/artifacts/1f63d6ec-8147-4bf0-bcd2-5d4f0e5eab8f/foo-1.0.0.tar.gz#sha256=2c26b46b68ffc68ff99b453c1d30413413422d706483bfa0f98a5e886266e7ae"]
      """

  Scenario: Endpoint should return versions with artifact checksum (SHA224)
    Given the first "artifact" has the following attributes:
      """
      { "checksum": "50c2dd37763f013d88783a379ef5bb50868dcec12cf81957cbaf9d22" }
      """
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/engines/pypi/simple/foo"
    Then the response status should be "200"
    And the response body should be an HTML document with the following xpaths:
      """
      /html/body/a[@href="https://api.keygen.sh/v1/accounts/$account/artifacts/1f63d6ec-8147-4bf0-bcd2-5d4f0e5eab8f/foo-1.0.0.tar.gz#sha224=50c2dd37763f013d88783a379ef5bb50868dcec12cf81957cbaf9d22"]
      """

  Scenario: Endpoint should return versions with artifact checksum (SHA384)
    Given the first "artifact" has the following attributes:
      """
      { "checksum": "a756b1e7554598049f8af894e3e803ac1ebc0460935747eb0b57d367aecd2548ab8fdeb0e6aace985597ec9a74c9bdbb" }
      """
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/engines/pypi/simple/foo"
    Then the response status should be "200"
    And the response body should be an HTML document with the following xpaths:
      """
      /html/body/a[@href="https://api.keygen.sh/v1/accounts/$account/artifacts/1f63d6ec-8147-4bf0-bcd2-5d4f0e5eab8f/foo-1.0.0.tar.gz#sha384=a756b1e7554598049f8af894e3e803ac1ebc0460935747eb0b57d367aecd2548ab8fdeb0e6aace985597ec9a74c9bdbb"]
      """

  Scenario: Endpoint should return versions with artifact checksum (SHA1)
    Given the first "artifact" has the following attributes:
      """
      { "checksum": "b3da0748d920641a9f47945bee04d241ddd0f5e3" }
      """
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/engines/pypi/simple/foo"
    Then the response status should be "200"
    And the response body should be an HTML document with the following xpaths:
      """
      /html/body/a[@href="https://api.keygen.sh/v1/accounts/$account/artifacts/1f63d6ec-8147-4bf0-bcd2-5d4f0e5eab8f/foo-1.0.0.tar.gz#sha1=b3da0748d920641a9f47945bee04d241ddd0f5e3"]
      """

  Scenario: Endpoint should return versions with artifact checksum (MD5)
    Given the first "artifact" has the following attributes:
      """
      { "checksum": "acbd18db4cc2f85cedef654fccc4a4d8" }
      """
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/engines/pypi/simple/foo"
    Then the response status should be "200"
    And the response body should be an HTML document with the following xpaths:
      """
      /html/body/a[@href="https://api.keygen.sh/v1/accounts/$account/artifacts/1f63d6ec-8147-4bf0-bcd2-5d4f0e5eab8f/foo-1.0.0.tar.gz#md5=acbd18db4cc2f85cedef654fccc4a4d8"]
      """

  Scenario: Endpoint should return versions without artifact checksum (unknown)
    Given the first "artifact" has the following attributes:
      """
      { "checksum": "124803a9" }
      """
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/engines/pypi/simple/foo"
    Then the response status should be "200"
    And the response body should be an HTML document with the following xpaths:
      """
      /html/body/a[@href="https://api.keygen.sh/v1/accounts/$account/artifacts/1f63d6ec-8147-4bf0-bcd2-5d4f0e5eab8f/foo-1.0.0.tar.gz"]
      """

  Scenario: Endpoint should return versions without artifact checksum (base64)
    Given the first "artifact" has the following attributes:
      """
      { "checksum": "jpx0/ZlKmoe+IShOgMe8nQrlXtkTWdWmouBMIyKU/F1zH4b2Gr5myKMRBX6/d3vFoXbm9kAQigiTe+FP1OtmOw==" }
      """
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/engines/pypi/simple/foo"
    Then the response status should be "200"
    And the response body should be an HTML document with the following xpaths:
      """
      /html/body/a[@href="https://api.keygen.sh/v1/accounts/$account/artifacts/1f63d6ec-8147-4bf0-bcd2-5d4f0e5eab8f/foo-1.0.0.tar.gz"]
      """

  Scenario: Endpoint should return versions without artifact checksum (invalid)
    Given the first "artifact" has the following attributes:
      """
      { "checksum": "asdasdasdasd" }
      """
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/engines/pypi/simple/foo"
    Then the response status should be "200"
    And the response body should be an HTML document with the following xpaths:
      """
      /html/body/a[@href="https://api.keygen.sh/v1/accounts/$account/artifacts/1f63d6ec-8147-4bf0-bcd2-5d4f0e5eab8f/foo-1.0.0.tar.gz"]
      """

  Scenario: Endpoint should return versions without artifact checksum (none)
    Given the first "artifact" has the following attributes:
      """
      { "checksum": null }
      """
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a GET request to "/accounts/test1/engines/pypi/simple/foo"
    Then the response status should be "200"
    And the response body should be an HTML document with the following xpaths:
      """
      /html/body/a[@href="https://api.keygen.sh/v1/accounts/$account/artifacts/1f63d6ec-8147-4bf0-bcd2-5d4f0e5eab8f/foo-1.0.0.tar.gz"]
      """

  Scenario: Endpoint should support etags (match)
    Given I am an admin of account "test1"
    And I use an authentication token
    And I send the following raw headers:
      """
      If-None-Match: W/"6d7793913c7e76a1b8964e1798c316ae"
      """
    When I send a GET request to "/accounts/test1/engines/pypi/simple/foo"
    Then the response status should be "304"

  Scenario: Endpoint should support etags (mismatch)
    Given I am an admin of account "test1"
    And I use an authentication token
    And I send the following raw headers:
      """
      If-None-Match: W/"foo"
      """
    When I send a GET request to "/accounts/test1/engines/pypi/simple/foo"
    Then the response status should be "200"
    And the response should contain the following raw headers:
      """
      Etag: W/"6d7793913c7e76a1b8964e1798c316ae"
      Cache-Control: max-age=600, private, no-transform
      """

  Scenario: License requests versions for a licensed product
    Given the last "product" has the following attributes:
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
    When I send a GET request to "/accounts/test1/engines/pypi/simple/foo"
    Then the response status should be "200"

  Scenario: License requests versions for a closed product
    Given the last "product" has the following attributes:
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
    When I send a GET request to "/accounts/test1/engines/pypi/simple/foo"
    Then the response status should be "403"

  Scenario: License requests versions for an open product
    Given the last "product" has the following attributes:
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
    When I send a GET request to "/accounts/test1/engines/pypi/simple/foo"
    Then the response status should be "200"

  Scenario: License requests versions for another licensed product
    Given the last "product" has the following attributes:
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
    When I send a GET request to "/accounts/test1/engines/pypi/simple/foo"
    Then the response status should be "403"

  Scenario: License requests versions for another closed product
    Given the last "product" has the following attributes:
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
    When I send a GET request to "/accounts/test1/engines/pypi/simple/foo"
    Then the response status should be "403"

  Scenario: License requests versions for another open product
    Given the last "product" has the following attributes:
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
    When I send a GET request to "/accounts/test1/engines/pypi/simple/foo"
    Then the response status should be "200"

  Scenario: Anonymous requests versions for a licensed product
    Given the last "product" has the following attributes:
      """
      { "distributionStrategy": "LICENSED" }
      """
    When I send a GET request to "/accounts/test1/engines/pypi/simple/foo"
    Then the response status should be "401"

  Scenario: Anonymous requests versions for a closed product
    Given the last "product" has the following attributes:
      """
      { "distributionStrategy": "CLOSED" }
      """
    When I send a GET request to "/accounts/test1/engines/pypi/simple/foo"
    Then the response status should be "401"

  Scenario: Anonymous requests versions for an open product
    Given the last "product" has the following attributes:
      """
      { "distributionStrategy": "OPEN" }
      """
    When I send a GET request to "/accounts/test1/engines/pypi/simple/foo"
    Then the response status should be "200"

  Scenario: Anonymous requests versions using a previous API version
    Given the last "product" has the following attributes:
      """
      { "distributionStrategy": "OPEN" }
      """
    And I use API version "1.3"
    When I send a GET request to "/accounts/test1/engines/pypi/simple/foo"
    Then the response status should be "200"
