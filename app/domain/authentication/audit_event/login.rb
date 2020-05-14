module Authentication
  module AuditEvent
    class Login < ::Audit::Event::Authn  
      operation 'login'

      success_message do
        format "%s successfully logged in with authenticator %s%s",
          role_id, authenticator_name, service_message_part
      end

      failure_message do
        format "%s failed to login with authenticator %s%s",
          role_id, authenticator_name, service_message_part
      end
    end
  end
end
