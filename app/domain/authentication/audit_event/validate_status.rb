module Authentication
  module AuditEvent
    class ValidateStatus < ::Audit::Event::Authn  
      operation 'validate-status'

      success_message do
        format "%s successfully validated status for authenticator %s%s",
          role_id, authenticator_name, service_message_part
      end

      failure_message do
        format "%s failed to validate status for authenticator %s%s",
          role_id, authenticator_name, service_message_part
      end
    end
  end
end
