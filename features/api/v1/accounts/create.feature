@api/v1
@mp
Feature: Create account
  Background:
    Given I send and accept JSON
    And there exists 1 "plan"

  Scenario: Anonymous creates an account
    When I send a POST request to "/accounts" with the following:
      """
      {
        "data": {
          "type": "accounts",
          "attributes": {
            "name": "Google",
            "slug": "google"
          },
          "relationships": {
            "plan": {
              "data": {
                "type": "plans",
                "id": "$plan[0]"
              }
            },
            "admins": {
              "data": [
                {
                  "type": "user",
                  "attributes": {
                    "firstName": "Larry",
                    "lastName": "Page",
                    "email": "lpage@keygen.sh",
                    "password": "googling"
                  }
                }
              ]
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the response body should be an "account" with the name "Google"
    And the response body should be an "account" with the slug "google"
    And the response body should be an "account" with the following meta:
      """
      {
        "publicKey": "$~accounts[0].public_key",
        "keys": {
          "ed25519": "$~accounts[0].ed25519_public_key",
          "rsa2048": "$~accounts[0].public_key"
        }
      }
      """
    And the account should receive a "prompt-for-first-impression" email
    And sidekiq should have 1 "initialize-billing" job
    And sidekiq should have 0 "request-log" jobs
    And the account "google" should not have a referral
    And the account "google" should have 1 "admin"

  Scenario: Anonymous creates an account with multiple admins
    When I send a POST request to "/accounts" with the following:
      """
      {
        "data": {
          "type": "accounts",
          "attributes": {
            "name": "Google",
            "slug": "google"
          },
          "relationships": {
            "plan": {
              "data": {
                "type": "plans",
                "id": "$plan[0]"
              }
            },
            "admins": {
              "data": [
                {
                  "type": "user",
                  "attributes": {
                    "email": "lpage@google.example",
                    "password": "googling"
                  }
                },
                {
                  "type": "user",
                  "attributes": {
                    "email": "sbrin@google.example"
                  }
                }
              ]
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the response body should be an "account" with the name "Google"
    And the response body should be an "account" with the slug "google"
    And the response body should be an "account" with the following meta:
      """
      {
        "publicKey": "$~accounts[0].public_key",
        "keys": {
          "ed25519": "$~accounts[0].ed25519_public_key",
          "rsa2048": "$~accounts[0].public_key"
        }
      }
      """
    And the account should receive a "prompt-for-first-impression" email
    And sidekiq should have 1 "initialize-billing" job
    And sidekiq should have 0 "request-log" jobs
    And the account "google" should not have a referral
    And the account "google" should have 2 "admins"

  Scenario: Anonymous creates an account (default API version)
    When I send a POST request to "/accounts" with the following:
      """
      {
        "data": {
          "type": "accounts",
          "attributes": {
            "name": "Latest Version"
          },
          "relationships": {
            "plan": {
              "data": { "type": "plans", "id": "$plan[0]" }
            },
            "admins": {
              "data": [
                {
                  "type": "user",
                  "attributes": { "firstName": "John", "lastName": "Doe", "email": "john.doe@keygen.example", "password": "secret" }
                }
              ]
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the response should contain the following headers:
      """
      { "Keygen-Version": "1.8" }
      """
    And the response body should be an "account" with the following attributes:
      """
      { "apiVersion": "1.8" }
      """

  Scenario: Anonymous creates an account (specific API version)
    Given I send the following headers:
      """
      { "Keygen-Version": "1.5" }
      """
    When I send a POST request to "/accounts" with the following:
      """
      {
        "data": {
          "type": "accounts",
          "attributes": {
            "name": "Version 1.5",
            "slug": "v1x5"
          },
          "relationships": {
            "plan": {
              "data": { "type": "plans", "id": "$plan[0]" }
            },
            "admins": {
              "data": [
                {
                  "type": "user",
                  "attributes": { "firstName": "John", "lastName": "Doe", "email": "john.doe@keygen.example", "password": "secret" }
                }
              ]
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the response should contain the following headers:
      """
      { "Keygen-Version": "1.5" }
      """
    And the response body should be an "account" with the following attributes:
      """
      { "apiVersion": "1.5" }
      """

  Scenario: Anonymous creates an account with a referral ID
    When I send a POST request to "/accounts" with the following:
      """
      {
        "data": {
          "type": "accounts",
          "attributes": {
            "name": "Referred",
            "slug": "referred"
          },
          "relationships": {
            "plan": {
              "data": {
                "type": "plans",
                "id": "$plan[0]"
              }
            },
            "admins": {
              "data": [
                {
                  "type": "user",
                  "attributes": {
                    "email": "elliot@allsafe.com",
                    "password": "mr.robot"
                  }
                }
              ]
            }
          }
        },
        "meta": {
          "referral": "bf376e7e-31a1-45d4-9e6d-d12f31fa5353"
        }
      }
      """
    Then the response status should be "201"
    And the response body should be an "account" with the following attributes:
      """
      {
        "name": "Referred",
        "slug": "referred"
      }
      """
    And sidekiq should have 1 "initialize-billing" job
    And sidekiq should have 0 "request-log" jobs
    And the account "referred" should have a referral of "bf376e7e-31a1-45d4-9e6d-d12f31fa5353"
    And the account "referred" should have 1 "admin"

  Scenario: Anonymous creates an account with admin metadata
    When I send a POST request to "/accounts" with the following:
      """
      {
        "data": {
          "type": "accounts",
          "attributes": {
            "name": "Meta",
            "slug": "meta"
          },
          "relationships": {
            "plan": {
              "data": {
                "type": "plans",
                "id": "$plan[0]"
              }
            },
            "admins": {
              "data": [
                {
                  "type": "user",
                  "attributes": {
                    "email": "elliot@allsafe.com",
                    "password": "mr.robot",
                    "metadata": {
                      "foo": "bar"
                    }
                  }
                }
              ]
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the response body should be an "account" with the following attributes:
      """
      {
        "name": "Meta",
        "slug": "meta"
      }
      """
    And the first "user" for account "meta" should have the following attributes:
      """
      {
        "email": "elliot@allsafe.com",
        "metadata": {
          "foo": "bar"
        }
      }
      """
    And sidekiq should have 1 "initialize-billing" job
    And sidekiq should have 0 "request-log" jobs
    And the account "meta" should have 1 "admin"

  Scenario: Anonymous creates an account with autogenerated account information
    When I send a POST request to "/accounts" with the following:
      """
      {
        "data": {
          "type": "accounts",
          "relationships": {
            "plan": {
              "data": {
                "type": "plans",
                "id": "$plan[0]"
              }
            },
            "admins": {
              "data": [
                {
                  "type": "user",
                  "attributes": {
                    "email": "zeke@keygen.sh",
                    "password": "pa$$w0rd!"
                  }
                }
              ]
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the response body should be an "account" with the slug "keygen-sh"
    And the response body should be an "account" with the name "keygen.sh"
    And the account should receive a "prompt-for-first-impression" email
    And the account "keygen-sh" should have 1 "admin"

  Scenario: Anonymous creates an account with autogenerated account information using a domain that is already used
    Given there exists an account "keygen-sh"
    When I send a POST request to "/accounts" with the following:
      """
      {
        "data": {
          "type": "accounts",
          "relationships": {
            "plan": {
              "data": {
                "type": "plans",
                "id": "$plan[0]"
              }
            },
            "admins": {
              "data": [
                {
                  "type": "user",
                  "attributes": {
                    "email": "zeke@keygen.sh",
                    "password": "pa$$w0rd!"
                  }
                }
              ]
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
        "detail": "already exists for this domain (please choose a different value or use account recovery)",
        "source": {
          "pointer": "/data/attributes/slug"
        }
      }
      """

  Scenario: Anonymous creates an account with autogenerated account information using a public email service
    Given there exists an account "gmail-com"
    When I send a POST request to "/accounts" with the following:
      """
      {
        "data": {
          "type": "accounts",
          "relationships": {
            "plan": {
              "data": {
                "type": "plans",
                "id": "$plan[0]"
              }
            },
            "admins": {
              "data": [
                {
                  "type": "user",
                  "attributes": {
                    "email": "zeke.gabrielse@gmail.com",
                    "password": "passw0rd"
                  }
                }
              ]
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the response body should be an "account" with a slug "zeke-gabrielse"
    And the response body should be an "account" with a name "zeke.gabrielse"
    And the account should receive a "prompt-for-first-impression" email

  Scenario: Anonymous creates an account with autogenerated account information using a public email service with underscores
    When I send a POST request to "/accounts" with the following:
      """
      {
        "data": {
          "type": "accounts",
          "relationships": {
            "plan": {
              "data": {
                "type": "plans",
                "id": "$plan[0]"
              }
            },
            "admins": {
              "data": [
                {
                  "type": "user",
                  "attributes": {
                    "email": "foo_bar@gmail.com",
                    "password": "passw0rd"
                  }
                }
              ]
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the response body should be an "account" with a slug "foo-bar"
    And the response body should be an "account" with a name "foo_bar"
    And the account should receive a "prompt-for-first-impression" email

  Scenario: Anonymous creates an account with autogenerated account information using a public email that is already used
    Given there exists an account "zekeg1991"
    When I send a POST request to "/accounts" with the following:
      """
      {
        "data": {
          "type": "accounts",
          "relationships": {
            "plan": {
              "data": {
                "type": "plans",
                "id": "$plan[0]"
              }
            },
            "admins": {
              "data": [
                {
                  "type": "user",
                  "attributes": {
                    "email": "zekeg1991@gmail.com",
                    "password": "passw0rd"
                  }
                }
              ]
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the response body should be an "account" with a slug that is not "zekeg1991"
    And the response body should be an "account" with a name "zekeg1991"
    And the account should receive a "prompt-for-first-impression" email

  Scenario: Anonymous creates an account with autogenerated account information using a public email in all caps
    When I send a POST request to "/accounts" with the following:
      """
      {
        "data": {
          "type": "accounts",
          "relationships": {
            "plan": {
              "data": {
                "type": "plans",
                "id": "$plan[0]"
              }
            },
            "admins": {
              "data": [
                {
                  "type": "user",
                  "attributes": {
                    "email": "TEST@GMAIL.COM",
                    "password": "pa$$word"
                  }
                }
              ]
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the response body should be an "account" with a slug that is not "gmail-com"
    And the response body should be an "account" with a name that is not "GMAIL.COM"
    And the account should receive a "prompt-for-first-impression" email

  Scenario: Anonymous creates an account using a slug in all caps that is already used
    Given there exists an account "keygen-sh"
    When I send a POST request to "/accounts" with the following:
      """
      {
        "data": {
          "type": "accounts",
          "attributes": {
            "slug": "KEYGEN-SH"
          },
          "relationships": {
            "plan": {
              "data": {
                "type": "plans",
                "id": "$plan[0]"
              }
            },
            "admins": {
              "data": [
                {
                  "type": "user",
                  "attributes": {
                    "email": "zeke@keygen.sh",
                    "password": "pa$$w0rd!"
                  }
                }
              ]
            }
          }
        }
      }
      """
    Then the response status should be "422"
    And the response body should be an array of 2 errors
    And the first error should have the following properties:
      """
      {
        "title": "Unprocessable resource",
        "detail": "can only contain lowercase letters, numbers and dashes (but cannot start with dash)",
        "source": {
          "pointer": "/data/attributes/slug"
        }
      }
      """
    And the second error should have the following properties:
      """
      {
        "title": "Unprocessable resource",
        "detail": "has already been taken",
        "source": {
          "pointer": "/data/attributes/slug"
        }
      }
      """

  Scenario: Anonymous creates an account with a UUID slug with dashes
    When I send a POST request to "/accounts" with the following:
      """
      {
        "data": {
          "type": "accounts",
          "attributes": {
            "name": "Hacker",
            "slug": "ace6b050-6dc0-4cb5-85e9-ad87f629255f"
          },
          "relationships": {
            "plan": {
              "data": {
                "type": "plans",
                "id": "$plan[0]"
              }
            },
            "admins": {
              "data": [
                {
                  "type": "user",
                  "attributes": {
                    "firstName": "Elliot",
                    "lastName": "Alderson",
                    "email": "elliot@allsafe.com",
                    "password": "mr.robot"
                  }
                }
              ]
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
        "detail": "cannot resemble a UUID",
        "source": {
          "pointer": "/data/attributes/slug"
        }
      }
      """

  Scenario: Anonymous creates an account with a UUID slug without dashes
    When I send a POST request to "/accounts" with the following:
      """
      {
        "data": {
          "type": "accounts",
          "attributes": {
            "name": "Hacker",
            "slug": "ace6b0506dc04cb585e9ad87f629255f"
          },
          "relationships": {
            "plan": {
              "data": {
                "type": "plans",
                "id": "$plan[0]"
              }
            },
            "admins": {
              "data": [
                {
                  "type": "user",
                  "attributes": {
                    "firstName": "Elliot",
                    "lastName": "Alderson",
                    "email": "elliot@allsafe.com",
                    "password": "mr.robot"
                  }
                }
              ]
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
        "detail": "cannot resemble a UUID",
        "source": {
          "pointer": "/data/attributes/slug"
        }
      }
      """

  Scenario: Anonymous creates an account with a UUID slug with oddly placed dashes
    When I send a POST request to "/accounts" with the following:
      """
      {
        "data": {
          "type": "accounts",
          "attributes": {
            "name": "Hacker",
            "slug": "ace-6b0506d-c04cb5-85e9a-d87f62-9255f"
          },
          "relationships": {
            "plan": {
              "data": {
                "type": "plans",
                "id": "$plan[0]"
              }
            },
            "admins": {
              "data": [
                {
                  "type": "user",
                  "attributes": {
                    "firstName": "Elliot",
                    "lastName": "Alderson",
                    "email": "elliot@allsafe.com",
                    "password": "mr.robot"
                  }
                }
              ]
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
        "detail": "cannot resemble a UUID",
        "source": {
          "pointer": "/data/attributes/slug"
        }
      }
      """

  Scenario: Anonymous creates an account with a dash slug
    When I send a POST request to "/accounts" with the following:
      """
      {
        "data": {
          "type": "accounts",
          "attributes": {
            "name": "Hacker",
            "slug": "-"
          },
          "relationships": {
            "plan": {
              "data": {
                "type": "plans",
                "id": "$plan[0]"
              }
            },
            "admins": {
              "data": [
                {
                  "type": "user",
                  "attributes": {
                    "firstName": "Elliot",
                    "lastName": "Alderson",
                    "email": "elliot@allsafe.com",
                    "password": "mr.robot"
                  }
                }
              ]
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
        "detail": "can only contain lowercase letters, numbers and dashes (but cannot start with dash)",
        "source": {
          "pointer": "/data/attributes/slug"
        }
      }
      """

  Scenario: Anonymous creates an account with a UUID email user to takeover via an autogenerated slug
    When I send a POST request to "/accounts" with the following:
      """
      {
        "data": {
          "type": "accounts",
          "attributes": {
            "slug": "ace6b050-6dc0-4cb5-85e9-ad87f629255f"
          },
          "relationships": {
            "plan": {
              "data": {
                "type": "plans",
                "id": "$plan[0]"
              }
            },
            "admins": {
              "data": [
                {
                  "type": "user",
                  "attributes": {
                    "email": "ace6b050-6dc0-4cb5-85e9-ad87f629255f@icloud.com",
                    "password": "secret123"
                  }
                }
              ]
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
        "detail": "cannot resemble a UUID",
        "source": {
          "pointer": "/data/attributes/slug"
        }
      }
      """

  Scenario: Anonymous creates an account with an imposter UUID to takeover via an autogenerated slug
    When I send a POST request to "/accounts" with the following:
      """
      {
        "data": {
          "type": "accounts",
          "attributes": {},
          "relationships": {
            "plan": {
              "data": {
                "type": "plans",
                "id": "$plan[0]"
              }
            },
            "admins": {
              "data": [
                {
                  "type": "user",
                  "attributes": {
                    "email": "-ace6b0506dc04cb585e9ad87f629255f-@icloud.com",
                    "password": "secret123"
                  }
                }
              ]
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
        "detail": "cannot resemble a UUID",
        "source": {
          "pointer": "/data/attributes/slug"
        }
      }
      """

  # NOTE: This is really just a test to make sure endpoints are valid even when
  #       we're authenticated as another account
  Scenario: Admin of an account creates another account
    Given the following "accounts" exist:
      | Name      | Slug      |
      | Hashicorp | hashicorp |
    And I am an admin of account "hashicorp"
    And I use an authentication token
    When I send a POST request to "/accounts" with the following:
      """
      {
        "data": {
          "type": "accounts",
          "attributes": {
            "name": "Google",
            "slug": "google"
          },
          "relationships": {
            "plan": {
              "data": {
                "type": "plans",
                "id": "$plan[0]"
              }
            },
            "admins": {
              "data": [
                {
                  "type": "user",
                  "attributes": {
                    "firstName": "Larry",
                    "lastName": "Page",
                    "email": "lpage@keygen.sh",
                    "password": "hunter2!"
                  }
                }
              ]
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the response body should be an "account" with the name "Google"
    And the account "google" should have 1 "admin"

  Scenario: Anonymous creates a protected account with multiple admins
    When I send a POST request to "/accounts" with the following:
      """
      {
        "data": {
          "type": "accounts",
          "attributes": {
            "name": "Google",
            "slug": "google",
            "protected": true
          },
          "relationships": {
            "plan": {
              "data": {
                "type": "plans",
                "id": "$plan[0]"
              }
            },
            "admins": {
              "data": [
                {
                  "type": "user",
                  "attributes": {
                    "firstName": "Larry",
                    "lastName": "Page",
                    "email": "lpage@keygen.sh",
                    "password": "password1"
                  }
                },
                {
                  "type": "user",
                  "attributes": {
                    "firstName": "Sergey",
                    "lastName": "Brin",
                    "email": "sbrin@keygen.sh",
                    "password": "password2"
                  }
                },
                {
                  "type": "user",
                  "attributes": {
                    "firstName": "Sundar",
                    "lastName": "Pichai",
                    "email": "spichai@keygen.sh",
                    "password": "password3"
                  }
                }
              ]
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the account "google" should have 3 "admins"
    And the account "google" should have the following attributes:
      """
      { "protected": true }
      """

  Scenario: Anonymous creates an account with multiple admins and an invalid parameter
    When I send a POST request to "/accounts" with the following:
      """
      {
        "data": {
          "type": "accounts",
          "attributes": {
            "name": "Google",
            "slug": "google"
          },
          "relationships": {
            "plan": {
              "data": {
                "type": "plans",
                "id": "$plan[0]"
              }
            },
            "admins": {
              "data": [
                {
                  "type": "user",
                  "attributes": {
                    "firstName": "Larry",
                    "lastName": "Page",
                    "email": "lpage@keygen.sh",
                    "password": "password1"
                  }
                },
                {
                  "type": "user",
                  "attributes": {
                    "firstName": "Sergey",
                    "lastName": "Brin",
                    "email": "sbrin@keygen.sh",
                    "password": "password2"
                  }
                },
                {
                  "type": "user",
                  "attributes": {
                    "firstName": "Sundar",
                    "lastName": "Pichai",
                    "email": "spichai@keygen.sh",
                    "password": "password3"
                  }
                },
                "invalidParameter"
              ]
            }
          }
        }
      }
      """
    Then the response status should be "400"

  Scenario: Anonymous attempts to create an account with a reserved slug
    When I send a POST request to "/accounts" with the following:
      """
      {
        "data": {
          "type": "accounts",
          "attributes": {
            "name": "Forbidden",
            "slug": "actions"
          },
          "relationships": {
            "plan": {
              "data": {
                "type": "plans",
                "id": "$plan[0]"
              }
            },
            "admins": {
              "data": [
                {
                  "type": "user",
                  "attributes": {
                    "firstName": "Bad",
                    "lastName": "Actor",
                    "email": "hacker@keygen.sh",
                    "password": "h4X0r$!1"
                  }
                }
              ]
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
        "detail": "is reserved",
        "source": {
          "pointer": "/data/attributes/slug"
        }
      }
      """

  Scenario: Anonymous attempts to create an account without a plan
    When I send a POST request to "/accounts" with the following:
      """
      {
        "data": {
          "type": "accounts",
          "attributes": {
            "name": "Google",
            "slug": "google"
          },
          "relationships": {
            "admins": {
              "data": [
                {
                  "type": "user",
                  "attributes": {
                    "firstName": "Larry",
                    "lastName": "Page",
                    "email": "lpage@keygen.sh",
                    "password": "password"
                  }
                }
              ]
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
        "detail": "is missing",
        "source": {
          "pointer": "/data/relationships/plan"
        }
      }
      """

  Scenario: Anonymous attempts to create an account with invalid admin emails
    When I send a POST request to "/accounts" with the following:
      """
      {
        "data": {
          "type": "accounts",
          "attributes": {
            "name": "Google",
            "slug": "google"
          },
          "relationships": {
            "plan": {
              "data": {
                "type": "plans",
                "id": "$plan[0]"
              }
            },
            "admins": {
              "data": [
                {
                  "type": "user",
                  "attributes": {
                    "firstName": "Larry",
                    "lastName": "Page",
                    "email": "lpage^keygen.sh",
                    "password": "password1"
                  }
                },
                {
                  "type": "user",
                  "attributes": {
                    "firstName": "Sergey",
                    "lastName": "Brin",
                    "email": "sbrin*keygen.sh",
                    "password": "password2"
                  }
                }
              ]
            }
          }
        }
      }
      """
    Then the response status should be "422"
    And the response body should be an array of 2 errors
    And the first error should have the following properties:
      """
      {
        "title": "Unprocessable resource",
        "detail": "must be a valid email",
        "source": {
          "pointer": "/data/relationships/admins/data/0/attributes/email"
        }
      }
      """
    And the second error should have the following properties:
      """
      {
        "title": "Unprocessable resource",
        "detail": "must be a valid email",
        "source": {
          "pointer": "/data/relationships/admins/data/1/attributes/email"
        }
      }
      """

  Scenario: Anonymous attempts to create an account without any admin users
    When I send a POST request to "/accounts" with the following:
      """
      {
        "data": {
          "type": "accounts",
          "attributes": {
            "name": "Google",
            "slug": "google"
          },
          "relationships": {
            "plan": {
              "data": {
                "type": "plans",
                "id": "$plan[0]"
              }
            }
          }
        }
      }
      """
    Then the response status should be "400"
    And the response body should be an array of 1 errors

  Scenario: Anonymous creates an account without an admin role (role param should be a noop)
    When I send a POST request to "/accounts" with the following:
      """
      {
        "data": {
          "type": "accounts",
          "attributes": {
            "name": "Fathom",
            "slug": "fathom"
          },
          "relationships": {
            "plan": {
              "data": {
                "type": "plans",
                "id": "$plan[0]"
              }
            },
            "admins": {
              "data": [
                {
                  "type": "user",
                  "attributes": {
                    "email": "pjrvs@fathom.example",
                    "password": "correct horse battery staple",
                    "role": "user"
                  }
                }
              ]
            }
          }
        }
      }
      """
    Then the response status should be "400"
    And the response body should be an array of 1 errors
    And the first error should have the following properties:
      """
      {
        "title": "Bad request",
        "detail": "is invalid",
        "source": {
          "pointer": "/data/relationships/admins/data/0/attributes/role"
        }
      }
      """

  Scenario: Anonymous attempts to create a duplicate account with an invalid plan
    Given there exists an account "test1"
    When I send a POST request to "/accounts" with the following:
      """
      {
        "data": {
          "type": "accounts",
          "attributes": {
            "name": "Test1",
            "slug": "test1"
          },
          "relationships": {
            "plan": {
              "data": {
                "type": "plans",
                "id": "invalid"
              }
            },
            "admins": {
              "data": [
                {
                  "type": "user",
                  "attributes": {
                    "firstName": "Larry",
                    "lastName": "Page",
                    "email": "lpage@keygen.sh",
                    "password": "secret123"
                  }
                }
              ]
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
        "detail": "type mismatch (received string expected UUID string)",
        "source": {
          "pointer": "/data/relationships/plan/data/id"
        }
      }
      """

  Scenario: Anonymous attempts to create an account with invalid JSON (syntax)
    When I send a POST request to "/accounts" with the following:
      """
      {
        "data": {
          "type": "accounts",
          "attributes": {
            "name": "Google",
            "slug": "invalid-syntax =>",
          },
          "relationships": {
            "plan": {
              "data": {
                "type": "plans",
                "id": "$plan[0]"
              }
            },
            "admins": {
              "data": [
                {
                  "type": "user",
                  "attributes": {
                    "firstName": "Larry",
                    "lastName": "Page",
                    "email": "lpage@keygen.sh",
                    "password": "secret123"
                  }
                }
              ]
            }
          }
        }
      }
      """
    Then the response status should be "400"
    And the response body should be an array of 1 errors
    And the first error should have the following properties:
      """
      {
        "title": "Bad request",
        "detail": "The request could not be completed because it contains invalid JSON (check formatting/encoding)",
        "code": "JSON_INVALID"
      }
      """

  # Scenario: Anonymous attempts to create an account with invalid JSON (escaping)
  #   When I send a POST request to "/accounts" with the following:
  #     """
  #     {
  #       "data": {
  #         "type": "accounts",
  #         "attributes": {
  #           "name": "Google",
  #           "slug": "Invalid_\$lug/Is;here"
  #         },
  #         "relationships": {
  #           "plan": {
  #             "data": {
  #               "type": "plans",
  #               "id": "$plan[0]"
  #             }
  #           },
  #           "admins": {
  #             "data": [
  #               {
  #                 "type": "user",
  #                 "attributes": {
  #                   "firstName": "Larry",
  #                   "lastName": "Page",
  #                   "email": "lpage@keygen.sh",
  #                   "password": "secret123"
  #                 }
  #               }
  #             ]
  #           }
  #         }
  #       }
  #     }
  #     """
  #   Then the response status should be "400"
  #   And the response body should be an array of 1 errors
  #   And the first error should have the following properties:
  #     """
  #     {
  #       "title": "Bad request",
  #       "detail": "The request could not be completed because it contains an invalid byte sequence (check encoding)",
  #       "code": "ENCODING_INVALID"
  #     }
  #     """

  Scenario: Anonymous attempts to create an account with an invalid slug
    When I send a POST request to "/accounts" with the following:
      """
      {
        "data": {
          "type": "accounts",
          "attributes": {
            "name": "Google",
            "slug": "@Invalid_slug/Is;here"
          },
          "relationships": {
            "plan": {
              "data": {
                "type": "plans",
                "id": "$plan[0]"
              }
            },
            "admins": {
              "data": [
                {
                  "type": "user",
                  "attributes": {
                    "firstName": "Larry",
                    "lastName": "Page",
                    "email": "lpage@keygen.sh",
                    "password": "secret123"
                  }
                }
              ]
            }
          }
        }
      }
      """
    Then the response status should be "422"
    And the response body should be an array of 1 errors
    And the first error should have the following properties:
      """
      {
        "title": "Unprocessable resource",
        "detail": "can only contain lowercase letters, numbers and dashes (but cannot start with dash)",
        "source": {
          "pointer": "/data/attributes/slug"
        }
      }
      """

  Scenario: Anonymous attempts to create an account with an invalid admin email
    When I send a POST request to "/accounts" with the following:
      """
      {
        "data": {
          "type": "accounts",
          "attributes": {
            "name": "Google",
            "slug": "google"
          },
          "relationships": {
            "plan": {
              "data": {
                "type": "plans",
                "id": "$plan[0]"
              }
            },
            "admins": {
              "data": [
                {
                  "type": "user",
                  "attributes": {
                    "firstName": "Larry",
                    "lastName": "Page",
                    "email": "missingatsymbol.keygen.sh",
                    "password": "secret123"
                  }
                }
              ]
            }
          }
        }
      }
      """
    Then the response status should be "422"
    And the response body should be an array of 1 errors
    And the first error should have the following properties:
      """
      {
        "title": "Unprocessable resource",
        "detail": "must be a valid email",
        "source": {
          "pointer": "/data/relationships/admins/data/0/attributes/email"
        }
      }
      """

  # Scenario: Anonymous sends an invalid HTTP method
  #   When I send a INVALID request to "/accounts" with the following:
  #     """
  #     {
  #       "data": {}
  #     }
  #     """
  #   Then the response status should be "400"
  #   And the response body should be an array of 1 errors
  #   And the first error should have the following properties:
  #     """
  #     {
  #       "title": "Unprocessable resource",
  #       "detail": "must be a valid email",
  #       "source": {
  #         "pointer": "/data/relationships/admins/data/0/attributes/email"
  #       }
  #     }
  #     """

  # Scenario: Anonymous attempts to perform an account takeover using unicode truncation (slug collision)
  #   Given the following "accounts" exist:
  #     | id                                   | name | slug |
  #     | ace6b050-6dc0-4cb5-85e9-ad87f629255f | Test | test |
  #   When I send a POST request to "/accounts" with the following:
  #     """
  #     {
  #       "data": {
  #         "type": "accounts",
  #         "attributes": {
  #           "name": "Test",
  #           "slug": "test\ud888"
  #         },
  #         "relationships": {
  #           "plan": {
  #             "data": {
  #               "type": "plans",
  #               "id": "$plan[0]"
  #             }
  #           },
  #           "admins": {
  #             "data": [
  #               {
  #                 "type": "user",
  #                 "attributes": {
  #                   "email": "test@hacker.example",
  #                   "password": "secret123"
  #                 }
  #               }
  #             ]
  #           }
  #         }
  #       }
  #     }
  #     """
  #   Then the response status should be "400"
  #   And the response body should be an array of 1 error
  #   And the first error should have the following properties:
  #     """
  #     {
  #       "title": "Bad request",
  #       "detail": "The request could not be completed because it contains an invalid byte sequence (check encoding)",
  #       "code": "ENCODING_INVALID"
  #     }
  #     """
  #   And sidekiq should have 0 "webhook" jobs
  #   And sidekiq should have 0 "metric" jobs
  #   And sidekiq should have 0 "request-log" jobs

  # Scenario: Anonymous attempts to perform an account takeover using unicode truncation (ID collision)
  #   Given the following "accounts" exist:
  #     | id                                   | name | slug |
  #     | ace6b050-6dc0-4cb5-85e9-ad87f629255f | Test | test |
  #   When I send a POST request to "/accounts" with the following:
  #     """
  #     {
  #       "data": {
  #         "type": "accounts",
  #         "attributes": {
  #           "name": "Test",
  #           "slug": "ace6b050-6dc0-4cb5-85e9-ad87f629255f\ud888"
  #         },
  #         "relationships": {
  #           "plan": {
  #             "data": {
  #               "type": "plans",
  #               "id": "$plan[0]"
  #             }
  #           },
  #           "admins": {
  #             "data": [
  #               {
  #                 "type": "user",
  #                 "attributes": {
  #                   "email": "test@hacker.example",
  #                   "password": "secret123"
  #                 }
  #               }
  #             ]
  #           }
  #         }
  #       }
  #     }
  #     """
  #   Then the response status should be "400"
  #   And the response body should be an array of 1 error
  #   And the first error should have the following properties:
  #     """
  #     {
  #       "title": "Bad request",
  #       "detail": "The request could not be completed because it contains an invalid byte sequence (check encoding)",
  #       "code": "ENCODING_INVALID"
  #     }
  #     """
  #   And sidekiq should have 0 "webhook" jobs
  #   And sidekiq should have 0 "metric" jobs
  #   And sidekiq should have 0 "request-log" jobs
