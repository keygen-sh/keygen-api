@api/v1
Feature: Create artifact

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
    When I send a POST request to "/accounts/test1/artifacts"
    Then the response status should be "403"

  Scenario: Admin creates an artifact
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 draft "release"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/artifacts" with the following:
      """
      {
        "data": {
          "type": "artifacts",
          "attributes": {
            "filename": "latest-mac.yml",
            "filetype": "yml",
            "filesize": 512,
            "platform": "darwin",
            "arch": "x86"
          },
          "relationships": {
            "release": {
              "data": {
                "type": "releases",
                "id": "$releases[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "307"
    And the response should contain a valid signature header for "test1"
    And the response body should be an "artifact" with the following attributes:
      """
      {
        "filename": "latest-mac.yml",
        "filetype": "yml",
        "filesize": 512,
        "platform": "darwin",
        "arch": "x86",
        "status": "WAITING"
      }
      """
    And the current account should have 1 "artifact"
    And the first "release" should have the following attributes:
      """
      { "status": "DRAFT" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Admin creates a shared artifact
    Given the current account is "test1"
    And the current account has 1 global "webhook-endpoint"
    And the current account has 1 shared "webhook-endpoint"
    And the current account has 1 shared "environment"
    And the current account has 1 draft "release"
    And I am an admin of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
    When I send a POST request to "/accounts/test1/artifacts" with the following:
      """
      {
        "data": {
          "type": "artifacts",
          "attributes": {
            "filename": "dev.yml",
            "filetype": "yml",
            "filesize": 512,
            "platform": "linux",
            "arch": "x86"
          },
          "relationships": {
            "environment": {
              "data": {
                "type": "environments",
                "id": "$environments[0]"
              }
            },
            "release": {
              "data": {
                "type": "releases",
                "id": "$releases[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "307"
    And the response should contain a valid signature header for "test1"
    And the response body should be an "artifact" with the following attributes:
      """
      {
        "filename": "dev.yml",
        "filetype": "yml",
        "filesize": 512,
        "platform": "linux",
        "arch": "x86",
        "status": "WAITING"
      }
      """
    And the response body should be an "artifact" with the following relationships:
      """
      {
        "environment": {
          "links": { "related": "/v1/accounts/$account/environments/$environments[0]" },
          "data": { "type": "environments", "id": "$environments[0]" }
        }
      }
      """
    And the response should contain the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
    And the current account should have 1 "artifact"
    And the first "release" should have the following attributes:
      """
      { "status": "DRAFT" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates an artifact (prefers no-redirect)
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 draft "release"
    And I am an admin of account "test1"
    And I send the following raw headers:
      """
      Prefer: no-redirect
      """
    And I use an authentication token
    When I send a POST request to "/accounts/test1/artifacts" with the following:
      """
      {
        "data": {
          "type": "artifacts",
          "attributes": {
            "filename": "latest-mac.yml",
            "filetype": "yml",
            "filesize": 512,
            "platform": "darwin",
            "arch": "x86"
          },
          "relationships": {
            "release": {
              "data": {
                "type": "releases",
                "id": "$releases[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "200"
    And the response should contain a valid signature header for "test1"
    And the response body should be an "artifact" with the following attributes:
      """
      {
        "filename": "latest-mac.yml",
        "filetype": "yml",
        "filesize": 512,
        "platform": "darwin",
        "arch": "x86",
        "status": "WAITING"
      }
      """
    And the current account should have 1 "artifact"
    And the first "release" should have the following attributes:
      """
      { "status": "DRAFT" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates a duplicate artifact
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 draft "release"
    And the current account has 1 "artifact" for the last "release"
    And the first "artifact" has the following attributes:
      """
      { "filename": "latest-mac.yml" }
      """
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/artifacts" with the following:
      """
      {
        "data": {
          "type": "artifacts",
          "attributes": {
            "filename": "latest-mac.yml",
            "filetype": "yml",
            "filesize": 512,
            "platform": "darwin",
            "arch": "x86"
          },
          "relationships": {
            "release": {
              "data": {
                "type": "releases",
                "id": "$releases[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "422"
    And the response body should be an array of 1 error
    And the first error should have the following properties:
      """
      {
        "title": "Unprocessable resource",
        "detail": "already exists",
        "code": "FILENAME_TAKEN",
        "source": {
          "pointer": "/data/attributes/filename"
        }
      }
      """
    And the current account should have 1 "artifact"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates an artifact with a non-lowercase filename
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 draft "release"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/artifacts" with the following:
      """
      {
        "data": {
          "type": "artifacts",
          "attributes": {
            "filename": "Product-1.0.0.AppImage",
            "filetype": ".AppImage",
            "filesize": 209715200,
            "platform": "linux"
          },
          "relationships": {
            "release": {
              "data": {
                "type": "releases",
                "id": "$releases[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "307"
    And the response should contain a valid signature header for "test1"
    And the response body should be an "artifact" with the following attributes:
      """
      { "filename": "Product-1.0.0.AppImage" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates an artifact with a null filename
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 draft "release"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/artifacts" with the following:
      """
      {
        "data": {
          "type": "artifacts",
          "attributes": {
            "filename": null
          },
          "relationships": {
            "release": {
              "data": {
                "type": "releases",
                "id": "$releases[0]"
              }
            }
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
        "detail": "cannot be null",
        "source": {
          "pointer": "/data/attributes/filename"
        }
      }
      """
    And the current account should have 0 "artifacts"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates an artifact with a non-lowercase filetype
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 draft "release"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/artifacts" with the following:
      """
      {
        "data": {
          "type": "artifacts",
          "attributes": {
            "filename": "Product-1.0.0.AppImage",
            "filetype": ".AppImage",
            "filesize": 209715200,
            "platform": "linux"
          },
          "relationships": {
            "release": {
              "data": {
                "type": "releases",
                "id": "$releases[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "307"
    And the response should contain a valid signature header for "test1"
    And the response body should be an "artifact" with the following attributes:
      """
      { "filetype": "appimage" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates an artifact with a null filetype
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 draft "release"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/artifacts" with the following:
      """
      {
        "data": {
          "type": "artifacts",
          "attributes": {
            "filename": "@keygen/node",
            "filetype": null
          },
          "relationships": {
            "release": {
              "data": {
                "type": "releases",
                "id": "$releases[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "307"
    And the response should contain a valid signature header for "test1"
    And the response body should be an "artifact" with the following attributes:
      """
      { "filetype": null }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates an artifact with an empty filetype
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 draft "release"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/artifacts" with the following:
      """
      {
        "data": {
          "type": "artifacts",
          "attributes": {
            "filename": "@keygen/node",
            "filetype": ""
          },
          "relationships": {
            "release": {
              "data": {
                "type": "releases",
                "id": "$releases[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "307"
    And the response should contain a valid signature header for "test1"
    And the response body should be an "artifact" with the following attributes:
      """
      { "filetype": null }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates an artifact with a null filesize
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 draft "release"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/artifacts" with the following:
      """
      {
        "data": {
          "type": "artifacts",
          "attributes": {
            "filename": "Setup.exe",
            "filetype": "exe",
            "filesize": null
          },
          "relationships": {
            "release": {
              "data": {
                "type": "releases",
                "id": "$releases[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "307"
    And the response should contain a valid signature header for "test1"
    And the response body should be an "artifact" with the following attributes:
      """
      { "filesize": null }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates an artifact with an empty filesize
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 draft "release"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/artifacts" with the following:
      """
      {
        "data": {
          "type": "artifacts",
          "attributes": {
            "filename": "Setup.exe",
            "filetype": "exe",
            "filesize": ""
          },
          "relationships": {
            "release": {
              "data": {
                "type": "releases",
                "id": "$releases[0]"
              }
            }
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
    And the current account should have 0 "artifacts"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates an artifact with a non-lowercase platform
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 draft "release"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/artifacts" with the following:
      """
      {
        "data": {
          "type": "artifacts",
          "attributes": {
            "filename": "App-1.0.0.dmg",
            "filetype": "dmg",
            "platform": "macOS",
            "arch": "M1"
          },
          "relationships": {
            "release": {
              "data": {
                "type": "releases",
                "id": "$releases[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "307"
    And the response should contain a valid signature header for "test1"
    And the response body should be an "artifact" with the following attributes:
      """
      { "platform": "macos" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates an artifact with a null platform
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 draft "release"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/artifacts" with the following:
      """
      {
        "data": {
          "type": "artifacts",
          "attributes": {
            "filename": "install.sh",
            "filetype": "sh",
            "platform": null
          },
          "relationships": {
            "release": {
              "data": {
                "type": "releases",
                "id": "$releases[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "307"
    And the response should contain a valid signature header for "test1"
    And the response body should be an "artifact" with the following attributes:
      """
      { "platform": null }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates an artifact with an empty platform
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 draft "release"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/artifacts" with the following:
      """
      {
        "data": {
          "type": "artifacts",
          "attributes": {
            "filename": "install.sh",
            "filetype": "sh",
            "platform": ""
          },
          "relationships": {
            "release": {
              "data": {
                "type": "releases",
                "id": "$releases[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "307"
    And the response should contain a valid signature header for "test1"
    And the response body should be an "artifact" with the following attributes:
      """
      { "platform": null }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates an artifact with a non-lowercase arch
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 draft "release"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/artifacts" with the following:
      """
      {
        "data": {
          "type": "artifacts",
          "attributes": {
            "filename": "App-1.0.0.dmg",
            "filetype": "dmg",
            "platform": "macOS",
            "arch": "M1"
          },
          "relationships": {
            "release": {
              "data": {
                "type": "releases",
                "id": "$releases[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "307"
    And the response should contain a valid signature header for "test1"
    And the response body should be an "artifact" with the following attributes:
      """
      { "arch": "m1" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates an artifact with a null arch
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 draft "release"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/artifacts" with the following:
      """
      {
        "data": {
          "type": "artifacts",
          "attributes": {
            "filename": "App-1.0.0.dmg",
            "filetype": "dmg",
            "platform": "darwin",
            "arch": null
          },
          "relationships": {
            "release": {
              "data": {
                "type": "releases",
                "id": "$releases[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "307"
    And the response should contain a valid signature header for "test1"
    And the response body should be an "artifact" with the following attributes:
      """
      { "arch": null }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates an artifact with an empty arch
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 draft "release"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/artifacts" with the following:
      """
      {
        "data": {
          "type": "artifacts",
          "attributes": {
            "filename": "App-1.0.0.dmg",
            "filetype": "dmg",
            "platform": "darwin",
            "arch": ""
          },
          "relationships": {
            "release": {
              "data": {
                "type": "releases",
                "id": "$releases[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "307"
    And the response should contain a valid signature header for "test1"
    And the response body should be an "artifact" with the following attributes:
      """
      { "arch": null }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates an artifact with a signature
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 draft "release"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/artifacts" with the following:
      """
      {
        "data": {
          "type": "artifacts",
          "attributes": {
            "filename": "keygen_darwin_amd64",
            "signature": "HIvRe+dldchKP30eOAzL7KKdJ12Pqsv87ToM4gMAYmtMe0ffHg89StT07jH+oNE3j/9+zqkrsJrKYFbeFIWABw"
          },
          "relationships": {
            "release": {
              "data": {
                "type": "releases",
                "id": "$releases[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "307"
    And the response should contain a valid signature header for "test1"
    And the response body should be an "artifact" with the following attributes:
      """
      { "signature": "HIvRe+dldchKP30eOAzL7KKdJ12Pqsv87ToM4gMAYmtMe0ffHg89StT07jH+oNE3j/9+zqkrsJrKYFbeFIWABw" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates an artifact with a null signature
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 draft "release"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/artifacts" with the following:
      """
      {
        "data": {
          "type": "artifacts",
          "attributes": {
            "filename": "keygen_darwin_amd64",
            "signature": null
          },
          "relationships": {
            "release": {
              "data": {
                "type": "releases",
                "id": "$releases[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "307"
    And the response should contain a valid signature header for "test1"
    And the response body should be an "artifact" with the following attributes:
      """
      { "signature": null }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates an artifact with an empty signature
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 draft "release"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/artifacts" with the following:
      """
      {
        "data": {
          "type": "artifacts",
          "attributes": {
            "filename": "keygen_darwin_amd64",
            "signature": ""
          },
          "relationships": {
            "release": {
              "data": {
                "type": "releases",
                "id": "$releases[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "307"
    And the response should contain a valid signature header for "test1"
    And the response body should be an "artifact" with the following attributes:
      """
      { "signature": "" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates an artifact with a checksum
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 draft "release"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/artifacts" with the following:
      """
      {
        "data": {
          "type": "artifacts",
          "attributes": {
            "filename": "keygen_darwin_amd64",
            "checksum": "5m4Mzb9VnYdml5yu5DsF72NIGqo+gCHmoVEs56uBnTPlfUDIuj/IDvPwEeAO+gbijHKGaX6Co85New023rF3XA"
          },
          "relationships": {
            "release": {
              "data": {
                "type": "releases",
                "id": "$releases[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "307"
    And the response should contain a valid signature header for "test1"
    And the response body should be an "artifact" with the following attributes:
      """
      { "checksum": "5m4Mzb9VnYdml5yu5DsF72NIGqo+gCHmoVEs56uBnTPlfUDIuj/IDvPwEeAO+gbijHKGaX6Co85New023rF3XA" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates an artifact with a null checksum
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 draft "release"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/artifacts" with the following:
      """
      {
        "data": {
          "type": "artifacts",
          "attributes": {
            "filename": "keygen_darwin_amd64",
            "checksum": null
          },
          "relationships": {
            "release": {
              "data": {
                "type": "releases",
                "id": "$releases[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "307"
    And the response should contain a valid signature header for "test1"
    And the response body should be an "artifact" with the following attributes:
      """
      { "checksum": null }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates an artifact with an empty checksum
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 draft "release"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/artifacts" with the following:
      """
      {
        "data": {
          "type": "artifacts",
          "attributes": {
            "filename": "keygen_darwin_amd64",
            "checksum": ""
          },
          "relationships": {
            "release": {
              "data": {
                "type": "releases",
                "id": "$releases[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "307"
    And the response should contain a valid signature header for "test1"
    And the response body should be an "artifact" with the following attributes:
      """
      { "checksum": "" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates an artifact with metadata
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 draft "release"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/artifacts" with the following:
      """
      {
        "data": {
          "type": "artifacts",
          "attributes": {
            "filename": "keygen_darwin_amd64",
            "metadata": { "foo": "bar" }
          },
          "relationships": {
            "release": {
              "data": {
                "type": "releases",
                "id": "$releases[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "307"
    And the response should contain a valid signature header for "test1"
    And the response body should be an "artifact" with the following attributes:
      """
      { "metadata": { "foo": "bar" } }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates an artifact with null metadata
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 draft "release"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/artifacts" with the following:
      """
      {
        "data": {
          "type": "artifacts",
          "attributes": {
            "filename": "keygen_darwin_amd64",
            "metadata": null
          },
          "relationships": {
            "release": {
              "data": {
                "type": "releases",
                "id": "$releases[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "307"
    And the response should contain a valid signature header for "test1"
    And the response body should be an "artifact" with the following attributes:
      """
      { "metadata": {} }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  Scenario: Admin creates an artifact with empty metadata
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 draft "release"
    And I am an admin of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/artifacts" with the following:
      """
      {
        "data": {
          "type": "artifacts",
          "attributes": {
            "filename": "keygen_darwin_amd64",
            "metadata": {}
          },
          "relationships": {
            "release": {
              "data": {
                "type": "releases",
                "id": "$releases[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "307"
    And the response should contain a valid signature header for "test1"
    And the response body should be an "artifact" with the following attributes:
      """
      { "metadata": {} }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  @ce
  Scenario: Environment creates an isolated artifact (in isolated environment)
    Given the current account is "test1"
    And the current account has 1 isolated "webhook-endpoint"
    And the current account has 1 isolated "environment"
    And the current account has 1 isolated "release"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    When I send a POST request to "/accounts/test1/artifacts" with the following:
      """
      {
        "data": {
          "type": "artifacts",
          "attributes": {
            "filename": "App-Setup-1-0-0.exe",
            "filetype": "exe",
            "filesize": 512,
            "platform": "win32",
            "arch": "amd64"
          },
          "relationships": {
            "release": {
              "data": {
                "type": "releases",
                "id": "$releases[0]"
              }
            }
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
        "detail": "is unsupported",
        "code": "ENVIRONMENT_NOT_SUPPORTED",
        "source": {
          "header": "Keygen-Environment"
        }
      }
      """
    And the response should contain a valid signature header for "test1"
    And the response should contain the following headers:
      """
      { "Keygen-Environment": null }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Environment creates an isolated artifact (in isolated environment)
    Given the current account is "test1"
    And the current account has 1 isolated "webhook-endpoint"
    And the current account has 1 isolated "environment"
    And the current account has 1 isolated "release"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    When I send a POST request to "/accounts/test1/artifacts" with the following:
      """
      {
        "data": {
          "type": "artifacts",
          "attributes": {
            "filename": "App-Setup-1-0-0.exe",
            "filetype": "exe",
            "filesize": 512,
            "platform": "win32",
            "arch": "amd64"
          },
          "relationships": {
            "release": {
              "data": {
                "type": "releases",
                "id": "$releases[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "307"
    And the response should contain a valid signature header for "test1"
    And the response body should be an "artifact" with the following attributes:
      """
      {
        "filename": "App-Setup-1-0-0.exe",
        "filetype": "exe",
        "filesize": 512,
        "platform": "win32",
        "arch": "amd64",
        "status": "WAITING"
      }
      """
    And the response body should be an "artifact" with the following relationships:
      """
      {
        "environment": {
          "links": { "related": "/v1/accounts/$account/environments/$environments[0]" },
          "data": { "type": "environments", "id": "$environments[0]" }
        }
      }
      """
    And the response should contain the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Environment creates a shared artifact (in isolated environment)
    Given the current account is "test1"
    And the current account has 1 isolated "webhook-endpoint"
    And the current account has 1 isolated "environment"
    And the current account has 1 shared "environment"
    And the current account has 1 isolated "release"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    When I send a POST request to "/accounts/test1/artifacts" with the following:
      """
      {
        "data": {
          "type": "artifacts",
          "attributes": {
            "filename": "App-Setup-1-0-0.exe",
            "filetype": "exe",
            "filesize": 512,
            "platform": "win32",
            "arch": "amd64"
          },
          "relationships": {
            "environment": {
              "data": {
                "type": "environments",
                "id": "$environments[1]"
              }
            },
            "release": {
              "data": {
                "type": "releases",
                "id": "$releases[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "403"
    And the response body should be an array of 1 error
    And the first error should have the following properties:
      """
      {
        "title": "Access denied",
        "detail": "You do not have permission to complete the request (record environment is not compatible with the current environment)"
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Environment creates a global artifact (in isolated environment)
    Given the current account is "test1"
    And the current account has 1 isolated "webhook-endpoint"
    And the current account has 1 isolated "environment"
    And the current account has 1 isolated "release"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "isolated" }
      """
    When I send a POST request to "/accounts/test1/artifacts" with the following:
      """
      {
        "data": {
          "type": "artifacts",
          "attributes": {
            "filename": "App-Setup-1-0-0.exe",
            "filetype": "exe",
            "filesize": 512,
            "platform": "win32",
            "arch": "amd64"
          },
          "relationships": {
            "environment": {
              "data": null
            },
            "release": {
              "data": {
                "type": "releases",
                "id": "$releases[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "403"
    And the response body should be an array of 1 error
    And the first error should have the following properties:
      """
      {
        "title": "Access denied",
        "detail": "You do not have permission to complete the request (record environment is not compatible with the current environment)"
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Environment creates a shared artifact (in shared environment)
    Given the current account is "test1"
    And the current account has 1 shared "webhook-endpoint"
    And the current account has 1 shared "environment"
    And the current account has 1 shared "release"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
    When I send a POST request to "/accounts/test1/artifacts" with the following:
      """
      {
        "data": {
          "type": "artifacts",
          "attributes": {
            "filename": "App-Setup-1-0-0.exe",
            "filetype": "exe",
            "filesize": 512,
            "platform": "win32",
            "arch": "amd64"
          },
          "relationships": {
            "release": {
              "data": {
                "type": "releases",
                "id": "$releases[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "307"
    And the response should contain a valid signature header for "test1"
    And the response body should be an "artifact" with the following attributes:
      """
      {
        "filename": "App-Setup-1-0-0.exe",
        "filetype": "exe",
        "filesize": 512,
        "platform": "win32",
        "arch": "amd64",
        "status": "WAITING"
      }
      """
    And the response body should be an "artifact" with the following relationships:
      """
      {
        "environment": {
          "links": { "related": "/v1/accounts/$account/environments/$environments[0]" },
          "data": { "type": "environments", "id": "$environments[0]" }
        }
      }
      """
    And the response should contain the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Environment creates an isolated artifact (in shared environment)
    Given the current account is "test1"
    And the current account has 1 shared "webhook-endpoint"
    And the current account has 1 shared "environment"
    And the current account has 1 isolated "environment"
    And the current account has 1 shared "release"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
    When I send a POST request to "/accounts/test1/artifacts" with the following:
      """
      {
        "data": {
          "type": "artifacts",
          "attributes": {
            "filename": "App-Setup-1-0-0.exe",
            "filetype": "exe",
            "filesize": 512,
            "platform": "win32",
            "arch": "amd64"
          },
          "relationships": {
            "environment": {
              "data": {
                "type": "environments",
                "id": "$environments[1]"
              }
            },
            "release": {
              "data": {
                "type": "releases",
                "id": "$releases[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "403"
    And the response body should be an array of 1 error
    And the first error should have the following properties:
      """
      {
        "title": "Access denied",
        "detail": "You do not have permission to complete the request (record environment is not compatible with the current environment)"
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Environment creates a global artifact (in shared environment)
    Given the current account is "test1"
    And the current account has 1 shared "webhook-endpoint"
    And the current account has 1 shared "environment"
    And the current account has 1 shared "release"
    And I am an environment of account "test1"
    And I use an authentication token
    And I send the following headers:
      """
      { "Keygen-Environment": "shared" }
      """
    When I send a POST request to "/accounts/test1/artifacts" with the following:
      """
      {
        "data": {
          "type": "artifacts",
          "attributes": {
            "filename": "App-Setup-1-0-0.exe",
            "filetype": "exe",
            "filesize": 512,
            "platform": "win32",
            "arch": "amd64"
          },
          "relationships": {
            "environment": {
              "data": null
            },
            "release": {
              "data": {
                "type": "releases",
                "id": "$releases[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "403"
    And the response body should be an array of 1 error
    And the first error should have the following properties:
      """
      {
        "title": "Access denied",
        "detail": "You do not have permission to complete the request (record environment is not compatible with the current environment)"
      }
      """
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  @ee
  Scenario: Environment creates a global artifact (in nil environment)
    Given the current account is "test1"
    And the current account has 1 shared "webhook-endpoint"
    And the current account has 1 shared "environment"
    And the current account has 1 shared "release"
    And I am an environment of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/artifacts" with the following:
      """
      {
        "data": {
          "type": "artifacts",
          "attributes": {
            "filename": "App-Setup-1-0-0.exe",
            "filetype": "exe",
            "filesize": 512,
            "platform": "win32",
            "arch": "amd64"
          },
          "relationships": {
            "environment": {
              "data": null
            },
            "release": {
              "data": {
                "type": "releases",
                "id": "$releases[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "401"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Product creates an artifact
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And the current account has 1 draft "release" for the last "product"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/artifacts" with the following:
      """
      {
        "data": {
          "type": "artifacts",
          "attributes": {
            "filename": "App-Setup-1-0-0.exe",
            "filetype": "exe",
            "filesize": 512,
            "platform": "win32",
            "arch": "amd64"
          },
          "relationships": {
            "release": {
              "data": {
                "type": "releases",
                "id": "$releases[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "307"
    And the response should contain a valid signature header for "test1"
    And the response body should be an "artifact" with the following attributes:
      """
      {
        "filename": "App-Setup-1-0-0.exe",
        "filetype": "exe",
        "filesize": 512,
        "platform": "win32",
        "arch": "amd64",
        "status": "WAITING"
      }
      """
    And sidekiq should have 1 "webhook" job
    And sidekiq should have 1 "event-log" job
    And sidekiq should have 1 "request-log" job

  Scenario: Product creates an artifact for another product
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 2 "products"
    And the current account has 1 draft "release" for the last "product"
    And I am a product of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/artifacts" with the following:
      """
      {
        "data": {
          "type": "artifacts",
          "attributes": {
            "filename": "App-Setup-1-0-0.exe",
            "filetype": "exe",
            "filesize": 512,
            "platform": "win32",
            "arch": "amd64"
          },
          "relationships": {
            "release": {
              "data": {
                "type": "releases",
                "id": "$releases[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: License creates an artifact
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And the current account has 1 draft "release" for the last "product"
    And the current account has 1 "policy" for the last "product"
    And the current account has 1 "license" for the last "policy"
    And I am a license of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/artifacts" with the following:
      """
      {
        "data": {
          "type": "artifacts",
          "attributes": {
            "filename": "App-Setup-1-0-0.exe"
          },
          "relationships": {
            "release": {
              "data": {
                "type": "releases",
                "id": "$releases[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: User creates an artifact
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And the current account has 1 draft "release" for the last "product"
    And the current account has 1 "user"
    And I am a user of account "test1"
    And I use an authentication token
    When I send a POST request to "/accounts/test1/artifacts" with the following:
      """
      {
        "data": {
          "type": "artifacts",
          "attributes": {
            "filename": "App-Setup-1-0-0.zip"
          },
          "relationships": {
            "release": {
              "data": {
                "type": "releases",
                "id": "$releases[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "403"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job

  Scenario: Anonymous creates an artifact
    Given the current account is "test1"
    And the current account has 1 "webhook-endpoint"
    And the current account has 1 "product"
    And the current account has 1 draft "release" for the last "product"
    When I send a POST request to "/accounts/test1/artifacts" with the following:
      """
      {
        "data": {
          "type": "artifacts",
          "attributes": {
            "filename": "App-Setup-1-0-0.zip"
          },
          "relationships": {
            "release": {
              "data": {
                "type": "releases",
                "id": "$releases[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "401"
    And sidekiq should have 0 "webhook" jobs
    And sidekiq should have 0 "event-log" jobs
    And sidekiq should have 1 "request-log" job
