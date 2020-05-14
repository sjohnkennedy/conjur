Feature: Users can login with LDAP credentials from an authorized LDAP server

  Background:
    Given a policy:
    """
    - !user alice
    - !user bob

    - !policy
      id: conjur/authn-ldap/test
      body:
      - !webservice

      - !group clients

      - !permit
        role: !group clients
        privilege: [ read, authenticate ]
        resource: !webservice

    - !grant
      role: !group conjur/authn-ldap/test/clients
      member: !user alice

    - !policy
      id: conjur/authn-ldap/secure
      body:
      - !host
      - !webservice
        owner: !host
        annotations:
          ldap-authn/base_dn: dc=conjur,dc=net
          ldap-authn/bind_dn: cn=admin,dc=conjur,dc=net
          ldap-authn/connect_type: tls
          ldap-authn/host: ldap-server
          ldap-authn/port: 389
          ldap-authn/filter_template: (uid=%s)

      - !group clients

      - !permit
        role: !group clients
        privilege: [ read, authenticate ]
        resource: !webservice

      - !variable
        id: bind-password
        owner: !host

      - !variable
        id: tls-ca-cert
        owner: !host

    - !grant
      role: !group conjur/authn-ldap/secure/clients
      member: !user alice
      
    """
    And I store the LDAP bind password in "conjur/authn-ldap/secure/bind-password"
    And I store the LDAP CA certificate in "conjur/authn-ldap/secure/tls-ca-cert"

  Scenario: An LDAP user authorized in Conjur can login with a good password
    Given I save my place in the log file
    When I login via LDAP as authorized Conjur user "alice"
    And I authenticate via LDAP as authorized Conjur user "alice" using key
    Then user "alice" has been authorized by Conjur
    And The following appears in the log after my savepoint:
    """
    cucumber:user:alice successfully authenticated with authenticator authn-ldap service cucumber:webservice:conjur/authn-ldap/test
    """

  Scenario: An LDAP user authorized in Conjur can login with a good password using TLS
    When I login via secure LDAP as authorized Conjur user "alice"
    And I authenticate via secure LDAP as authorized Conjur user "alice" using key
    Then user "alice" has been authorized by Conjur

  Scenario: An LDAP user authorized in Conjur can authenticate with a good password
    When I authenticate via LDAP as authorized Conjur user "alice"
    Then user "alice" has been authorized by Conjur

  Scenario: An LDAP user authorized in Conjur can't login with a bad password
    When my LDAP password is wrong for authorized user "alice"
    Then it is unauthorized

  Scenario: 'admin' cannot use LDAP authentication
    When I login via LDAP as authorized Conjur user "admin"
    Then it is unauthorized

  Scenario: An valid LDAP user who's not in Conjur can't login
    When I login via LDAP as non-existent Conjur user "bob"
    Then it is forbidden

  Scenario: An empty password may never be used to authenticate
    When my LDAP password for authorized Conjur user "alice" is empty
    Then it is unauthorized

    #TODO Add an "is denied" for alice added to conjur but not entitled
  Scenario: An LDAP user in Conjur but without authorization can't login
    Given a policy:
    """
    - !user alice

    - !policy
      id: conjur/authn-ldap/test
      body:
      - !webservice

      - !group clients

      - !permit
        role: !group clients
        privilege: [ read, authenticate ]
        resource: !webservice
    """
    When I login via LDAP as authorized Conjur user "alice"
    Then it is forbidden

  # This test runs a failing authentication request that is already
  # tested in another scenario (An LDAP user authorized in Conjur can't login with a bad password).
  # We run it again here to verify that we write a message to the audit log
  Scenario: Authentication failure is written to the audit log
    Given I save my place in the audit log file
    When my LDAP password is wrong for authorized user "alice"
    Then it is unauthorized
    And The following appears in the audit log after my savepoint:
    """
    cucumber:user:alice failed to login with authenticator authn-ldap service cucumber:webservice:conjur/authn-ldap/test
    """
