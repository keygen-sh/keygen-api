@api/v1
Feature: Update artifact

  Background:
    Given the following "accounts" exist:
      | Name    | Slug  |
      | Test 1  | test1 |
      | Test 2  | test2 |
    And I send and accept JSON

  Scenario: Endpoint should be inaccessible when account is disabled
    Given the account "test1" is canceled
    And the current account is "test1"
    And the current account has 1 published "release"
    And the current account has 1 "artifact" for the last "release"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/artifacts/$0"
    Then the response status should be "403"

    Scenario: Admin updates an artifact's filesize
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 draft "release"
    And the current account has 1 "artifact" for the last "release"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/artifacts/$0" with the following:
      """
      {
        "data": {
          "type": "artifacts",
          "attributes": {
            "filesize": 123456789
          }
        }
      }
      """
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should be an "artifact" with the following attributes:
      """
      { "filesize": 123456789 }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin updates an artifact's null filesize
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 draft "release"
    And the current account has 1 "artifact" for the last "release"
    And the last "artifact" has the following attributes:
      """
      { "filesize": 1 }
      """
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/artifacts/$0" with the following:
      """
      {
        "data": {
          "type": "artifacts",
          "id": "$artifacts[0]",
          "attributes": {
            "filesize": null
          }
        }
      }
      """
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should be an "artifact" with the following attributes:
      """
      { "filesize": null }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin updates an artifact with an empty filesize
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 draft "release"
    And the current account has 1 "artifact" for the last "release"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/artifacts/$0" with the following:
      """
      {
        "data": {
          "type": "artifacts",
          "attributes": {
            "filesize": ""
          }
        }
      }
      """
    Then the response status should be "400"
    And the response body should be an array of 1 error
    And the first error should have the following properties:
      """
      {
        "title": "Bad request",
        "detail": "type mismatch (received string expected integer)",
        "source": {
          "pointer": "/data/attributes/filesize"
        }
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin updates an artifact's signature
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 published "release"
    And the current account has 1 "artifact" for the last "release"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/artifacts/$0" with the following:
      """
      {
        "data": {
          "type": "artifacts",
          "attributes": {
            "signature": "HIvRe+dldchKP30eOAzL7KKdJ12Pqsv87ToM4gMAYmtMe0ffHg89StT07jH+oNE3j/9+zqkrsJrKYFbeFIWABw"
          }
        }
      }
      """
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should be an "artifact" with the following attributes:
      """
      { "signature": "HIvRe+dldchKP30eOAzL7KKdJ12Pqsv87ToM4gMAYmtMe0ffHg89StT07jH+oNE3j/9+zqkrsJrKYFbeFIWABw" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin updates an artifact's null signature
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 published "release"
    And the current account has 1 "artifact" for the last "release"
    And the last "artifact" has the following attributes:
      """
      { "signature": "HIvRe+dldchKP30eOAzL7KKdJ12Pqsv87ToM4gMAYmtMe0ffHg89StT07jH+oNE3j/9+zqkrsJrKYFbeFIWABw" }
      """
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/artifacts/$0" with the following:
      """
      {
        "data": {
          "type": "artifacts",
          "attributes": {
            "signature": null
          }
        }
      }
      """
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should be an "artifact" with the following attributes:
      """
      { "signature": null }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin updates an artifact with an empty signature
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 published "release"
    And the current account has 1 "artifact" for the last "release"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/artifacts/$0" with the following:
      """
      {
        "data": {
          "type": "artifacts",
          "attributes": {
            "signature": ""
          }
        }
      }
      """
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should be an "artifact" with the following attributes:
      """
      { "signature": "" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin updates an artifact's checksum
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 draft "release"
    And the current account has 1 "artifact" for the last "release"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/artifacts/$0" with the following:
      """
      {
        "data": {
          "type": "artifacts",
          "attributes": {
            "checksum": "5m4Mzb9VnYdml5yu5DsF72NIGqo+gCHmoVEs56uBnTPlfUDIuj/IDvPwEeAO+gbijHKGaX6Co85New023rF3XA"
          }
        }
      }
      """
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should be an "artifact" with the following attributes:
      """
      { "checksum": "5m4Mzb9VnYdml5yu5DsF72NIGqo+gCHmoVEs56uBnTPlfUDIuj/IDvPwEeAO+gbijHKGaX6Co85New023rF3XA" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin updates an artifact's null checksum
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 draft "release"
    And the current account has 1 "artifact" for the last "release"
    And the last "artifact" has the following attributes:
      """
      { "checksum": "5m4Mzb9VnYdml5yu5DsF72NIGqo+gCHmoVEs56uBnTPlfUDIuj/IDvPwEeAO+gbijHKGaX6Co85New023rF3XA" }
      """
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/artifacts/$0" with the following:
      """
      {
        "data": {
          "type": "artifacts",
          "attributes": {
            "checksum": null
          }
        }
      }
      """
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should be an "artifact" with the following attributes:
      """
      { "checksum": null }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin updates an artifact with an empty checksum
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 draft "release"
    And the current account has 1 "artifact" for the last "release"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/artifacts/$0" with the following:
      """
      {
        "data": {
          "type": "artifacts",
          "attributes": {
            "checksum": ""
          }
        }
      }
      """
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should be an "artifact" with the following attributes:
      """
      { "checksum": "" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin updates an artifact with metadata
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 yanked "release"
    And the current account has 1 "artifact" for the last "release"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/artifacts/$0" with the following:
      """
      {
        "data": {
          "type": "artifacts",
          "attributes": {
            "metadata": { "foo": "bar" }
          }
        }
      }
      """
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should be an "artifact" with the following attributes:
      """
      { "metadata": { "foo": "bar" } }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin updates an artifact with null metadata
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 yanked "release"
    And the current account has 1 "artifact" for the last "release"
    And the last "artifact" has the following attributes:
      """
      { "metadata": { "foo": "bar" } }
      """
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/artifacts/$0" with the following:
      """
      {
        "data": {
          "type": "artifacts",
          "attributes": {
            "metadata": null
          }
        }
      }
      """
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should be an "artifact" with the following attributes:
      """
      { "metadata": { "foo": "bar" } }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin updates an artifact with empty metadata
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 yanked "release"
    And the current account has 1 "artifact" for the last "release"
    And the last "artifact" has the following attributes:
      """
      { "metadata": { "foo": "bar" } }
      """
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/artifacts/$0" with the following:
      """
      {
        "data": {
          "type": "artifacts",
          "attributes": {
            "metadata": {}
          }
        }
      }
      """
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should be an "artifact" with the following attributes:
      """
      { "metadata": {} }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin updates an artifact's filename
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 published "release"
    And the current account has 1 "artifact" for the last "release"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/artifacts/$0" with the following:
      """
      {
        "data": {
          "type": "artifacts",
          "attributes": {
            "filename": "keygen_darwin_amd64"
          }
        }
      }
      """
    Then the response status should be "400"
    And the response body should be an array of 1 error
    And the first error should have the following properties:
      """
      {
        "title": "Bad request",
        "detail": "unpermitted parameter",
        "source": {
          "pointer": "/data/attributes/filename"
        }
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin updates an artifact's status
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 published "release"
    And the current account has 1 "artifact" for the last "release"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/artifacts/$0" with the following:
      """
      {
        "data": {
          "type": "artifacts",
          "attributes": {
            "status": "UPLOADED"
          }
        }
      }
      """
    Then the response status should be "400"
    And the response body should be an array of 1 error
    And the first error should have the following properties:
      """
      {
        "title": "Bad request",
        "detail": "unpermitted parameter",
        "source": {
          "pointer": "/data/attributes/status"
        }
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Environment updates an artifact (isolated)
    Given the current account is "test1"
    And the current account has 1 isolated "webhook-endpoint"
    And the current account has 1 isolated "environment"
    And the current account has 1 isolated "artifact"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    When I send a PATCH request to "/accounts/test1/artifacts/$0" with the following:
      """
      {
        "data": {
          "type": "artifacts",
          "attributes": {
            "signature": "HIvRe+dldchKP30eOAzL7KKdJ12Pqsv87ToM4gMAYmtMe0ffHg89StT07jH+oNE3j/9+zqkrsJrKYFbeFIWABw",
            "checksum": "5m4Mzb9VnYdml5yu5DsF72NIGqo+gCHmoVEs56uBnTPlfUDIuj/IDvPwEeAO+gbijHKGaX6Co85New023rF3XA"
          }
        }
      }
      """
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should be an "artifact" with the following attributes:
      """
      {
        "signature": "HIvRe+dldchKP30eOAzL7KKdJ12Pqsv87ToM4gMAYmtMe0ffHg89StT07jH+oNE3j/9+zqkrsJrKYFbeFIWABw",
        "checksum": "5m4Mzb9VnYdml5yu5DsF72NIGqo+gCHmoVEs56uBnTPlfUDIuj/IDvPwEeAO+gbijHKGaX6Co85New023rF3XA"
      }
      """
    And the response should contain the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Environment updates an artifact (shared)
    Given the current account is "test1"
    And the current account has 1 shared "webhook-endpoint"
    And the current account has 1 shared "environment"
    And the current account has 1 shared "artifact"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
    When I send a PATCH request to "/accounts/test1/artifacts/$0" with the following:
      """
      {
        "data": {
          "type": "artifacts",
          "attributes": {
            "signature": "HIvRe+dldchKP30eOAzL7KKdJ12Pqsv87ToM4gMAYmtMe0ffHg89StT07jH+oNE3j/9+zqkrsJrKYFbeFIWABw",
            "checksum": "5m4Mzb9VnYdml5yu5DsF72NIGqo+gCHmoVEs56uBnTPlfUDIuj/IDvPwEeAO+gbijHKGaX6Co85New023rF3XA"
          }
        }
      }
      """
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should be an "artifact" with the following attributes:
      """
      {
        "signature": "HIvRe+dldchKP30eOAzL7KKdJ12Pqsv87ToM4gMAYmtMe0ffHg89StT07jH+oNE3j/9+zqkrsJrKYFbeFIWABw",
        "checksum": "5m4Mzb9VnYdml5yu5DsF72NIGqo+gCHmoVEs56uBnTPlfUDIuj/IDvPwEeAO+gbijHKGaX6Co85New023rF3XA"
      }
      """
    And the response should contain the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Product updates an artifact
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 2 "products"
    And the current account has 1 published "release" for the first "product"
    And the current account has 1 "artifact" for the last "release"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/artifacts/$0" with the following:
      """
      {
        "data": {
          "type": "artifacts",
          "attributes": {
            "signature": "HIvRe+dldchKP30eOAzL7KKdJ12Pqsv87ToM4gMAYmtMe0ffHg89StT07jH+oNE3j/9+zqkrsJrKYFbeFIWABw",
            "checksum": "5m4Mzb9VnYdml5yu5DsF72NIGqo+gCHmoVEs56uBnTPlfUDIuj/IDvPwEeAO+gbijHKGaX6Co85New023rF3XA"
          }
        }
      }
      """
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should be an "artifact" with the following attributes:
      """
      {
        "signature": "HIvRe+dldchKP30eOAzL7KKdJ12Pqsv87ToM4gMAYmtMe0ffHg89StT07jH+oNE3j/9+zqkrsJrKYFbeFIWABw",
        "checksum": "5m4Mzb9VnYdml5yu5DsF72NIGqo+gCHmoVEs56uBnTPlfUDIuj/IDvPwEeAO+gbijHKGaX6Co85New023rF3XA"
      }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "metric" job
    And sidekiq should have 1 "request-log" job

  Scenario: Product updates an artifact for another product
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 2 "products"
    And the current account has 1 published "release" for the second "product"
    And the current account has 1 "artifact" for the last "release"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/artifacts/$0" with the following:
      """
      {
        "data": {
          "type": "artifacts",
          "attributes": {
            "signature": "HIvRe+dldchKP30eOAzL7KKdJ12Pqsv87ToM4gMAYmtMe0ffHg89StT07jH+oNE3j/9+zqkrsJrKYFbeFIWABw",
            "checksum": "5m4Mzb9VnYdml5yu5DsF72NIGqo+gCHmoVEs56uBnTPlfUDIuj/IDvPwEeAO+gbijHKGaX6Co85New023rF3XA"
          }
        }
      }
      """
    Then the response status should be "404"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: License updates an artifact they have access to
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 2 "products"
    And the current account has 1 published "release" for the first "product"
    And the current account has 1 "artifact" for the last "release"
    And the current account has 1 "policy" for the first "product"
    And the current account has 1 "license" for the last "policy"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/artifacts/$0" with the following:
      """
      {
        "data": {
          "type": "artifacts",
          "attributes": {
            "signature": "HIvRe+dldchKP30eOAzL7KKdJ12Pqsv87ToM4gMAYmtMe0ffHg89StT07jH+oNE3j/9+zqkrsJrKYFbeFIWABw",
            "checksum": "5m4Mzb9VnYdml5yu5DsF72NIGqo+gCHmoVEs56uBnTPlfUDIuj/IDvPwEeAO+gbijHKGaX6Co85New023rF3XA"
          }
        }
      }
      """
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: License updates an artifact they do not have access to
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And the current account has 1 published "release" for the last "product"
    And the current account has 1 "artifact" for the last "release"
    And the current account has 1 "license"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/artifacts/$0" with the following:
      """
      {
        "data": {
          "type": "artifacts",
          "attributes": {
            "signature": "HIvRe+dldchKP30eOAzL7KKdJ12Pqsv87ToM4gMAYmtMe0ffHg89StT07jH+oNE3j/9+zqkrsJrKYFbeFIWABw",
            "checksum": "5m4Mzb9VnYdml5yu5DsF72NIGqo+gCHmoVEs56uBnTPlfUDIuj/IDvPwEeAO+gbijHKGaX6Co85New023rF3XA"
          }
        }
      }
      """
    Then the response status should be "404"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: User updates an artifact they have access to
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "user"
    And the current account has 1 "product"
    And the current account has 1 published "release" for the last "product"
    And the current account has 1 "artifact" for the last "release"
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "license" for the last "policy"
    And the last "license" has the following attributes:
      """
      { "userId": "$users[1]" }
      """
    And I am a user of account "test1"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/artifacts/$0" with the following:
      """
      {
        "data": {
          "type": "artifacts",
          "attributes": {
            "signature": "HIvRe+dldchKP30eOAzL7KKdJ12Pqsv87ToM4gMAYmtMe0ffHg89StT07jH+oNE3j/9+zqkrsJrKYFbeFIWABw",
            "checksum": "5m4Mzb9VnYdml5yu5DsF72NIGqo+gCHmoVEs56uBnTPlfUDIuj/IDvPwEeAO+gbijHKGaX6Co85New023rF3XA"
          }
        }
      }
      """
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: User updates an artifact they do not have access to
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 2 "products"
    And the current account has 1 published "release" for the first "product"
    And the current account has 1 "artifact" for the last "release"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a PATCH request to "/accounts/test1/artifacts/$0" with the following:
      """
      {
        "data": {
          "type": "artifacts",
          "attributes": {
            "signature": "HIvRe+dldchKP30eOAzL7KKdJ12Pqsv87ToM4gMAYmtMe0ffHg89StT07jH+oNE3j/9+zqkrsJrKYFbeFIWABw",
            "checksum": "5m4Mzb9VnYdml5yu5DsF72NIGqo+gCHmoVEs56uBnTPlfUDIuj/IDvPwEeAO+gbijHKGaX6Co85New023rF3XA"
          }
        }
      }
      """
    Then the response status should be "404"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "metric" jobs
    And sidekiq should have 1 "request-log" job

