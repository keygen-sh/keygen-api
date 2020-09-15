@api/v1
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
                    "password": "goog"
                  }
                }
              ]
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the JSON response should be an "account" with the name "Google"
    And the JSON response should be an "account" with the following meta:
      """
      { "publicKey": "$~accounts[0].public_key" }
      """
    And the account should receive a "welcome" email
    And the account "google" should have 1 "admin"
    And sidekiq should have 0 "request-log" jobs

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
    And the JSON response should be an array of 1 error
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
    And the JSON response should be an array of 1 error
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
    And the JSON response should be an array of 1 error
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
                    "password": "goog"
                  }
                }
              ]
            }
          }
        }
      }
      """
    Then the response status should be "201"
    And the JSON response should be an "account" with the name "Google"
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
                    "password": "goog"
                  }
                },
                {
                  "type": "user",
                  "attributes": {
                    "firstName": "Sergey",
                    "lastName": "Brin",
                    "email": "sbrin@keygen.sh",
                    "password": "goog"
                  }
                },
                {
                  "type": "user",
                  "attributes": {
                    "firstName": "Sundar",
                    "lastName": "Pichai",
                    "email": "spichai@keygen.sh",
                    "password": "goog"
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
                    "password": "goog"
                  }
                },
                {
                  "type": "user",
                  "attributes": {
                    "firstName": "Sergey",
                    "lastName": "Brin",
                    "email": "sbrin@keygen.sh",
                    "password": "goog"
                  }
                },
                {
                  "type": "user",
                  "attributes": {
                    "firstName": "Sundar",
                    "lastName": "Pichai",
                    "email": "spichai@keygen.sh",
                    "password": "goog"
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
                    "password": "h4X0r$"
                  }
                }
              ]
            }
          }
        }
      }
      """
    Then the response status should be "422"
    And the JSON response should be an array of 1 error
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
                    "password": "goog"
                  }
                }
              ]
            }
          }
        }
      }
      """
    Then the response status should be "400"
    And the JSON response should be an array of 1 error
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
                    "password": "goog"
                  }
                },
                {
                  "type": "user",
                  "attributes": {
                    "firstName": "Sergey",
                    "lastName": "Brin",
                    "email": "sbrin*keygen.sh",
                    "password": "goog"
                  }
                }
              ]
            }
          }
        }
      }
      """
    Then the response status should be "422"
    And the JSON response should be an array of 2 errors
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
    And the JSON response should be an array of 1 errors

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
                    "password": "goog"
                  }
                }
              ]
            }
          }
        }
      }
      """
    Then the response status should be "422"
    And the JSON response should be an array of 2 errors

  Scenario: Anonymous attempts to create an account with invalid JSON (escaping)
    When I send a POST request to "/accounts" with the following:
      """
      {
        "data": {
          "type": "accounts",
          "attributes": {
            "name": "Google",
            "slug": "Invalid_\$lug/Is;here"
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
                    "password": "goog"
                  }
                }
              ]
            }
          }
        }
      }
      """
    Then the response status should be "400"
    And the JSON response should be an array of 1 errors
    And the first error should have the following properties:
      """
      {
        "title": "Bad request",
        "detail": "The request could not be completed because it contains invalid JSON (check encoding)",
        "code": "JSON_INVALID"
      }
      """

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
                    "password": "goog"
                  }
                }
              ]
            }
          }
        }
      }
      """
    Then the response status should be "422"
    And the JSON response should be an array of 1 errors
    And the first error should have the following properties:
      """
      {
        "title": "Unprocessable resource",
        "detail": "can only contain lowercase letters, numbers and dashes",
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
                    "password": "goog"
                  }
                }
              ]
            }
          }
        }
      }
      """
    Then the response status should be "422"
    And the JSON response should be an array of 1 errors
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
  #   And the JSON response should be an array of 1 errors
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
