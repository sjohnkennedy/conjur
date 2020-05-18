Feature: Azure Authenticator - Bad authenticator configuration leads to an error

  In this feature we define an Azure Authenticator with a configuration
  mistake. Each test will verify that we fail the authentication in such a case
  and log the relevant error for the user to re-configure the authenticator
  properly

  Scenario: provider-uri variable missing in policy is denied
    Given a policy:
    """
    - !policy
      id: conjur/authn-azure/prod
      body:
      - !webservice

      - !group apps

      - !permit
        role: !group apps
        privilege: [ read, authenticate ]
        resource: !webservice
    """
    And I am the super-user
    And I have host "test-app"
    And I set Azure annotations to host "test-app"
    And I grant group "conjur/authn-azure/prod/apps" to host "test-app"
    And I fetch a non-assigned-identity Azure access token from inside machine
    And I save my place in the log file
    When I authenticate via Azure with token as host "test-app"
    Then it is unauthorized
    And The following appears in the log after my savepoint:
    """
    Errors::Conjur::RequiredResourceMissing
    """

  # TODO: add this test when issue #1085 is done
  @skip
  Scenario: provider-uri variable without value is denied
    Given a policy:
    """
    - !policy
      id: conjur/authn-azure/prod
      body:
      - !webservice

      - !variable
        id: provider-uri

      - !group apps

      - !permit
        role: !group apps
        privilege: [ read, authenticate ]
        resource: !webservice
    """
    And I am the super-user
    And I have host "test-app"
    And I set Azure annotations to host "test-app"
    And I grant group "conjur/authn-azure/prod/apps" to host "test-app"
    And I fetch a non-assigned-identity Azure access token from inside machine
    And I save my place in the log file
    When I authenticate via Azure with token as host "test-app"
    Then it is unauthorized
    And The following appears in the log after my savepoint:
    """
    Errors::Conjur::RequiredSecretMissing
    """

  Scenario: webservice missing in policy is denied
    Given a policy:
    """
    - !policy
      id: conjur/authn-azure/prod
      body:

      - !variable
        id: provider-uri

      - !group apps
    """
    And I am the super-user
    And I have host "test-app"
    And I set Azure annotations to host "test-app"
    And I grant group "conjur/authn-azure/prod/apps" to host "test-app"
    And I successfully set Azure provider-uri variable with the correct values
    And I fetch a non-assigned-identity Azure access token from inside machine
    And I save my place in the log file
    When I authenticate via Azure with token as host "test-app"
    Then it is unauthorized
    And The following appears in the log after my savepoint:
    """
    Errors::Authentication::Security::WebserviceNotFound
    """

  Scenario: Webservice with read and no authenticate permission in policy is denied
    Given a policy:
    """
    - !policy
      id: conjur/authn-azure/prod
      body:
        - !webservice

        - !variable
          id: provider-uri

        - !group apps

        - !permit
          role: !group apps
          privilege: [ read ]
          resource: !webservice
    """
    And I am the super-user
    And I have host "test-app"
    And I set Azure annotations to host "test-app"
    And I grant group "conjur/authn-azure/prod/apps" to host "test-app"
    And I successfully set Azure provider-uri variable with the correct values
    And I fetch a non-assigned-identity Azure access token from inside machine
    And I save my place in the log file
    When I authenticate via Azure with token as host "test-app"
    Then it is forbidden
    And The following appears in the log after my savepoint:
    """
    Errors::Authentication::Security::RoleNotAuthorizedOnResource
    """

  Scenario: Bad Gateway is raised in case of an invalid ID Provider hostname
    Given a policy:
    """
    - !policy
      id: conjur/authn-azure/prod
      body:
      - !webservice

      - !variable
        id: provider-uri

      - !group apps

      - !permit
        role: !group apps
        privilege: [ read, authenticate ]
        resource: !webservice
    """
    And I am the super-user
    And I add the secret value "http://127.0.0.1.com/" to the resource "cucumber:variable:conjur/authn-azure/prod/provider-uri"
    And I have host "test-app"
    And I set Azure annotations to host "test-app"
    And I grant group "conjur/authn-azure/prod/apps" to host "test-app"
    And I fetch a non-assigned-identity Azure access token from inside machine
    And I save my place in the log file
    When I authenticate via Azure with token as host "test-app"
    Then it is bad gateway
    And The following appears in the log after my savepoint:
    """
    Errors::Authentication::OAuth::ProviderDiscoveryFailed
    """
