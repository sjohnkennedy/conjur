module Authentication
  module AuthnK8s
    module AuditEvent
      class InjectClientCert < ::Audit::Event::Authn
        operation 'k8s-inject-client-cert'

        success_message do
          format "%s successfully injected client certificate with authenticator %s%s",
            role_id, authenticator_name, service_message_part
        end

        failure_message do
          format "%s failed to inject client certificate with authenticator %s%s",
            role_id, authenticator_name, service_message_part
        end
      end
    end
  end
end
