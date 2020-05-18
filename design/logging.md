# Solution Design - Redefine Conjur logs

## Table of Contents
- [Solution Design - Redefine Conjur logs](#solution-design---redefine-conjur-logs)
  * [Issue description](#issue-description)
  * [Solution](#solution)
    + [Backwards compatibility](#backwards-compatibility)
    + [Affected Components](#affected-components)
  * [Security](#security)
  * [Test Plan](#test-plan)
  * [Documentation](#documentation)
  * [Version update](#version-update)
  * [Breaking](#breaking)

## Issue description

As a Conjur operator, I want to read the logs, so that I can easily understand the application flow.

Currently, when we set the log level to INFO (which is the default value),
we do not get any log messages regarding what happened in the application flow. 
However, if we change the log level to DEBUG we get too many log messages as we 
log the DB messages at that level, alongside our own debug level logs. 

For example, let's look at a log sample for the use-case where a user sends an 
`authn-oidc` request with a username that is not defined in Conjur. If the log level
is set to INFO (as the default value is), then the log will look like this:
```
 INFO 2020/05/18 09:49:20 +0000 [pid=411] [origin=127.0.0.1] [request_id=0487ea6a-a974-481a-8b7f-d7d62e96aec6] [tid=421] Started POST "/authn-oidc/keycloak/cucumber/authenticate" for 127.0.0.1 at 2020-05-18 09:49:20 +0000
 INFO 2020/05/18 09:49:21 +0000 [pid=411] [origin=127.0.0.1] [request_id=0487ea6a-a974-481a-8b7f-d7d62e96aec6] [tid=421] Processing by AuthenticateController#authenticate_oidc as */*
 INFO 2020/05/18 09:49:21 +0000 [pid=411] [origin=127.0.0.1] [request_id=0487ea6a-a974-481a-8b7f-d7d62e96aec6] [tid=421]   Parameters: {"service_id"=>"keycloak", "account"=>"cucumber"}
 INFO 2020/05/18 09:49:21 +0000 [pid=411] [origin=127.0.0.1] [request_id=0487ea6a-a974-481a-8b7f-d7d62e96aec6] [tid=421] Completed 401 Unauthorized in 94ms
```

As can be seen, there is not enough data to understand why the request failed.
If the log level is set to DEBUG, then the log will look like this:
```
INFO 2020/05/18 09:45:41 +0000 [pid=298] [origin=127.0.0.1] [request_id=b7390d52-73a1-41ff-add3-9f4e37395e55] [tid=305] Started POST "/authn-oidc/keycloak/cucumber/authenticate" for 127.0.0.1 at 2020-05-18 09:45:41 +0000
 INFO 2020/05/18 09:45:41 +0000 [pid=298] [origin=127.0.0.1] [request_id=b7390d52-73a1-41ff-add3-9f4e37395e55] [tid=305] Processing by AuthenticateController#authenticate_oidc as */*
 INFO 2020/05/18 09:45:41 +0000 [pid=298] [origin=127.0.0.1] [request_id=b7390d52-73a1-41ff-add3-9f4e37395e55] [tid=305]   Parameters: {"service_id"=>"keycloak", "account"=>"cucumber"}
DEBUG 2020/05/18 09:45:41 +0000 [pid=298] [origin=127.0.0.1] [request_id=b7390d52-73a1-41ff-add3-9f4e37395e55] [tid=305]   Sequel::Postgres::Database (0.5ms)  BEGIN
DEBUG 2020/05/18 09:45:41 +0000 [pid=298] [origin=127.0.0.1] [request_id=b7390d52-73a1-41ff-add3-9f4e37395e55] [tid=305]   Sequel::Postgres::Database (0.9ms)  SELECT * FROM "roles" WHERE "role_id" = 'cucumber:user:admin'
DEBUG 2020/05/18 09:45:41 +0000 [pid=298] [origin=127.0.0.1] [request_id=b7390d52-73a1-41ff-add3-9f4e37395e55] [tid=305]   Sequel::Postgres::Database (0.7ms)  SELECT * FROM "resources" WHERE "resource_id" = 'cucumber:variable:conjur/authn-oidc/keycloak/provider-uri'
DEBUG 2020/05/18 09:45:41 +0000 [pid=298] [origin=127.0.0.1] [request_id=b7390d52-73a1-41ff-add3-9f4e37395e55] [tid=305]   Sequel::Postgres::Database (0.8ms)  SELECT * FROM "resources" WHERE "resource_id" = 'cucumber:variable:conjur/authn-oidc/keycloak/id-token-user-property'
DEBUG 2020/05/18 09:45:41 +0000 [pid=298] [origin=127.0.0.1] [request_id=b7390d52-73a1-41ff-add3-9f4e37395e55] [tid=305]   Sequel::Postgres::Database (1.6ms)  SELECT * FROM "secrets" WHERE ("secrets"."resource_id" = 'cucumber:variable:conjur/authn-oidc/keycloak/provider-uri') ORDER BY "version" DESC LIMIT 1
DEBUG 2020/05/18 09:45:41 +0000 [pid=298] [origin=127.0.0.1] [request_id=b7390d52-73a1-41ff-add3-9f4e37395e55] [tid=305]   Sequel::Postgres::Database (0.7ms)  SELECT * FROM "secrets" WHERE ("secrets"."resource_id" = 'cucumber:variable:conjur/authn-oidc/keycloak/id-token-user-property') ORDER BY "version" DESC LIMIT 1
DEBUG 2020/05/18 09:45:41 +0000 [pid=298] [origin=127.0.0.1] [request_id=b7390d52-73a1-41ff-add3-9f4e37395e55] [tid=305] CONJ00023D Concurrency limited cache concurrent requests updated to '1'
DEBUG 2020/05/18 09:45:41 +0000 [pid=298] [origin=127.0.0.1] [request_id=b7390d52-73a1-41ff-add3-9f4e37395e55] [tid=305] CONJ00007D Working with Identity Provider https://keycloak:8443/auth/realms/master
DEBUG 2020/05/18 09:45:41 +0000 [pid=298] [origin=127.0.0.1] [request_id=b7390d52-73a1-41ff-add3-9f4e37395e55] [tid=305] CONJ00008D Identity Provider discovery succeeded
DEBUG 2020/05/18 09:45:41 +0000 [pid=298] [origin=127.0.0.1] [request_id=b7390d52-73a1-41ff-add3-9f4e37395e55] [tid=305] CONJ00009D Fetched Identity Provider keys from provider successfully
DEBUG 2020/05/18 09:45:41 +0000 [pid=298] [origin=127.0.0.1] [request_id=b7390d52-73a1-41ff-add3-9f4e37395e55] [tid=305] CONJ00016D Rate limited cache updated successfully
DEBUG 2020/05/18 09:45:41 +0000 [pid=298] [origin=127.0.0.1] [request_id=b7390d52-73a1-41ff-add3-9f4e37395e55] [tid=305] CONJ00021D Concurrency limited cache updated successfully
DEBUG 2020/05/18 09:45:41 +0000 [pid=298] [origin=127.0.0.1] [request_id=b7390d52-73a1-41ff-add3-9f4e37395e55] [tid=305] CONJ00023D Concurrency limited cache concurrent requests updated to '0'
DEBUG 2020/05/18 09:45:41 +0000 [pid=298] [origin=127.0.0.1] [request_id=b7390d52-73a1-41ff-add3-9f4e37395e55] [tid=305] CONJ00017D Fetched Identity Provider keys from cache successfully
DEBUG 2020/05/18 09:45:41 +0000 [pid=298] [origin=127.0.0.1] [request_id=b7390d52-73a1-41ff-add3-9f4e37395e55] [tid=305] CONJ00005D Token decoded successfully
DEBUG 2020/05/18 09:45:41 +0000 [pid=298] [origin=127.0.0.1] [request_id=b7390d52-73a1-41ff-add3-9f4e37395e55] [tid=305] CONJ00004D Extracted username 'not_in_conjur' from ID token field 'preferred_username'
DEBUG 2020/05/18 09:45:41 +0000 [pid=298] [origin=127.0.0.1] [request_id=b7390d52-73a1-41ff-add3-9f4e37395e55] [tid=305]   Sequel::Postgres::Database (0.7ms)  SELECT * FROM "roles" WHERE "role_id" = 'cucumber:user:admin'
DEBUG 2020/05/18 09:45:41 +0000 [pid=298] [origin=127.0.0.1] [request_id=b7390d52-73a1-41ff-add3-9f4e37395e55] [tid=305]   Sequel::Postgres::Database (1.4ms)  SELECT * FROM "roles" WHERE "role_id" = 'cucumber:user:admin'
DEBUG 2020/05/18 09:45:41 +0000 [pid=298] [origin=127.0.0.1] [request_id=b7390d52-73a1-41ff-add3-9f4e37395e55] [tid=305]   Sequel::Postgres::Database (1.5ms)  SELECT * FROM "roles" WHERE "role_id" = 'cucumber:user:admin'
DEBUG 2020/05/18 09:45:41 +0000 [pid=298] [origin=127.0.0.1] [request_id=b7390d52-73a1-41ff-add3-9f4e37395e55] [tid=305]   Sequel::Postgres::Database (0.7ms)  SELECT * FROM "resources" WHERE "resource_id" = 'cucumber:webservice:conjur/authn-oidc/keycloak'
DEBUG 2020/05/18 09:45:41 +0000 [pid=298] [origin=127.0.0.1] [request_id=b7390d52-73a1-41ff-add3-9f4e37395e55] [tid=305]   Sequel::Postgres::Database (0.6ms)  SELECT * FROM "roles" WHERE "role_id" = 'cucumber:user:not_in_conjur'
DEBUG 2020/05/18 09:45:41 +0000 [pid=298] [origin=127.0.0.1] [request_id=b7390d52-73a1-41ff-add3-9f4e37395e55] [tid=305]   Sequel::Postgres::Database (0.6ms)  SELECT * FROM "roles" WHERE ("role_id" = 'cucumber:user:not_in_conjur') LIMIT 1
DEBUG 2020/05/18 09:45:41 +0000 [pid=298] [origin=127.0.0.1] [request_id=b7390d52-73a1-41ff-add3-9f4e37395e55] [tid=305] Authentication Error: #<Errors::Authentication::Security::RoleNotFound: CONJ00007E 'not_in_conjur' not found>
DEBUG 2020/05/18 09:45:41 +0000 [pid=298] [origin=127.0.0.1] [request_id=b7390d52-73a1-41ff-add3-9f4e37395e55] [tid=305] /src/conjur-server/app/domain/authentication/validate_webservice_access.rb:59:in `validate_user_is_defined'
DEBUG 2020/05/18 09:45:41 +0000 [pid=298] [origin=127.0.0.1] [request_id=b7390d52-73a1-41ff-add3-9f4e37395e55] [tid=305] /src/conjur-server/app/domain/authentication/validate_webservice_access.rb:34:in `call'
DEBUG 2020/05/18 09:45:41 +0000 [pid=298] [origin=127.0.0.1] [request_id=b7390d52-73a1-41ff-add3-9f4e37395e55] [tid=305] (eval):7:in `call'
DEBUG 2020/05/18 09:45:41 +0000 [pid=298] [origin=127.0.0.1] [request_id=b7390d52-73a1-41ff-add3-9f4e37395e55] [tid=305] /src/conjur-server/app/domain/authentication/validate_security.rb:47:in `validate_user_has_access_to_webservice'
DEBUG 2020/05/18 09:45:41 +0000 [pid=298] [origin=127.0.0.1] [request_id=b7390d52-73a1-41ff-add3-9f4e37395e55] [tid=305] /src/conjur-server/app/domain/authentication/validate_security.rb:28:in `call'
DEBUG 2020/05/18 09:45:41 +0000 [pid=298] [origin=127.0.0.1] [request_id=b7390d52-73a1-41ff-add3-9f4e37395e55] [tid=305] (eval):7:in `call'
DEBUG 2020/05/18 09:45:41 +0000 [pid=298] [origin=127.0.0.1] [request_id=b7390d52-73a1-41ff-add3-9f4e37395e55] [tid=305] /src/conjur-server/app/domain/authentication/authn_oidc/authenticate.rb:118:in `validate_security'
DEBUG 2020/05/18 09:45:41 +0000 [pid=298] [origin=127.0.0.1] [request_id=b7390d52-73a1-41ff-add3-9f4e37395e55] [tid=305] /src/conjur-server/app/domain/authentication/authn_oidc/authenticate.rb:41:in `call'
DEBUG 2020/05/18 09:45:41 +0000 [pid=298] [origin=127.0.0.1] [request_id=b7390d52-73a1-41ff-add3-9f4e37395e55] [tid=305] (eval):7:in `call'
DEBUG 2020/05/18 09:45:41 +0000 [pid=298] [origin=127.0.0.1] [request_id=b7390d52-73a1-41ff-add3-9f4e37395e55] [tid=305] /src/conjur-server/app/controllers/authenticate_controller.rb:90:in `authenticate_oidc'
DEBUG 2020/05/18 09:45:41 +0000 [pid=298] [origin=127.0.0.1] [request_id=b7390d52-73a1-41ff-add3-9f4e37395e55] [tid=305] /var/lib/gems/2.5.0/gems/actionpack-5.2.4.2/lib/action_controller/metal/basic_implicit_render.rb:6:in `send_action'
DEBUG 2020/05/18 09:45:41 +0000 [pid=298] [origin=127.0.0.1] [request_id=b7390d52-73a1-41ff-add3-9f4e37395e55] [tid=305] /var/lib/gems/2.5.0/gems/actionpack-5.2.4.2/lib/abstract_controller/base.rb:194:in `process_action'
DEBUG 2020/05/18 09:45:41 +0000 [pid=298] [origin=127.0.0.1] [request_id=b7390d52-73a1-41ff-add3-9f4e37395e55] [tid=305] /var/lib/gems/2.5.0/gems/actionpack-5.2.4.2/lib/action_controller/metal/rendering.rb:30:in `process_action'
DEBUG 2020/05/18 09:45:41 +0000 [pid=298] [origin=127.0.0.1] [request_id=b7390d52-73a1-41ff-add3-9f4e37395e55] [tid=305] /var/lib/gems/2.5.0/gems/actionpack-5.2.4.2/lib/abstract_controller/callbacks.rb:42:in `block in process_action'
DEBUG 2020/05/18 09:45:41 +0000 [pid=298] [origin=127.0.0.1] [request_id=b7390d52-73a1-41ff-add3-9f4e37395e55] [tid=305] /var/lib/gems/2.5.0/gems/activesupport-5.2.4.2/lib/active_support/callbacks.rb:109:in `block in run_callbacks'
DEBUG 2020/05/18 09:45:41 +0000 [pid=298] [origin=127.0.0.1] [request_id=b7390d52-73a1-41ff-add3-9f4e37395e55] [tid=305] /src/conjur-server/app/controllers/application_controller.rb:74:in `block in run_with_transaction'
DEBUG 2020/05/18 09:45:41 +0000 [pid=298] [origin=127.0.0.1] [request_id=b7390d52-73a1-41ff-add3-9f4e37395e55] [tid=305] /var/lib/gems/2.5.0/gems/sequel-4.49.0/lib/sequel/database/transactions.rb:224:in `_transaction'
DEBUG 2020/05/18 09:45:41 +0000 [pid=298] [origin=127.0.0.1] [request_id=b7390d52-73a1-41ff-add3-9f4e37395e55] [tid=305] /var/lib/gems/2.5.0/gems/sequel-4.49.0/lib/sequel/database/transactions.rb:199:in `block in transaction'
DEBUG 2020/05/18 09:45:41 +0000 [pid=298] [origin=127.0.0.1] [request_id=b7390d52-73a1-41ff-add3-9f4e37395e55] [tid=305] /var/lib/gems/2.5.0/gems/sequel-4.49.0/lib/sequel/database/connecting.rb:301:in `block in synchronize'
DEBUG 2020/05/18 09:45:41 +0000 [pid=298] [origin=127.0.0.1] [request_id=b7390d52-73a1-41ff-add3-9f4e37395e55] [tid=305] /var/lib/gems/2.5.0/gems/sequel-4.49.0/lib/sequel/connection_pool/threaded.rb:107:in `hold'
DEBUG 2020/05/18 09:45:41 +0000 [pid=298] [origin=127.0.0.1] [request_id=b7390d52-73a1-41ff-add3-9f4e37395e55] [tid=305] /var/lib/gems/2.5.0/gems/sequel-4.49.0/lib/sequel/database/connecting.rb:301:in `synchronize'
DEBUG 2020/05/18 09:45:41 +0000 [pid=298] [origin=127.0.0.1] [request_id=b7390d52-73a1-41ff-add3-9f4e37395e55] [tid=305] /var/lib/gems/2.5.0/gems/sequel-4.49.0/lib/sequel/database/transactions.rb:165:in `transaction'
DEBUG 2020/05/18 09:45:41 +0000 [pid=298] [origin=127.0.0.1] [request_id=b7390d52-73a1-41ff-add3-9f4e37395e55] [tid=305] /src/conjur-server/app/controllers/application_controller.rb:73:in `run_with_transaction'
DEBUG 2020/05/18 09:45:41 +0000 [pid=298] [origin=127.0.0.1] [request_id=b7390d52-73a1-41ff-add3-9f4e37395e55] [tid=305] /var/lib/gems/2.5.0/gems/activesupport-5.2.4.2/lib/active_support/callbacks.rb:118:in `block in run_callbacks'
DEBUG 2020/05/18 09:45:41 +0000 [pid=298] [origin=127.0.0.1] [request_id=b7390d52-73a1-41ff-add3-9f4e37395e55] [tid=305] /var/lib/gems/2.5.0/gems/activesupport-5.2.4.2/lib/active_support/callbacks.rb:136:in `run_callbacks'
DEBUG 2020/05/18 09:45:41 +0000 [pid=298] [origin=127.0.0.1] [request_id=b7390d52-73a1-41ff-add3-9f4e37395e55] [tid=305] /var/lib/gems/2.5.0/gems/actionpack-5.2.4.2/lib/abstract_controller/callbacks.rb:41:in `process_action'
DEBUG 2020/05/18 09:45:41 +0000 [pid=298] [origin=127.0.0.1] [request_id=b7390d52-73a1-41ff-add3-9f4e37395e55] [tid=305] /var/lib/gems/2.5.0/gems/actionpack-5.2.4.2/lib/action_controller/metal/rescue.rb:22:in `process_action'
DEBUG 2020/05/18 09:45:41 +0000 [pid=298] [origin=127.0.0.1] [request_id=b7390d52-73a1-41ff-add3-9f4e37395e55] [tid=305] /var/lib/gems/2.5.0/gems/actionpack-5.2.4.2/lib/action_controller/metal/instrumentation.rb:34:in `block in process_action'
DEBUG 2020/05/18 09:45:41 +0000 [pid=298] [origin=127.0.0.1] [request_id=b7390d52-73a1-41ff-add3-9f4e37395e55] [tid=305] /var/lib/gems/2.5.0/gems/activesupport-5.2.4.2/lib/active_support/notifications.rb:168:in `block in instrument'
DEBUG 2020/05/18 09:45:41 +0000 [pid=298] [origin=127.0.0.1] [request_id=b7390d52-73a1-41ff-add3-9f4e37395e55] [tid=305] /var/lib/gems/2.5.0/gems/activesupport-5.2.4.2/lib/active_support/notifications/instrumenter.rb:23:in `instrument'
DEBUG 2020/05/18 09:45:41 +0000 [pid=298] [origin=127.0.0.1] [request_id=b7390d52-73a1-41ff-add3-9f4e37395e55] [tid=305] /var/lib/gems/2.5.0/gems/activesupport-5.2.4.2/lib/active_support/notifications.rb:168:in `instrument'
DEBUG 2020/05/18 09:45:41 +0000 [pid=298] [origin=127.0.0.1] [request_id=b7390d52-73a1-41ff-add3-9f4e37395e55] [tid=305] /var/lib/gems/2.5.0/gems/actionpack-5.2.4.2/lib/action_controller/metal/instrumentation.rb:32:in `process_action'
DEBUG 2020/05/18 09:45:41 +0000 [pid=298] [origin=127.0.0.1] [request_id=b7390d52-73a1-41ff-add3-9f4e37395e55] [tid=305] /var/lib/gems/2.5.0/gems/actionpack-5.2.4.2/lib/action_controller/metal/params_wrapper.rb:256:in `process_action'
DEBUG 2020/05/18 09:45:41 +0000 [pid=298] [origin=127.0.0.1] [request_id=b7390d52-73a1-41ff-add3-9f4e37395e55] [tid=305] /var/lib/gems/2.5.0/gems/actionpack-5.2.4.2/lib/abstract_controller/base.rb:134:in `process'
DEBUG 2020/05/18 09:45:41 +0000 [pid=298] [origin=127.0.0.1] [request_id=b7390d52-73a1-41ff-add3-9f4e37395e55] [tid=305] /var/lib/gems/2.5.0/gems/actionview-5.2.4.2/lib/action_view/rendering.rb:32:in `process'
DEBUG 2020/05/18 09:45:41 +0000 [pid=298] [origin=127.0.0.1] [request_id=b7390d52-73a1-41ff-add3-9f4e37395e55] [tid=305] /var/lib/gems/2.5.0/gems/actionpack-5.2.4.2/lib/action_controller/metal.rb:191:in `dispatch'
DEBUG 2020/05/18 09:45:41 +0000 [pid=298] [origin=127.0.0.1] [request_id=b7390d52-73a1-41ff-add3-9f4e37395e55] [tid=305] /var/lib/gems/2.5.0/gems/actionpack-5.2.4.2/lib/action_controller/metal.rb:252:in `dispatch'
DEBUG 2020/05/18 09:45:41 +0000 [pid=298] [origin=127.0.0.1] [request_id=b7390d52-73a1-41ff-add3-9f4e37395e55] [tid=305] /var/lib/gems/2.5.0/gems/actionpack-5.2.4.2/lib/action_dispatch/routing/route_set.rb:52:in `dispatch'
DEBUG 2020/05/18 09:45:41 +0000 [pid=298] [origin=127.0.0.1] [request_id=b7390d52-73a1-41ff-add3-9f4e37395e55] [tid=305] /var/lib/gems/2.5.0/gems/actionpack-5.2.4.2/lib/action_dispatch/routing/route_set.rb:34:in `serve'
DEBUG 2020/05/18 09:45:41 +0000 [pid=298] [origin=127.0.0.1] [request_id=b7390d52-73a1-41ff-add3-9f4e37395e55] [tid=305] /var/lib/gems/2.5.0/gems/actionpack-5.2.4.2/lib/action_dispatch/journey/router.rb:52:in `block in serve'
DEBUG 2020/05/18 09:45:41 +0000 [pid=298] [origin=127.0.0.1] [request_id=b7390d52-73a1-41ff-add3-9f4e37395e55] [tid=305] /var/lib/gems/2.5.0/gems/actionpack-5.2.4.2/lib/action_dispatch/journey/router.rb:35:in `each'
DEBUG 2020/05/18 09:45:41 +0000 [pid=298] [origin=127.0.0.1] [request_id=b7390d52-73a1-41ff-add3-9f4e37395e55] [tid=305] /var/lib/gems/2.5.0/gems/actionpack-5.2.4.2/lib/action_dispatch/journey/router.rb:35:in `serve'
DEBUG 2020/05/18 09:45:41 +0000 [pid=298] [origin=127.0.0.1] [request_id=b7390d52-73a1-41ff-add3-9f4e37395e55] [tid=305] /var/lib/gems/2.5.0/gems/actionpack-5.2.4.2/lib/action_dispatch/routing/route_set.rb:840:in `call'
DEBUG 2020/05/18 09:45:41 +0000 [pid=298] [origin=127.0.0.1] [request_id=b7390d52-73a1-41ff-add3-9f4e37395e55] [tid=305] /src/conjur-server/lib/rack/default_content_type.rb:58:in `call'
DEBUG 2020/05/18 09:45:41 +0000 [pid=298] [origin=127.0.0.1] [request_id=b7390d52-73a1-41ff-add3-9f4e37395e55] [tid=305] /var/lib/gems/2.5.0/gems/conjur-rack-4.0.0/lib/conjur/rack/authenticator.rb:89:in `call'
DEBUG 2020/05/18 09:45:41 +0000 [pid=298] [origin=127.0.0.1] [request_id=b7390d52-73a1-41ff-add3-9f4e37395e55] [tid=305] /var/lib/gems/2.5.0/gems/rack-2.2.2/lib/rack/tempfile_reaper.rb:15:in `call'
DEBUG 2020/05/18 09:45:41 +0000 [pid=298] [origin=127.0.0.1] [request_id=b7390d52-73a1-41ff-add3-9f4e37395e55] [tid=305] /var/lib/gems/2.5.0/gems/rack-2.2.2/lib/rack/etag.rb:27:in `call'
DEBUG 2020/05/18 09:45:41 +0000 [pid=298] [origin=127.0.0.1] [request_id=b7390d52-73a1-41ff-add3-9f4e37395e55] [tid=305] /var/lib/gems/2.5.0/gems/rack-2.2.2/lib/rack/conditional_get.rb:40:in `call'
DEBUG 2020/05/18 09:45:41 +0000 [pid=298] [origin=127.0.0.1] [request_id=b7390d52-73a1-41ff-add3-9f4e37395e55] [tid=305] /var/lib/gems/2.5.0/gems/rack-2.2.2/lib/rack/head.rb:12:in `call'
DEBUG 2020/05/18 09:45:41 +0000 [pid=298] [origin=127.0.0.1] [request_id=b7390d52-73a1-41ff-add3-9f4e37395e55] [tid=305] /var/lib/gems/2.5.0/gems/actionpack-5.2.4.2/lib/action_dispatch/http/content_security_policy.rb:18:in `call'
DEBUG 2020/05/18 09:45:41 +0000 [pid=298] [origin=127.0.0.1] [request_id=b7390d52-73a1-41ff-add3-9f4e37395e55] [tid=305] /var/lib/gems/2.5.0/gems/rack-2.2.2/lib/rack/session/abstract/id.rb:266:in `context'
DEBUG 2020/05/18 09:45:41 +0000 [pid=298] [origin=127.0.0.1] [request_id=b7390d52-73a1-41ff-add3-9f4e37395e55] [tid=305] /var/lib/gems/2.5.0/gems/rack-2.2.2/lib/rack/session/abstract/id.rb:260:in `call'
DEBUG 2020/05/18 09:45:41 +0000 [pid=298] [origin=127.0.0.1] [request_id=b7390d52-73a1-41ff-add3-9f4e37395e55] [tid=305] /var/lib/gems/2.5.0/gems/actionpack-5.2.4.2/lib/action_dispatch/middleware/cookies.rb:670:in `call'
DEBUG 2020/05/18 09:45:41 +0000 [pid=298] [origin=127.0.0.1] [request_id=b7390d52-73a1-41ff-add3-9f4e37395e55] [tid=305] /var/lib/gems/2.5.0/gems/actionpack-5.2.4.2/lib/action_dispatch/middleware/callbacks.rb:28:in `block in call'
DEBUG 2020/05/18 09:45:41 +0000 [pid=298] [origin=127.0.0.1] [request_id=b7390d52-73a1-41ff-add3-9f4e37395e55] [tid=305] /var/lib/gems/2.5.0/gems/activesupport-5.2.4.2/lib/active_support/callbacks.rb:98:in `run_callbacks'
DEBUG 2020/05/18 09:45:41 +0000 [pid=298] [origin=127.0.0.1] [request_id=b7390d52-73a1-41ff-add3-9f4e37395e55] [tid=305] /var/lib/gems/2.5.0/gems/actionpack-5.2.4.2/lib/action_dispatch/middleware/callbacks.rb:26:in `call'
DEBUG 2020/05/18 09:45:41 +0000 [pid=298] [origin=127.0.0.1] [request_id=b7390d52-73a1-41ff-add3-9f4e37395e55] [tid=305] /var/lib/gems/2.5.0/gems/actionpack-5.2.4.2/lib/action_dispatch/middleware/debug_exceptions.rb:61:in `call'
DEBUG 2020/05/18 09:45:41 +0000 [pid=298] [origin=127.0.0.1] [request_id=b7390d52-73a1-41ff-add3-9f4e37395e55] [tid=305] /var/lib/gems/2.5.0/gems/actionpack-5.2.4.2/lib/action_dispatch/middleware/show_exceptions.rb:33:in `call'
DEBUG 2020/05/18 09:45:41 +0000 [pid=298] [origin=127.0.0.1] [request_id=b7390d52-73a1-41ff-add3-9f4e37395e55] [tid=305] /var/lib/gems/2.5.0/gems/railties-5.2.4.2/lib/rails/rack/logger.rb:38:in `call_app'
DEBUG 2020/05/18 09:45:41 +0000 [pid=298] [origin=127.0.0.1] [request_id=b7390d52-73a1-41ff-add3-9f4e37395e55] [tid=305] /var/lib/gems/2.5.0/gems/railties-5.2.4.2/lib/rails/rack/logger.rb:26:in `block in call'
DEBUG 2020/05/18 09:45:41 +0000 [pid=298] [origin=127.0.0.1] [request_id=b7390d52-73a1-41ff-add3-9f4e37395e55] [tid=305] /var/lib/gems/2.5.0/gems/activesupport-5.2.4.2/lib/active_support/tagged_logging.rb:71:in `block in tagged'
DEBUG 2020/05/18 09:45:41 +0000 [pid=298] [origin=127.0.0.1] [request_id=b7390d52-73a1-41ff-add3-9f4e37395e55] [tid=305] /var/lib/gems/2.5.0/gems/activesupport-5.2.4.2/lib/active_support/tagged_logging.rb:28:in `tagged'
DEBUG 2020/05/18 09:45:41 +0000 [pid=298] [origin=127.0.0.1] [request_id=b7390d52-73a1-41ff-add3-9f4e37395e55] [tid=305] /var/lib/gems/2.5.0/gems/activesupport-5.2.4.2/lib/active_support/tagged_logging.rb:71:in `tagged'
DEBUG 2020/05/18 09:45:41 +0000 [pid=298] [origin=127.0.0.1] [request_id=b7390d52-73a1-41ff-add3-9f4e37395e55] [tid=305] /var/lib/gems/2.5.0/gems/railties-5.2.4.2/lib/rails/rack/logger.rb:26:in `call'
DEBUG 2020/05/18 09:45:41 +0000 [pid=298] [origin=127.0.0.1] [request_id=b7390d52-73a1-41ff-add3-9f4e37395e55] [tid=305] /var/lib/gems/2.5.0/gems/actionpack-5.2.4.2/lib/action_dispatch/middleware/remote_ip.rb:81:in `call'
DEBUG 2020/05/18 09:45:41 +0000 [pid=298] [origin=127.0.0.1] [request_id=b7390d52-73a1-41ff-add3-9f4e37395e55] [tid=305] /var/lib/gems/2.5.0/gems/actionpack-5.2.4.2/lib/action_dispatch/middleware/request_id.rb:27:in `call'
DEBUG 2020/05/18 09:45:41 +0000 [pid=298] [origin=127.0.0.1] [request_id=b7390d52-73a1-41ff-add3-9f4e37395e55] [tid=305] /var/lib/gems/2.5.0/gems/rack-2.2.2/lib/rack/method_override.rb:24:in `call'
DEBUG 2020/05/18 09:45:41 +0000 [pid=298] [origin=127.0.0.1] [request_id=b7390d52-73a1-41ff-add3-9f4e37395e55] [tid=305] /var/lib/gems/2.5.0/gems/rack-2.2.2/lib/rack/runtime.rb:22:in `call'
DEBUG 2020/05/18 09:45:41 +0000 [pid=298] [origin=127.0.0.1] [request_id=b7390d52-73a1-41ff-add3-9f4e37395e55] [tid=305] /var/lib/gems/2.5.0/gems/activesupport-5.2.4.2/lib/active_support/cache/strategy/local_cache_middleware.rb:29:in `call'
DEBUG 2020/05/18 09:45:41 +0000 [pid=298] [origin=127.0.0.1] [request_id=b7390d52-73a1-41ff-add3-9f4e37395e55] [tid=305] /var/lib/gems/2.5.0/gems/actionpack-5.2.4.2/lib/action_dispatch/middleware/executor.rb:14:in `call'
DEBUG 2020/05/18 09:45:41 +0000 [pid=298] [origin=127.0.0.1] [request_id=b7390d52-73a1-41ff-add3-9f4e37395e55] [tid=305] /var/lib/gems/2.5.0/gems/actionpack-5.2.4.2/lib/action_dispatch/middleware/static.rb:127:in `call'
DEBUG 2020/05/18 09:45:41 +0000 [pid=298] [origin=127.0.0.1] [request_id=b7390d52-73a1-41ff-add3-9f4e37395e55] [tid=305] /var/lib/gems/2.5.0/gems/rack-2.2.2/lib/rack/sendfile.rb:110:in `call'
DEBUG 2020/05/18 09:45:41 +0000 [pid=298] [origin=127.0.0.1] [request_id=b7390d52-73a1-41ff-add3-9f4e37395e55] [tid=305] /var/lib/gems/2.5.0/gems/conjur-rack-heartbeat-2.2.0/lib/rack/heartbeat.rb:20:in `call'
DEBUG 2020/05/18 09:45:41 +0000 [pid=298] [origin=127.0.0.1] [request_id=b7390d52-73a1-41ff-add3-9f4e37395e55] [tid=305] /var/lib/gems/2.5.0/gems/railties-5.2.4.2/lib/rails/engine.rb:524:in `call'
DEBUG 2020/05/18 09:45:41 +0000 [pid=298] [origin=127.0.0.1] [request_id=b7390d52-73a1-41ff-add3-9f4e37395e55] [tid=305] /var/lib/gems/2.5.0/gems/puma-3.12.4/lib/puma/configuration.rb:227:in `call'
DEBUG 2020/05/18 09:45:41 +0000 [pid=298] [origin=127.0.0.1] [request_id=b7390d52-73a1-41ff-add3-9f4e37395e55] [tid=305] /var/lib/gems/2.5.0/gems/puma-3.12.4/lib/puma/server.rb:675:in `handle_request'
DEBUG 2020/05/18 09:45:41 +0000 [pid=298] [origin=127.0.0.1] [request_id=b7390d52-73a1-41ff-add3-9f4e37395e55] [tid=305] /var/lib/gems/2.5.0/gems/puma-3.12.4/lib/puma/server.rb:476:in `process_client'
DEBUG 2020/05/18 09:45:41 +0000 [pid=298] [origin=127.0.0.1] [request_id=b7390d52-73a1-41ff-add3-9f4e37395e55] [tid=305] /var/lib/gems/2.5.0/gems/puma-3.12.4/lib/puma/server.rb:334:in `block in run'
DEBUG 2020/05/18 09:45:41 +0000 [pid=298] [origin=127.0.0.1] [request_id=b7390d52-73a1-41ff-add3-9f4e37395e55] [tid=305] /var/lib/gems/2.5.0/gems/puma-3.12.4/lib/puma/thread_pool.rb:135:in `block in spawn_thread'
DEBUG 2020/05/18 09:45:41 +0000 [pid=298] [origin=127.0.0.1] [request_id=b7390d52-73a1-41ff-add3-9f4e37395e55] [tid=305]   Sequel::Postgres::Database (0.4ms)  ROLLBACK
DEBUG 2020/05/18 09:45:41 +0000 [pid=298] [origin=127.0.0.1] [request_id=b7390d52-73a1-41ff-add3-9f4e37395e55] [tid=305] ApplicationController::Unauthorized
/src/conjur-server/app/controllers/authenticate_controller.rb:159:in `handle_authentication_error'
/src/conjur-server/app/controllers/authenticate_controller.rb:95:in `rescue in authenticate_oidc'
/src/conjur-server/app/controllers/authenticate_controller.rb:89:in `authenticate_oidc'
/var/lib/gems/2.5.0/gems/actionpack-5.2.4.2/lib/action_controller/metal/basic_implicit_render.rb:6:in `send_action'
/var/lib/gems/2.5.0/gems/actionpack-5.2.4.2/lib/abstract_controller/base.rb:194:in `process_action'
/var/lib/gems/2.5.0/gems/actionpack-5.2.4.2/lib/action_controller/metal/rendering.rb:30:in `process_action'
/var/lib/gems/2.5.0/gems/actionpack-5.2.4.2/lib/abstract_controller/callbacks.rb:42:in `block in process_action'
/var/lib/gems/2.5.0/gems/activesupport-5.2.4.2/lib/active_support/callbacks.rb:109:in `block in run_callbacks'
/src/conjur-server/app/controllers/application_controller.rb:74:in `block in run_with_transaction'
/var/lib/gems/2.5.0/gems/sequel-4.49.0/lib/sequel/database/transactions.rb:224:in `_transaction'
/var/lib/gems/2.5.0/gems/sequel-4.49.0/lib/sequel/database/transactions.rb:199:in `block in transaction'
/var/lib/gems/2.5.0/gems/sequel-4.49.0/lib/sequel/database/connecting.rb:301:in `block in synchronize'
/var/lib/gems/2.5.0/gems/sequel-4.49.0/lib/sequel/connection_pool/threaded.rb:107:in `hold'
/var/lib/gems/2.5.0/gems/sequel-4.49.0/lib/sequel/database/connecting.rb:301:in `synchronize'
/var/lib/gems/2.5.0/gems/sequel-4.49.0/lib/sequel/database/transactions.rb:165:in `transaction'
/src/conjur-server/app/controllers/application_controller.rb:73:in `run_with_transaction'
/var/lib/gems/2.5.0/gems/activesupport-5.2.4.2/lib/active_support/callbacks.rb:118:in `block in run_callbacks'
/var/lib/gems/2.5.0/gems/activesupport-5.2.4.2/lib/active_support/callbacks.rb:136:in `run_callbacks'
/var/lib/gems/2.5.0/gems/actionpack-5.2.4.2/lib/abstract_controller/callbacks.rb:41:in `process_action'
/var/lib/gems/2.5.0/gems/actionpack-5.2.4.2/lib/action_controller/metal/rescue.rb:22:in `process_action'
/var/lib/gems/2.5.0/gems/actionpack-5.2.4.2/lib/action_controller/metal/instrumentation.rb:34:in `block in process_action'
/var/lib/gems/2.5.0/gems/activesupport-5.2.4.2/lib/active_support/notifications.rb:168:in `block in instrument'
/var/lib/gems/2.5.0/gems/activesupport-5.2.4.2/lib/active_support/notifications/instrumenter.rb:23:in `instrument'
/var/lib/gems/2.5.0/gems/activesupport-5.2.4.2/lib/active_support/notifications.rb:168:in `instrument'
/var/lib/gems/2.5.0/gems/actionpack-5.2.4.2/lib/action_controller/metal/instrumentation.rb:32:in `process_action'
/var/lib/gems/2.5.0/gems/actionpack-5.2.4.2/lib/action_controller/metal/params_wrapper.rb:256:in `process_action'
/var/lib/gems/2.5.0/gems/actionpack-5.2.4.2/lib/abstract_controller/base.rb:134:in `process'
/var/lib/gems/2.5.0/gems/actionview-5.2.4.2/lib/action_view/rendering.rb:32:in `process'
/var/lib/gems/2.5.0/gems/actionpack-5.2.4.2/lib/action_controller/metal.rb:191:in `dispatch'
/var/lib/gems/2.5.0/gems/actionpack-5.2.4.2/lib/action_controller/metal.rb:252:in `dispatch'
/var/lib/gems/2.5.0/gems/actionpack-5.2.4.2/lib/action_dispatch/routing/route_set.rb:52:in `dispatch'
/var/lib/gems/2.5.0/gems/actionpack-5.2.4.2/lib/action_dispatch/routing/route_set.rb:34:in `serve'
/var/lib/gems/2.5.0/gems/actionpack-5.2.4.2/lib/action_dispatch/journey/router.rb:52:in `block in serve'
/var/lib/gems/2.5.0/gems/actionpack-5.2.4.2/lib/action_dispatch/journey/router.rb:35:in `each'
/var/lib/gems/2.5.0/gems/actionpack-5.2.4.2/lib/action_dispatch/journey/router.rb:35:in `serve'
/var/lib/gems/2.5.0/gems/actionpack-5.2.4.2/lib/action_dispatch/routing/route_set.rb:840:in `call'
/src/conjur-server/lib/rack/default_content_type.rb:58:in `call'
/var/lib/gems/2.5.0/gems/conjur-rack-4.0.0/lib/conjur/rack/authenticator.rb:89:in `call'
/var/lib/gems/2.5.0/gems/rack-2.2.2/lib/rack/tempfile_reaper.rb:15:in `call'
/var/lib/gems/2.5.0/gems/rack-2.2.2/lib/rack/etag.rb:27:in `call'
/var/lib/gems/2.5.0/gems/rack-2.2.2/lib/rack/conditional_get.rb:40:in `call'
/var/lib/gems/2.5.0/gems/rack-2.2.2/lib/rack/head.rb:12:in `call'
/var/lib/gems/2.5.0/gems/actionpack-5.2.4.2/lib/action_dispatch/http/content_security_policy.rb:18:in `call'
/var/lib/gems/2.5.0/gems/rack-2.2.2/lib/rack/session/abstract/id.rb:266:in `context'
/var/lib/gems/2.5.0/gems/rack-2.2.2/lib/rack/session/abstract/id.rb:260:in `call'
/var/lib/gems/2.5.0/gems/actionpack-5.2.4.2/lib/action_dispatch/middleware/cookies.rb:670:in `call'
/var/lib/gems/2.5.0/gems/actionpack-5.2.4.2/lib/action_dispatch/middleware/callbacks.rb:28:in `block in call'
/var/lib/gems/2.5.0/gems/activesupport-5.2.4.2/lib/active_support/callbacks.rb:98:in `run_callbacks'
/var/lib/gems/2.5.0/gems/actionpack-5.2.4.2/lib/action_dispatch/middleware/callbacks.rb:26:in `call'
/var/lib/gems/2.5.0/gems/actionpack-5.2.4.2/lib/action_dispatch/middleware/debug_exceptions.rb:61:in `call'
/var/lib/gems/2.5.0/gems/actionpack-5.2.4.2/lib/action_dispatch/middleware/show_exceptions.rb:33:in `call'
/var/lib/gems/2.5.0/gems/railties-5.2.4.2/lib/rails/rack/logger.rb:38:in `call_app'
/var/lib/gems/2.5.0/gems/railties-5.2.4.2/lib/rails/rack/logger.rb:26:in `block in call'
/var/lib/gems/2.5.0/gems/activesupport-5.2.4.2/lib/active_support/tagged_logging.rb:71:in `block in tagged'
/var/lib/gems/2.5.0/gems/activesupport-5.2.4.2/lib/active_support/tagged_logging.rb:28:in `tagged'
/var/lib/gems/2.5.0/gems/activesupport-5.2.4.2/lib/active_support/tagged_logging.rb:71:in `tagged'
/var/lib/gems/2.5.0/gems/railties-5.2.4.2/lib/rails/rack/logger.rb:26:in `call'
/var/lib/gems/2.5.0/gems/actionpack-5.2.4.2/lib/action_dispatch/middleware/remote_ip.rb:81:in `call'
/var/lib/gems/2.5.0/gems/actionpack-5.2.4.2/lib/action_dispatch/middleware/request_id.rb:27:in `call'
/var/lib/gems/2.5.0/gems/rack-2.2.2/lib/rack/method_override.rb:24:in `call'
/var/lib/gems/2.5.0/gems/rack-2.2.2/lib/rack/runtime.rb:22:in `call'
/var/lib/gems/2.5.0/gems/activesupport-5.2.4.2/lib/active_support/cache/strategy/local_cache_middleware.rb:29:in `call'
/var/lib/gems/2.5.0/gems/actionpack-5.2.4.2/lib/action_dispatch/middleware/executor.rb:14:in `call'
/var/lib/gems/2.5.0/gems/actionpack-5.2.4.2/lib/action_dispatch/middleware/static.rb:127:in `call'
/var/lib/gems/2.5.0/gems/rack-2.2.2/lib/rack/sendfile.rb:110:in `call'
/var/lib/gems/2.5.0/gems/conjur-rack-heartbeat-2.2.0/lib/rack/heartbeat.rb:20:in `call'
/var/lib/gems/2.5.0/gems/railties-5.2.4.2/lib/rails/engine.rb:524:in `call'
/var/lib/gems/2.5.0/gems/puma-3.12.4/lib/puma/configuration.rb:227:in `call'
/var/lib/gems/2.5.0/gems/puma-3.12.4/lib/puma/server.rb:675:in `handle_request'
/var/lib/gems/2.5.0/gems/puma-3.12.4/lib/puma/server.rb:476:in `process_client'
/var/lib/gems/2.5.0/gems/puma-3.12.4/lib/puma/server.rb:334:in `block in run'
/var/lib/gems/2.5.0/gems/puma-3.12.4/lib/puma/thread_pool.rb:135:in `block in spawn_thread'
 INFO 2020/05/18 09:45:41 +0000 [pid=298] [origin=127.0.0.1] [request_id=b7390d52-73a1-41ff-add3-9f4e37395e55] [tid=305] Completed 401 Unauthorized in 288ms
```

As you can see, this log shows too much data on why the request failed.
This makes the log very hard to debug, and it's clear that we need some solution for this.

## Solution

We will redefine our log levels to the following:
1. DEBUG - messages that can help Conjur developers investigate an issue. These messages will include
           stack traces and DB messages.
2. INFO - messages that can help Conjur users and operators investigate an issue. These messages will include
          the messages that we print in our logs (messages with the `CONJ` prefix).
3. WARN - messages that prompts to Conjur users and operators that an issue is recoverable but should be addresses.

These level are based on Datadog's post on [managing Rails application logs](https://www.datadoghq.com/blog/managing-rails-application-logs/).

Let's look at a log sample for the same use-case we saw above, where a user sends an 
`authn-oidc` request with a username that is not defined in Conjur. 

If the log level is set to INFO (as the default value is), then the log will look like this:
```
 INFO 2020/05/17 17:39:58 +0000 [pid=401] [origin=127.0.0.1] [request_id=f39fb7e2-59f9-4f3a-89a9-bb9a50b09860] [tid=413] Started POST "/authn-oidc/keycloak/cucumber/authenticate" for 127.0.0.1 at 2020-05-17 17:39:58 +0000
 INFO 2020/05/17 17:39:58 +0000 [pid=401] [origin=127.0.0.1] [request_id=f39fb7e2-59f9-4f3a-89a9-bb9a50b09860] [tid=413] Processing by AuthenticateController#authenticate_oidc as */*
 INFO 2020/05/17 17:39:58 +0000 [pid=401] [origin=127.0.0.1] [request_id=f39fb7e2-59f9-4f3a-89a9-bb9a50b09860] [tid=413]   Parameters: {"service_id"=>"keycloak", "account"=>"cucumber"}
 INFO 2020/05/17 17:39:58 +0000 [pid=401] [origin=127.0.0.1] [request_id=f39fb7e2-59f9-4f3a-89a9-bb9a50b09860] [tid=413] CONJ00023I Concurrency limited cache concurrent requests updated to '1'
 INFO 2020/05/17 17:39:58 +0000 [pid=401] [origin=127.0.0.1] [request_id=f39fb7e2-59f9-4f3a-89a9-bb9a50b09860] [tid=413] CONJ00007I Working with Identity Provider https://keycloak:8443/auth/realms/master
 INFO 2020/05/17 17:39:58 +0000 [pid=401] [origin=127.0.0.1] [request_id=f39fb7e2-59f9-4f3a-89a9-bb9a50b09860] [tid=413] CONJ00008I Identity Provider discovery succeeded
 INFO 2020/05/17 17:39:58 +0000 [pid=401] [origin=127.0.0.1] [request_id=f39fb7e2-59f9-4f3a-89a9-bb9a50b09860] [tid=413] CONJ00009I Fetched Identity Provider keys from provider successfully
 INFO 2020/05/17 17:39:58 +0000 [pid=401] [origin=127.0.0.1] [request_id=f39fb7e2-59f9-4f3a-89a9-bb9a50b09860] [tid=413] CONJ00016I Rate limited cache updated successfully
 INFO 2020/05/17 17:39:58 +0000 [pid=401] [origin=127.0.0.1] [request_id=f39fb7e2-59f9-4f3a-89a9-bb9a50b09860] [tid=413] CONJ00021I Concurrency limited cache updated successfully
 INFO 2020/05/17 17:39:58 +0000 [pid=401] [origin=127.0.0.1] [request_id=f39fb7e2-59f9-4f3a-89a9-bb9a50b09860] [tid=413] CONJ00023I Concurrency limited cache concurrent requests updated to '0'
 INFO 2020/05/17 17:39:58 +0000 [pid=401] [origin=127.0.0.1] [request_id=f39fb7e2-59f9-4f3a-89a9-bb9a50b09860] [tid=413] CONJ00017I Fetched Identity Provider keys from cache successfully
 INFO 2020/05/17 17:39:58 +0000 [pid=401] [origin=127.0.0.1] [request_id=f39fb7e2-59f9-4f3a-89a9-bb9a50b09860] [tid=413] CONJ00005I Token decoded successfully
 INFO 2020/05/17 17:39:58 +0000 [pid=401] [origin=127.0.0.1] [request_id=f39fb7e2-59f9-4f3a-89a9-bb9a50b09860] [tid=413] CONJ00004I Extracted username 'not_in_conjur' from ID token field 'preferred_username'
 INFO 2020/05/17 17:39:59 +0000 [pid=401] [origin=127.0.0.1] [request_id=f39fb7e2-59f9-4f3a-89a9-bb9a50b09860] [tid=413] Authentication Error: #<Errors::Authentication::Security::RoleNotFound: CONJ00007E 'not_in_conjur' not found>
 INFO 2020/05/17 17:39:59 +0000 [pid=401] [origin=127.0.0.1] [request_id=f39fb7e2-59f9-4f3a-89a9-bb9a50b09860] [tid=413] Completed 401 Unauthorized in 143ms
```

We can see here a clear log that shows the flow of the request, finished by the error that occurred.

If the log level is set to DEBUG, then the log will look like this:
```
 INFO 2020/05/17 17:38:07 +0000 [pid=300] [origin=127.0.0.1] [request_id=d3f54689-ed9d-4c66-858a-d01d9c7adbc9] [tid=317] Started POST "/authn-oidc/keycloak/cucumber/authenticate" for 127.0.0.1 at 2020-05-17 17:38:07 +0000
 INFO 2020/05/17 17:38:07 +0000 [pid=300] [origin=127.0.0.1] [request_id=d3f54689-ed9d-4c66-858a-d01d9c7adbc9] [tid=317] Processing by AuthenticateController#authenticate_oidc as */*
 INFO 2020/05/17 17:38:07 +0000 [pid=300] [origin=127.0.0.1] [request_id=d3f54689-ed9d-4c66-858a-d01d9c7adbc9] [tid=317]   Parameters: {"service_id"=>"keycloak", "account"=>"cucumber"}
DEBUG 2020/05/17 17:38:07 +0000 [pid=300] [origin=127.0.0.1] [request_id=d3f54689-ed9d-4c66-858a-d01d9c7adbc9] [tid=317]   Sequel::Postgres::Database (0.5ms)  BEGIN
DEBUG 2020/05/17 17:38:07 +0000 [pid=300] [origin=127.0.0.1] [request_id=d3f54689-ed9d-4c66-858a-d01d9c7adbc9] [tid=317]   Sequel::Postgres::Database (0.8ms)  SELECT * FROM "roles" WHERE "role_id" = 'cucumber:user:admin'
DEBUG 2020/05/17 17:38:07 +0000 [pid=300] [origin=127.0.0.1] [request_id=d3f54689-ed9d-4c66-858a-d01d9c7adbc9] [tid=317]   Sequel::Postgres::Database (3.0ms)  SELECT * FROM "resources" WHERE "resource_id" = 'cucumber:variable:conjur/authn-oidc/keycloak/provider-uri'
DEBUG 2020/05/17 17:38:07 +0000 [pid=300] [origin=127.0.0.1] [request_id=d3f54689-ed9d-4c66-858a-d01d9c7adbc9] [tid=317]   Sequel::Postgres::Database (1.3ms)  SELECT * FROM "resources" WHERE "resource_id" = 'cucumber:variable:conjur/authn-oidc/keycloak/id-token-user-property'
DEBUG 2020/05/17 17:38:07 +0000 [pid=300] [origin=127.0.0.1] [request_id=d3f54689-ed9d-4c66-858a-d01d9c7adbc9] [tid=317]   Sequel::Postgres::Database (2.4ms)  SELECT * FROM "secrets" WHERE ("secrets"."resource_id" = 'cucumber:variable:conjur/authn-oidc/keycloak/provider-uri') ORDER BY "version" DESC LIMIT 1
DEBUG 2020/05/17 17:38:07 +0000 [pid=300] [origin=127.0.0.1] [request_id=d3f54689-ed9d-4c66-858a-d01d9c7adbc9] [tid=317]   Sequel::Postgres::Database (0.9ms)  SELECT * FROM "secrets" WHERE ("secrets"."resource_id" = 'cucumber:variable:conjur/authn-oidc/keycloak/id-token-user-property') ORDER BY "version" DESC LIMIT 1
 INFO 2020/05/17 17:38:07 +0000 [pid=300] [origin=127.0.0.1] [request_id=d3f54689-ed9d-4c66-858a-d01d9c7adbc9] [tid=317] CONJ00023I Concurrency limited cache concurrent requests updated to '1'
 INFO 2020/05/17 17:38:07 +0000 [pid=300] [origin=127.0.0.1] [request_id=d3f54689-ed9d-4c66-858a-d01d9c7adbc9] [tid=317] CONJ00007I Working with Identity Provider https://keycloak:8443/auth/realms/master
 INFO 2020/05/17 17:38:07 +0000 [pid=300] [origin=127.0.0.1] [request_id=d3f54689-ed9d-4c66-858a-d01d9c7adbc9] [tid=317] CONJ00008I Identity Provider discovery succeeded
 INFO 2020/05/17 17:38:07 +0000 [pid=300] [origin=127.0.0.1] [request_id=d3f54689-ed9d-4c66-858a-d01d9c7adbc9] [tid=317] CONJ00009I Fetched Identity Provider keys from provider successfully
 INFO 2020/05/17 17:38:07 +0000 [pid=300] [origin=127.0.0.1] [request_id=d3f54689-ed9d-4c66-858a-d01d9c7adbc9] [tid=317] CONJ00016I Rate limited cache updated successfully
 INFO 2020/05/17 17:38:07 +0000 [pid=300] [origin=127.0.0.1] [request_id=d3f54689-ed9d-4c66-858a-d01d9c7adbc9] [tid=317] CONJ00021I Concurrency limited cache updated successfully
 INFO 2020/05/17 17:38:07 +0000 [pid=300] [origin=127.0.0.1] [request_id=d3f54689-ed9d-4c66-858a-d01d9c7adbc9] [tid=317] CONJ00023I Concurrency limited cache concurrent requests updated to '0'
 INFO 2020/05/17 17:38:07 +0000 [pid=300] [origin=127.0.0.1] [request_id=d3f54689-ed9d-4c66-858a-d01d9c7adbc9] [tid=317] CONJ00017I Fetched Identity Provider keys from cache successfully
 INFO 2020/05/17 17:38:07 +0000 [pid=300] [origin=127.0.0.1] [request_id=d3f54689-ed9d-4c66-858a-d01d9c7adbc9] [tid=317] CONJ00005I Token decoded successfully
 INFO 2020/05/17 17:38:07 +0000 [pid=300] [origin=127.0.0.1] [request_id=d3f54689-ed9d-4c66-858a-d01d9c7adbc9] [tid=317] CONJ00004I Extracted username 'not_in_conjur' from ID token field 'preferred_username'
DEBUG 2020/05/17 17:38:07 +0000 [pid=300] [origin=127.0.0.1] [request_id=d3f54689-ed9d-4c66-858a-d01d9c7adbc9] [tid=317]   Sequel::Postgres::Database (0.5ms)  SELECT * FROM "roles" WHERE "role_id" = 'cucumber:user:admin'
DEBUG 2020/05/17 17:38:07 +0000 [pid=300] [origin=127.0.0.1] [request_id=d3f54689-ed9d-4c66-858a-d01d9c7adbc9] [tid=317]   Sequel::Postgres::Database (1.0ms)  SELECT * FROM "roles" WHERE "role_id" = 'cucumber:user:admin'
DEBUG 2020/05/17 17:38:07 +0000 [pid=300] [origin=127.0.0.1] [request_id=d3f54689-ed9d-4c66-858a-d01d9c7adbc9] [tid=317]   Sequel::Postgres::Database (1.5ms)  SELECT * FROM "roles" WHERE "role_id" = 'cucumber:user:admin'
DEBUG 2020/05/17 17:38:07 +0000 [pid=300] [origin=127.0.0.1] [request_id=d3f54689-ed9d-4c66-858a-d01d9c7adbc9] [tid=317]   Sequel::Postgres::Database (0.9ms)  SELECT * FROM "resources" WHERE "resource_id" = 'cucumber:webservice:conjur/authn-oidc/keycloak'
DEBUG 2020/05/17 17:38:07 +0000 [pid=300] [origin=127.0.0.1] [request_id=d3f54689-ed9d-4c66-858a-d01d9c7adbc9] [tid=317]   Sequel::Postgres::Database (1.7ms)  SELECT * FROM "roles" WHERE "role_id" = 'cucumber:user:not_in_conjur'
DEBUG 2020/05/17 17:38:07 +0000 [pid=300] [origin=127.0.0.1] [request_id=d3f54689-ed9d-4c66-858a-d01d9c7adbc9] [tid=317]   Sequel::Postgres::Database (1.1ms)  SELECT * FROM "roles" WHERE ("role_id" = 'cucumber:user:not_in_conjur') LIMIT 1
 INFO 2020/05/17 17:38:07 +0000 [pid=300] [origin=127.0.0.1] [request_id=d3f54689-ed9d-4c66-858a-d01d9c7adbc9] [tid=317] Authentication Error: #<Errors::Authentication::Security::RoleNotFound: CONJ00007E 'not_in_conjur' not found>
DEBUG 2020/05/17 17:38:07 +0000 [pid=300] [origin=127.0.0.1] [request_id=d3f54689-ed9d-4c66-858a-d01d9c7adbc9] [tid=317] /src/conjur-server/app/domain/authentication/validate_webservice_access.rb:59:in `validate_user_is_defined'
DEBUG 2020/05/17 17:38:07 +0000 [pid=300] [origin=127.0.0.1] [request_id=d3f54689-ed9d-4c66-858a-d01d9c7adbc9] [tid=317] /src/conjur-server/app/domain/authentication/validate_webservice_access.rb:34:in `call'
DEBUG 2020/05/17 17:38:07 +0000 [pid=300] [origin=127.0.0.1] [request_id=d3f54689-ed9d-4c66-858a-d01d9c7adbc9] [tid=317] (eval):7:in `call'
DEBUG 2020/05/17 17:38:07 +0000 [pid=300] [origin=127.0.0.1] [request_id=d3f54689-ed9d-4c66-858a-d01d9c7adbc9] [tid=317] /src/conjur-server/app/domain/authentication/validate_security.rb:47:in `validate_user_has_access_to_webservice'
DEBUG 2020/05/17 17:38:07 +0000 [pid=300] [origin=127.0.0.1] [request_id=d3f54689-ed9d-4c66-858a-d01d9c7adbc9] [tid=317] /src/conjur-server/app/domain/authentication/validate_security.rb:28:in `call'
DEBUG 2020/05/17 17:38:07 +0000 [pid=300] [origin=127.0.0.1] [request_id=d3f54689-ed9d-4c66-858a-d01d9c7adbc9] [tid=317] (eval):7:in `call'
DEBUG 2020/05/17 17:38:07 +0000 [pid=300] [origin=127.0.0.1] [request_id=d3f54689-ed9d-4c66-858a-d01d9c7adbc9] [tid=317] /src/conjur-server/app/domain/authentication/authn_oidc/authenticate.rb:118:in `validate_security'
DEBUG 2020/05/17 17:38:07 +0000 [pid=300] [origin=127.0.0.1] [request_id=d3f54689-ed9d-4c66-858a-d01d9c7adbc9] [tid=317] /src/conjur-server/app/domain/authentication/authn_oidc/authenticate.rb:41:in `call'
DEBUG 2020/05/17 17:38:07 +0000 [pid=300] [origin=127.0.0.1] [request_id=d3f54689-ed9d-4c66-858a-d01d9c7adbc9] [tid=317] (eval):7:in `call'
DEBUG 2020/05/17 17:38:07 +0000 [pid=300] [origin=127.0.0.1] [request_id=d3f54689-ed9d-4c66-858a-d01d9c7adbc9] [tid=317] /src/conjur-server/app/controllers/authenticate_controller.rb:90:in `authenticate_oidc'
DEBUG 2020/05/17 17:38:07 +0000 [pid=300] [origin=127.0.0.1] [request_id=d3f54689-ed9d-4c66-858a-d01d9c7adbc9] [tid=317] /var/lib/gems/2.5.0/gems/actionpack-5.2.4.2/lib/action_controller/metal/basic_implicit_render.rb:6:in `send_action'
DEBUG 2020/05/17 17:38:07 +0000 [pid=300] [origin=127.0.0.1] [request_id=d3f54689-ed9d-4c66-858a-d01d9c7adbc9] [tid=317] /var/lib/gems/2.5.0/gems/actionpack-5.2.4.2/lib/abstract_controller/base.rb:194:in `process_action'
DEBUG 2020/05/17 17:38:07 +0000 [pid=300] [origin=127.0.0.1] [request_id=d3f54689-ed9d-4c66-858a-d01d9c7adbc9] [tid=317] /var/lib/gems/2.5.0/gems/actionpack-5.2.4.2/lib/action_controller/metal/rendering.rb:30:in `process_action'
DEBUG 2020/05/17 17:38:07 +0000 [pid=300] [origin=127.0.0.1] [request_id=d3f54689-ed9d-4c66-858a-d01d9c7adbc9] [tid=317] /var/lib/gems/2.5.0/gems/actionpack-5.2.4.2/lib/abstract_controller/callbacks.rb:42:in `block in process_action'
DEBUG 2020/05/17 17:38:07 +0000 [pid=300] [origin=127.0.0.1] [request_id=d3f54689-ed9d-4c66-858a-d01d9c7adbc9] [tid=317] /var/lib/gems/2.5.0/gems/activesupport-5.2.4.2/lib/active_support/callbacks.rb:109:in `block in run_callbacks'
DEBUG 2020/05/17 17:38:07 +0000 [pid=300] [origin=127.0.0.1] [request_id=d3f54689-ed9d-4c66-858a-d01d9c7adbc9] [tid=317] /src/conjur-server/app/controllers/application_controller.rb:74:in `block in run_with_transaction'
DEBUG 2020/05/17 17:38:07 +0000 [pid=300] [origin=127.0.0.1] [request_id=d3f54689-ed9d-4c66-858a-d01d9c7adbc9] [tid=317] /var/lib/gems/2.5.0/gems/sequel-4.49.0/lib/sequel/database/transactions.rb:224:in `_transaction'
DEBUG 2020/05/17 17:38:07 +0000 [pid=300] [origin=127.0.0.1] [request_id=d3f54689-ed9d-4c66-858a-d01d9c7adbc9] [tid=317] /var/lib/gems/2.5.0/gems/sequel-4.49.0/lib/sequel/database/transactions.rb:199:in `block in transaction'
DEBUG 2020/05/17 17:38:07 +0000 [pid=300] [origin=127.0.0.1] [request_id=d3f54689-ed9d-4c66-858a-d01d9c7adbc9] [tid=317] /var/lib/gems/2.5.0/gems/sequel-4.49.0/lib/sequel/database/connecting.rb:301:in `block in synchronize'
DEBUG 2020/05/17 17:38:07 +0000 [pid=300] [origin=127.0.0.1] [request_id=d3f54689-ed9d-4c66-858a-d01d9c7adbc9] [tid=317] /var/lib/gems/2.5.0/gems/sequel-4.49.0/lib/sequel/connection_pool/threaded.rb:107:in `hold'
DEBUG 2020/05/17 17:38:07 +0000 [pid=300] [origin=127.0.0.1] [request_id=d3f54689-ed9d-4c66-858a-d01d9c7adbc9] [tid=317] /var/lib/gems/2.5.0/gems/sequel-4.49.0/lib/sequel/database/connecting.rb:301:in `synchronize'
DEBUG 2020/05/17 17:38:07 +0000 [pid=300] [origin=127.0.0.1] [request_id=d3f54689-ed9d-4c66-858a-d01d9c7adbc9] [tid=317] /var/lib/gems/2.5.0/gems/sequel-4.49.0/lib/sequel/database/transactions.rb:165:in `transaction'
DEBUG 2020/05/17 17:38:07 +0000 [pid=300] [origin=127.0.0.1] [request_id=d3f54689-ed9d-4c66-858a-d01d9c7adbc9] [tid=317] /src/conjur-server/app/controllers/application_controller.rb:73:in `run_with_transaction'
DEBUG 2020/05/17 17:38:07 +0000 [pid=300] [origin=127.0.0.1] [request_id=d3f54689-ed9d-4c66-858a-d01d9c7adbc9] [tid=317] /var/lib/gems/2.5.0/gems/activesupport-5.2.4.2/lib/active_support/callbacks.rb:118:in `block in run_callbacks'
DEBUG 2020/05/17 17:38:07 +0000 [pid=300] [origin=127.0.0.1] [request_id=d3f54689-ed9d-4c66-858a-d01d9c7adbc9] [tid=317] /var/lib/gems/2.5.0/gems/activesupport-5.2.4.2/lib/active_support/callbacks.rb:136:in `run_callbacks'
DEBUG 2020/05/17 17:38:07 +0000 [pid=300] [origin=127.0.0.1] [request_id=d3f54689-ed9d-4c66-858a-d01d9c7adbc9] [tid=317] /var/lib/gems/2.5.0/gems/actionpack-5.2.4.2/lib/abstract_controller/callbacks.rb:41:in `process_action'
DEBUG 2020/05/17 17:38:07 +0000 [pid=300] [origin=127.0.0.1] [request_id=d3f54689-ed9d-4c66-858a-d01d9c7adbc9] [tid=317] /var/lib/gems/2.5.0/gems/actionpack-5.2.4.2/lib/action_controller/metal/rescue.rb:22:in `process_action'
DEBUG 2020/05/17 17:38:07 +0000 [pid=300] [origin=127.0.0.1] [request_id=d3f54689-ed9d-4c66-858a-d01d9c7adbc9] [tid=317] /var/lib/gems/2.5.0/gems/actionpack-5.2.4.2/lib/action_controller/metal/instrumentation.rb:34:in `block in process_action'
DEBUG 2020/05/17 17:38:07 +0000 [pid=300] [origin=127.0.0.1] [request_id=d3f54689-ed9d-4c66-858a-d01d9c7adbc9] [tid=317] /var/lib/gems/2.5.0/gems/activesupport-5.2.4.2/lib/active_support/notifications.rb:168:in `block in instrument'
DEBUG 2020/05/17 17:38:07 +0000 [pid=300] [origin=127.0.0.1] [request_id=d3f54689-ed9d-4c66-858a-d01d9c7adbc9] [tid=317] /var/lib/gems/2.5.0/gems/activesupport-5.2.4.2/lib/active_support/notifications/instrumenter.rb:23:in `instrument'
DEBUG 2020/05/17 17:38:07 +0000 [pid=300] [origin=127.0.0.1] [request_id=d3f54689-ed9d-4c66-858a-d01d9c7adbc9] [tid=317] /var/lib/gems/2.5.0/gems/activesupport-5.2.4.2/lib/active_support/notifications.rb:168:in `instrument'
DEBUG 2020/05/17 17:38:07 +0000 [pid=300] [origin=127.0.0.1] [request_id=d3f54689-ed9d-4c66-858a-d01d9c7adbc9] [tid=317] /var/lib/gems/2.5.0/gems/actionpack-5.2.4.2/lib/action_controller/metal/instrumentation.rb:32:in `process_action'
DEBUG 2020/05/17 17:38:07 +0000 [pid=300] [origin=127.0.0.1] [request_id=d3f54689-ed9d-4c66-858a-d01d9c7adbc9] [tid=317] /var/lib/gems/2.5.0/gems/actionpack-5.2.4.2/lib/action_controller/metal/params_wrapper.rb:256:in `process_action'
DEBUG 2020/05/17 17:38:07 +0000 [pid=300] [origin=127.0.0.1] [request_id=d3f54689-ed9d-4c66-858a-d01d9c7adbc9] [tid=317] /var/lib/gems/2.5.0/gems/actionpack-5.2.4.2/lib/abstract_controller/base.rb:134:in `process'
DEBUG 2020/05/17 17:38:07 +0000 [pid=300] [origin=127.0.0.1] [request_id=d3f54689-ed9d-4c66-858a-d01d9c7adbc9] [tid=317] /var/lib/gems/2.5.0/gems/actionview-5.2.4.2/lib/action_view/rendering.rb:32:in `process'
DEBUG 2020/05/17 17:38:07 +0000 [pid=300] [origin=127.0.0.1] [request_id=d3f54689-ed9d-4c66-858a-d01d9c7adbc9] [tid=317] /var/lib/gems/2.5.0/gems/actionpack-5.2.4.2/lib/action_controller/metal.rb:191:in `dispatch'
DEBUG 2020/05/17 17:38:07 +0000 [pid=300] [origin=127.0.0.1] [request_id=d3f54689-ed9d-4c66-858a-d01d9c7adbc9] [tid=317] /var/lib/gems/2.5.0/gems/actionpack-5.2.4.2/lib/action_controller/metal.rb:252:in `dispatch'
DEBUG 2020/05/17 17:38:07 +0000 [pid=300] [origin=127.0.0.1] [request_id=d3f54689-ed9d-4c66-858a-d01d9c7adbc9] [tid=317] /var/lib/gems/2.5.0/gems/actionpack-5.2.4.2/lib/action_dispatch/routing/route_set.rb:52:in `dispatch'
DEBUG 2020/05/17 17:38:07 +0000 [pid=300] [origin=127.0.0.1] [request_id=d3f54689-ed9d-4c66-858a-d01d9c7adbc9] [tid=317] /var/lib/gems/2.5.0/gems/actionpack-5.2.4.2/lib/action_dispatch/routing/route_set.rb:34:in `serve'
DEBUG 2020/05/17 17:38:07 +0000 [pid=300] [origin=127.0.0.1] [request_id=d3f54689-ed9d-4c66-858a-d01d9c7adbc9] [tid=317] /var/lib/gems/2.5.0/gems/actionpack-5.2.4.2/lib/action_dispatch/journey/router.rb:52:in `block in serve'
DEBUG 2020/05/17 17:38:07 +0000 [pid=300] [origin=127.0.0.1] [request_id=d3f54689-ed9d-4c66-858a-d01d9c7adbc9] [tid=317] /var/lib/gems/2.5.0/gems/actionpack-5.2.4.2/lib/action_dispatch/journey/router.rb:35:in `each'
DEBUG 2020/05/17 17:38:07 +0000 [pid=300] [origin=127.0.0.1] [request_id=d3f54689-ed9d-4c66-858a-d01d9c7adbc9] [tid=317] /var/lib/gems/2.5.0/gems/actionpack-5.2.4.2/lib/action_dispatch/journey/router.rb:35:in `serve'
DEBUG 2020/05/17 17:38:07 +0000 [pid=300] [origin=127.0.0.1] [request_id=d3f54689-ed9d-4c66-858a-d01d9c7adbc9] [tid=317] /var/lib/gems/2.5.0/gems/actionpack-5.2.4.2/lib/action_dispatch/routing/route_set.rb:840:in `call'
DEBUG 2020/05/17 17:38:07 +0000 [pid=300] [origin=127.0.0.1] [request_id=d3f54689-ed9d-4c66-858a-d01d9c7adbc9] [tid=317] /src/conjur-server/lib/rack/default_content_type.rb:58:in `call'
DEBUG 2020/05/17 17:38:07 +0000 [pid=300] [origin=127.0.0.1] [request_id=d3f54689-ed9d-4c66-858a-d01d9c7adbc9] [tid=317] /var/lib/gems/2.5.0/gems/conjur-rack-4.0.0/lib/conjur/rack/authenticator.rb:89:in `call'
DEBUG 2020/05/17 17:38:07 +0000 [pid=300] [origin=127.0.0.1] [request_id=d3f54689-ed9d-4c66-858a-d01d9c7adbc9] [tid=317] /var/lib/gems/2.5.0/gems/rack-2.2.2/lib/rack/tempfile_reaper.rb:15:in `call'
DEBUG 2020/05/17 17:38:07 +0000 [pid=300] [origin=127.0.0.1] [request_id=d3f54689-ed9d-4c66-858a-d01d9c7adbc9] [tid=317] /var/lib/gems/2.5.0/gems/rack-2.2.2/lib/rack/etag.rb:27:in `call'
DEBUG 2020/05/17 17:38:07 +0000 [pid=300] [origin=127.0.0.1] [request_id=d3f54689-ed9d-4c66-858a-d01d9c7adbc9] [tid=317] /var/lib/gems/2.5.0/gems/rack-2.2.2/lib/rack/conditional_get.rb:40:in `call'
DEBUG 2020/05/17 17:38:07 +0000 [pid=300] [origin=127.0.0.1] [request_id=d3f54689-ed9d-4c66-858a-d01d9c7adbc9] [tid=317] /var/lib/gems/2.5.0/gems/rack-2.2.2/lib/rack/head.rb:12:in `call'
DEBUG 2020/05/17 17:38:07 +0000 [pid=300] [origin=127.0.0.1] [request_id=d3f54689-ed9d-4c66-858a-d01d9c7adbc9] [tid=317] /var/lib/gems/2.5.0/gems/actionpack-5.2.4.2/lib/action_dispatch/http/content_security_policy.rb:18:in `call'
DEBUG 2020/05/17 17:38:07 +0000 [pid=300] [origin=127.0.0.1] [request_id=d3f54689-ed9d-4c66-858a-d01d9c7adbc9] [tid=317] /var/lib/gems/2.5.0/gems/rack-2.2.2/lib/rack/session/abstract/id.rb:266:in `context'
DEBUG 2020/05/17 17:38:07 +0000 [pid=300] [origin=127.0.0.1] [request_id=d3f54689-ed9d-4c66-858a-d01d9c7adbc9] [tid=317] /var/lib/gems/2.5.0/gems/rack-2.2.2/lib/rack/session/abstract/id.rb:260:in `call'
DEBUG 2020/05/17 17:38:07 +0000 [pid=300] [origin=127.0.0.1] [request_id=d3f54689-ed9d-4c66-858a-d01d9c7adbc9] [tid=317] /var/lib/gems/2.5.0/gems/actionpack-5.2.4.2/lib/action_dispatch/middleware/cookies.rb:670:in `call'
DEBUG 2020/05/17 17:38:07 +0000 [pid=300] [origin=127.0.0.1] [request_id=d3f54689-ed9d-4c66-858a-d01d9c7adbc9] [tid=317] /var/lib/gems/2.5.0/gems/actionpack-5.2.4.2/lib/action_dispatch/middleware/callbacks.rb:28:in `block in call'
DEBUG 2020/05/17 17:38:07 +0000 [pid=300] [origin=127.0.0.1] [request_id=d3f54689-ed9d-4c66-858a-d01d9c7adbc9] [tid=317] /var/lib/gems/2.5.0/gems/activesupport-5.2.4.2/lib/active_support/callbacks.rb:98:in `run_callbacks'
DEBUG 2020/05/17 17:38:07 +0000 [pid=300] [origin=127.0.0.1] [request_id=d3f54689-ed9d-4c66-858a-d01d9c7adbc9] [tid=317] /var/lib/gems/2.5.0/gems/actionpack-5.2.4.2/lib/action_dispatch/middleware/callbacks.rb:26:in `call'
DEBUG 2020/05/17 17:38:07 +0000 [pid=300] [origin=127.0.0.1] [request_id=d3f54689-ed9d-4c66-858a-d01d9c7adbc9] [tid=317] /var/lib/gems/2.5.0/gems/actionpack-5.2.4.2/lib/action_dispatch/middleware/debug_exceptions.rb:61:in `call'
DEBUG 2020/05/17 17:38:07 +0000 [pid=300] [origin=127.0.0.1] [request_id=d3f54689-ed9d-4c66-858a-d01d9c7adbc9] [tid=317] /var/lib/gems/2.5.0/gems/actionpack-5.2.4.2/lib/action_dispatch/middleware/show_exceptions.rb:33:in `call'
DEBUG 2020/05/17 17:38:07 +0000 [pid=300] [origin=127.0.0.1] [request_id=d3f54689-ed9d-4c66-858a-d01d9c7adbc9] [tid=317] /var/lib/gems/2.5.0/gems/railties-5.2.4.2/lib/rails/rack/logger.rb:38:in `call_app'
DEBUG 2020/05/17 17:38:07 +0000 [pid=300] [origin=127.0.0.1] [request_id=d3f54689-ed9d-4c66-858a-d01d9c7adbc9] [tid=317] /var/lib/gems/2.5.0/gems/railties-5.2.4.2/lib/rails/rack/logger.rb:26:in `block in call'
DEBUG 2020/05/17 17:38:07 +0000 [pid=300] [origin=127.0.0.1] [request_id=d3f54689-ed9d-4c66-858a-d01d9c7adbc9] [tid=317] /var/lib/gems/2.5.0/gems/activesupport-5.2.4.2/lib/active_support/tagged_logging.rb:71:in `block in tagged'
DEBUG 2020/05/17 17:38:07 +0000 [pid=300] [origin=127.0.0.1] [request_id=d3f54689-ed9d-4c66-858a-d01d9c7adbc9] [tid=317] /var/lib/gems/2.5.0/gems/activesupport-5.2.4.2/lib/active_support/tagged_logging.rb:28:in `tagged'
DEBUG 2020/05/17 17:38:07 +0000 [pid=300] [origin=127.0.0.1] [request_id=d3f54689-ed9d-4c66-858a-d01d9c7adbc9] [tid=317] /var/lib/gems/2.5.0/gems/activesupport-5.2.4.2/lib/active_support/tagged_logging.rb:71:in `tagged'
DEBUG 2020/05/17 17:38:07 +0000 [pid=300] [origin=127.0.0.1] [request_id=d3f54689-ed9d-4c66-858a-d01d9c7adbc9] [tid=317] /var/lib/gems/2.5.0/gems/railties-5.2.4.2/lib/rails/rack/logger.rb:26:in `call'
DEBUG 2020/05/17 17:38:07 +0000 [pid=300] [origin=127.0.0.1] [request_id=d3f54689-ed9d-4c66-858a-d01d9c7adbc9] [tid=317] /var/lib/gems/2.5.0/gems/actionpack-5.2.4.2/lib/action_dispatch/middleware/remote_ip.rb:81:in `call'
DEBUG 2020/05/17 17:38:07 +0000 [pid=300] [origin=127.0.0.1] [request_id=d3f54689-ed9d-4c66-858a-d01d9c7adbc9] [tid=317] /var/lib/gems/2.5.0/gems/actionpack-5.2.4.2/lib/action_dispatch/middleware/request_id.rb:27:in `call'
DEBUG 2020/05/17 17:38:07 +0000 [pid=300] [origin=127.0.0.1] [request_id=d3f54689-ed9d-4c66-858a-d01d9c7adbc9] [tid=317] /var/lib/gems/2.5.0/gems/rack-2.2.2/lib/rack/method_override.rb:24:in `call'
DEBUG 2020/05/17 17:38:07 +0000 [pid=300] [origin=127.0.0.1] [request_id=d3f54689-ed9d-4c66-858a-d01d9c7adbc9] [tid=317] /var/lib/gems/2.5.0/gems/rack-2.2.2/lib/rack/runtime.rb:22:in `call'
DEBUG 2020/05/17 17:38:07 +0000 [pid=300] [origin=127.0.0.1] [request_id=d3f54689-ed9d-4c66-858a-d01d9c7adbc9] [tid=317] /var/lib/gems/2.5.0/gems/activesupport-5.2.4.2/lib/active_support/cache/strategy/local_cache_middleware.rb:29:in `call'
DEBUG 2020/05/17 17:38:07 +0000 [pid=300] [origin=127.0.0.1] [request_id=d3f54689-ed9d-4c66-858a-d01d9c7adbc9] [tid=317] /var/lib/gems/2.5.0/gems/actionpack-5.2.4.2/lib/action_dispatch/middleware/executor.rb:14:in `call'
DEBUG 2020/05/17 17:38:07 +0000 [pid=300] [origin=127.0.0.1] [request_id=d3f54689-ed9d-4c66-858a-d01d9c7adbc9] [tid=317] /var/lib/gems/2.5.0/gems/actionpack-5.2.4.2/lib/action_dispatch/middleware/static.rb:127:in `call'
DEBUG 2020/05/17 17:38:07 +0000 [pid=300] [origin=127.0.0.1] [request_id=d3f54689-ed9d-4c66-858a-d01d9c7adbc9] [tid=317] /var/lib/gems/2.5.0/gems/rack-2.2.2/lib/rack/sendfile.rb:110:in `call'
DEBUG 2020/05/17 17:38:07 +0000 [pid=300] [origin=127.0.0.1] [request_id=d3f54689-ed9d-4c66-858a-d01d9c7adbc9] [tid=317] /var/lib/gems/2.5.0/gems/conjur-rack-heartbeat-2.2.0/lib/rack/heartbeat.rb:20:in `call'
DEBUG 2020/05/17 17:38:07 +0000 [pid=300] [origin=127.0.0.1] [request_id=d3f54689-ed9d-4c66-858a-d01d9c7adbc9] [tid=317] /var/lib/gems/2.5.0/gems/railties-5.2.4.2/lib/rails/engine.rb:524:in `call'
DEBUG 2020/05/17 17:38:07 +0000 [pid=300] [origin=127.0.0.1] [request_id=d3f54689-ed9d-4c66-858a-d01d9c7adbc9] [tid=317] /var/lib/gems/2.5.0/gems/puma-3.12.4/lib/puma/configuration.rb:227:in `call'
DEBUG 2020/05/17 17:38:07 +0000 [pid=300] [origin=127.0.0.1] [request_id=d3f54689-ed9d-4c66-858a-d01d9c7adbc9] [tid=317] /var/lib/gems/2.5.0/gems/puma-3.12.4/lib/puma/server.rb:675:in `handle_request'
DEBUG 2020/05/17 17:38:07 +0000 [pid=300] [origin=127.0.0.1] [request_id=d3f54689-ed9d-4c66-858a-d01d9c7adbc9] [tid=317] /var/lib/gems/2.5.0/gems/puma-3.12.4/lib/puma/server.rb:476:in `process_client'
DEBUG 2020/05/17 17:38:07 +0000 [pid=300] [origin=127.0.0.1] [request_id=d3f54689-ed9d-4c66-858a-d01d9c7adbc9] [tid=317] /var/lib/gems/2.5.0/gems/puma-3.12.4/lib/puma/server.rb:334:in `block in run'
DEBUG 2020/05/17 17:38:07 +0000 [pid=300] [origin=127.0.0.1] [request_id=d3f54689-ed9d-4c66-858a-d01d9c7adbc9] [tid=317] /var/lib/gems/2.5.0/gems/puma-3.12.4/lib/puma/thread_pool.rb:135:in `block in spawn_thread'
DEBUG 2020/05/17 17:38:07 +0000 [pid=300] [origin=127.0.0.1] [request_id=d3f54689-ed9d-4c66-858a-d01d9c7adbc9] [tid=317]   Sequel::Postgres::Database (1.9ms)  ROLLBACK
DEBUG 2020/05/17 17:38:07 +0000 [pid=300] [origin=127.0.0.1] [request_id=d3f54689-ed9d-4c66-858a-d01d9c7adbc9] [tid=317] ApplicationController::Unauthorized
/src/conjur-server/app/controllers/authenticate_controller.rb:159:in `handle_authentication_error'
/src/conjur-server/app/controllers/authenticate_controller.rb:95:in `rescue in authenticate_oidc'
/src/conjur-server/app/controllers/authenticate_controller.rb:89:in `authenticate_oidc'
/var/lib/gems/2.5.0/gems/actionpack-5.2.4.2/lib/action_controller/metal/basic_implicit_render.rb:6:in `send_action'
/var/lib/gems/2.5.0/gems/actionpack-5.2.4.2/lib/abstract_controller/base.rb:194:in `process_action'
/var/lib/gems/2.5.0/gems/actionpack-5.2.4.2/lib/action_controller/metal/rendering.rb:30:in `process_action'
/var/lib/gems/2.5.0/gems/actionpack-5.2.4.2/lib/abstract_controller/callbacks.rb:42:in `block in process_action'
/var/lib/gems/2.5.0/gems/activesupport-5.2.4.2/lib/active_support/callbacks.rb:109:in `block in run_callbacks'
/src/conjur-server/app/controllers/application_controller.rb:74:in `block in run_with_transaction'
/var/lib/gems/2.5.0/gems/sequel-4.49.0/lib/sequel/database/transactions.rb:224:in `_transaction'
/var/lib/gems/2.5.0/gems/sequel-4.49.0/lib/sequel/database/transactions.rb:199:in `block in transaction'
/var/lib/gems/2.5.0/gems/sequel-4.49.0/lib/sequel/database/connecting.rb:301:in `block in synchronize'
/var/lib/gems/2.5.0/gems/sequel-4.49.0/lib/sequel/connection_pool/threaded.rb:107:in `hold'
/var/lib/gems/2.5.0/gems/sequel-4.49.0/lib/sequel/database/connecting.rb:301:in `synchronize'
/var/lib/gems/2.5.0/gems/sequel-4.49.0/lib/sequel/database/transactions.rb:165:in `transaction'
/src/conjur-server/app/controllers/application_controller.rb:73:in `run_with_transaction'
/var/lib/gems/2.5.0/gems/activesupport-5.2.4.2/lib/active_support/callbacks.rb:118:in `block in run_callbacks'
/var/lib/gems/2.5.0/gems/activesupport-5.2.4.2/lib/active_support/callbacks.rb:136:in `run_callbacks'
/var/lib/gems/2.5.0/gems/actionpack-5.2.4.2/lib/abstract_controller/callbacks.rb:41:in `process_action'
/var/lib/gems/2.5.0/gems/actionpack-5.2.4.2/lib/action_controller/metal/rescue.rb:22:in `process_action'
/var/lib/gems/2.5.0/gems/actionpack-5.2.4.2/lib/action_controller/metal/instrumentation.rb:34:in `block in process_action'
/var/lib/gems/2.5.0/gems/activesupport-5.2.4.2/lib/active_support/notifications.rb:168:in `block in instrument'
/var/lib/gems/2.5.0/gems/activesupport-5.2.4.2/lib/active_support/notifications/instrumenter.rb:23:in `instrument'
/var/lib/gems/2.5.0/gems/activesupport-5.2.4.2/lib/active_support/notifications.rb:168:in `instrument'
/var/lib/gems/2.5.0/gems/actionpack-5.2.4.2/lib/action_controller/metal/instrumentation.rb:32:in `process_action'
/var/lib/gems/2.5.0/gems/actionpack-5.2.4.2/lib/action_controller/metal/params_wrapper.rb:256:in `process_action'
/var/lib/gems/2.5.0/gems/actionpack-5.2.4.2/lib/abstract_controller/base.rb:134:in `process'
/var/lib/gems/2.5.0/gems/actionview-5.2.4.2/lib/action_view/rendering.rb:32:in `process'
/var/lib/gems/2.5.0/gems/actionpack-5.2.4.2/lib/action_controller/metal.rb:191:in `dispatch'
/var/lib/gems/2.5.0/gems/actionpack-5.2.4.2/lib/action_controller/metal.rb:252:in `dispatch'
/var/lib/gems/2.5.0/gems/actionpack-5.2.4.2/lib/action_dispatch/routing/route_set.rb:52:in `dispatch'
/var/lib/gems/2.5.0/gems/actionpack-5.2.4.2/lib/action_dispatch/routing/route_set.rb:34:in `serve'
/var/lib/gems/2.5.0/gems/actionpack-5.2.4.2/lib/action_dispatch/journey/router.rb:52:in `block in serve'
/var/lib/gems/2.5.0/gems/actionpack-5.2.4.2/lib/action_dispatch/journey/router.rb:35:in `each'
/var/lib/gems/2.5.0/gems/actionpack-5.2.4.2/lib/action_dispatch/journey/router.rb:35:in `serve'
/var/lib/gems/2.5.0/gems/actionpack-5.2.4.2/lib/action_dispatch/routing/route_set.rb:840:in `call'
/src/conjur-server/lib/rack/default_content_type.rb:58:in `call'
/var/lib/gems/2.5.0/gems/conjur-rack-4.0.0/lib/conjur/rack/authenticator.rb:89:in `call'
/var/lib/gems/2.5.0/gems/rack-2.2.2/lib/rack/tempfile_reaper.rb:15:in `call'
/var/lib/gems/2.5.0/gems/rack-2.2.2/lib/rack/etag.rb:27:in `call'
/var/lib/gems/2.5.0/gems/rack-2.2.2/lib/rack/conditional_get.rb:40:in `call'
/var/lib/gems/2.5.0/gems/rack-2.2.2/lib/rack/head.rb:12:in `call'
/var/lib/gems/2.5.0/gems/actionpack-5.2.4.2/lib/action_dispatch/http/content_security_policy.rb:18:in `call'
/var/lib/gems/2.5.0/gems/rack-2.2.2/lib/rack/session/abstract/id.rb:266:in `context'
/var/lib/gems/2.5.0/gems/rack-2.2.2/lib/rack/session/abstract/id.rb:260:in `call'
/var/lib/gems/2.5.0/gems/actionpack-5.2.4.2/lib/action_dispatch/middleware/cookies.rb:670:in `call'
/var/lib/gems/2.5.0/gems/actionpack-5.2.4.2/lib/action_dispatch/middleware/callbacks.rb:28:in `block in call'
/var/lib/gems/2.5.0/gems/activesupport-5.2.4.2/lib/active_support/callbacks.rb:98:in `run_callbacks'
/var/lib/gems/2.5.0/gems/actionpack-5.2.4.2/lib/action_dispatch/middleware/callbacks.rb:26:in `call'
/var/lib/gems/2.5.0/gems/actionpack-5.2.4.2/lib/action_dispatch/middleware/debug_exceptions.rb:61:in `call'
/var/lib/gems/2.5.0/gems/actionpack-5.2.4.2/lib/action_dispatch/middleware/show_exceptions.rb:33:in `call'
/var/lib/gems/2.5.0/gems/railties-5.2.4.2/lib/rails/rack/logger.rb:38:in `call_app'
/var/lib/gems/2.5.0/gems/railties-5.2.4.2/lib/rails/rack/logger.rb:26:in `block in call'
/var/lib/gems/2.5.0/gems/activesupport-5.2.4.2/lib/active_support/tagged_logging.rb:71:in `block in tagged'
/var/lib/gems/2.5.0/gems/activesupport-5.2.4.2/lib/active_support/tagged_logging.rb:28:in `tagged'
/var/lib/gems/2.5.0/gems/activesupport-5.2.4.2/lib/active_support/tagged_logging.rb:71:in `tagged'
/var/lib/gems/2.5.0/gems/railties-5.2.4.2/lib/rails/rack/logger.rb:26:in `call'
/var/lib/gems/2.5.0/gems/actionpack-5.2.4.2/lib/action_dispatch/middleware/remote_ip.rb:81:in `call'
/var/lib/gems/2.5.0/gems/actionpack-5.2.4.2/lib/action_dispatch/middleware/request_id.rb:27:in `call'
/var/lib/gems/2.5.0/gems/rack-2.2.2/lib/rack/method_override.rb:24:in `call'
/var/lib/gems/2.5.0/gems/rack-2.2.2/lib/rack/runtime.rb:22:in `call'
/var/lib/gems/2.5.0/gems/activesupport-5.2.4.2/lib/active_support/cache/strategy/local_cache_middleware.rb:29:in `call'
/var/lib/gems/2.5.0/gems/actionpack-5.2.4.2/lib/action_dispatch/middleware/executor.rb:14:in `call'
/var/lib/gems/2.5.0/gems/actionpack-5.2.4.2/lib/action_dispatch/middleware/static.rb:127:in `call'
/var/lib/gems/2.5.0/gems/rack-2.2.2/lib/rack/sendfile.rb:110:in `call'
/var/lib/gems/2.5.0/gems/conjur-rack-heartbeat-2.2.0/lib/rack/heartbeat.rb:20:in `call'
/var/lib/gems/2.5.0/gems/railties-5.2.4.2/lib/rails/engine.rb:524:in `call'
/var/lib/gems/2.5.0/gems/puma-3.12.4/lib/puma/configuration.rb:227:in `call'
/var/lib/gems/2.5.0/gems/puma-3.12.4/lib/puma/server.rb:675:in `handle_request'
/var/lib/gems/2.5.0/gems/puma-3.12.4/lib/puma/server.rb:476:in `process_client'
/var/lib/gems/2.5.0/gems/puma-3.12.4/lib/puma/server.rb:334:in `block in run'
/var/lib/gems/2.5.0/gems/puma-3.12.4/lib/puma/thread_pool.rb:135:in `block in spawn_thread'
 INFO 2020/05/17 17:38:07 +0000 [pid=300] [origin=127.0.0.1] [request_id=d3f54689-ed9d-4c66-858a-d01d9c7adbc9] [tid=317] Completed 401 Unauthorized in 447ms
```

Here we can see that the log is more robust and has all the data that can help a developer
to investigate the issue, including the stack trace and the DB messages.

### Backwards compatibility

It's important to say that the UX will not change by default. We will do this by changing
the default value for the log level from `info` to `warn`. This way the log will show the
same data that it shows today.

### Affected Components

- Conjur
- DAP
  - The DAP log contains not only the Conjur log but also the logs of `evoke`, `conjur-ui` & `ldap-sync`. We will update
    their logs to fit our logs classification defined above.  
    let's address each component to decide on the action items:
    - `evoke`: this component doesn't write to the log in INFO level so it won't be affected by the change.
    - `conjur-ui`: this components writes messages in DEBUG, INFO and WARN and should be addressed.
    - `ldap-sync`: this components writes messages in DEBUG, INFO and WARN and should be addressed.

## Security

We do not change the current Conjur log as we log the same data by default. Therefore,
there is no security concern in this effort.

## Test Plan

We will not introduce new tests in this effort and the regression tests will be enough.

## Documentation

In our [current docs](https://docs.cyberark.com/Product-Doc/OnlineHelp/AAM-DAP/Latest/en/Content/Operations/Services/logs.htm#Enabledebuglogmessages)
we explain how users can enable debug logs. We will need to update that page to explain
on the differences between INFO and DEBUG.

The page above exists only for DAP as we have an issue in Conjur where it's impossible 
to restart the server. Once that is solved we can create the page for Conjur as well.

We will also add an entry to the CHANGELOG of all the repos that change their logs.

## Version update

- Conjur
- DAP

## Breaking

The following tasks should be done as part of this effort:

- Change log level of messages in all repos (conjur, evoke, ui, ldap-sync) according to the guidelines.
    - Change the error codes in Conjur accordingly: `CONJ<some-number>D` to `CONJ<some-number>I`
- Change the default log level in `production.rb` from `info` to `warn`
- Change the default log level in `appliance.rb` from `info` to `warn`
- Add an entry in the CHANGELOG regarding this change
- Update the docs
