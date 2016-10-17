Feature: Policy loading error messages

  @logged-in-admin
  Scenario: A policy which references a non-existing resource reports the error.

    The error message provides the id of the record that was not found.

    When I POST "/policies/:account/policy/bootstrap" with body:
    """
    - !variable password

    - !permit
      role: !user bob
      privilege: [ execute ]
      resource: !variable password
    """
    Then it's not found
    And the JSON response should be:
    """
    {
      "error": {
        "code": "not_found",
        "message": "User 'bob' not found in account 'cucumber'",
        "target": "id",
        "innererror": {
          "code": "not_found",
          "id": "cucumber:user:bob"
        }
      }
    }
    """


  @logged-in-admin
  Scenario: A policy with a blank resource id reports the error.

    When I POST "/policies/:account/policy/bootstrap" with body:
    """
    - !user bob

    - !permit
      role: !user bob
      privilege: [ execute ]
      resource:
    """
    Then it's unprocessable
    And the JSON response should be:
    """
    {
      "error": {
        "code": "validation_failed",
        "message": "Resource has a blank id",
        "details": [
          {
            "code": "validation_failed",
            "target": "policy_text",
            "message": "Resource has a blank id"
          }
        ]
      }
    }
    """