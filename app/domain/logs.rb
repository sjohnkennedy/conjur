# frozen_string_literal: true

require 'util/trackable_log_message_class'

unless defined? LogMessages::Authentication::OriginValidated
  # This wrapper prevents classes from being loaded by Rails
  # auto-load. #TODO: fix this in a proper manner

  module LogMessages

    module Authentication

      OriginValidated = ::Util::TrackableLogMessageClass.new(
        msg:  "Origin validated",
        code: "CONJ00003I"
      )

      ValidatingAnnotationsWithPrefix = ::Util::TrackableLogMessageClass.new(
        msg:  "Validating annotations with prefix {0-prefix}",
        code: "CONJ00025I"
      )

      RetrievedAnnotationValue = ::Util::TrackableLogMessageClass.new(
        msg:  "Retrieved value of annotation {0-annotation-name}",
        code: "CONJ00024I"
      )

      ContainerNameAnnotationDefaultValue = ::Util::TrackableLogMessageClass.new(
        msg:  "Annotation '{0-authentication-container-annotation-name}' not found. " \
                "Using default value '{1-default-authentication-container}'",
        code: "CONJ00033I"
      )

      module Security

        SecurityValidated = ::Util::TrackableLogMessageClass.new(
          msg:  "Security validated",
          code: "CONJ00001I"
        )

      end

      module OAuth

        IdentityProviderUri = ::Util::TrackableLogMessageClass.new(
          msg:  "Working with Identity Provider {0-provider-uri}",
          code: "CONJ00007I"
        )

        IdentityProviderDiscoverySuccess = ::Util::TrackableLogMessageClass.new(
          msg:  "Identity Provider discovery succeeded",
          code: "CONJ00008I"
        )

        FetchProviderKeysSuccess = ::Util::TrackableLogMessageClass.new(
          msg:  "Fetched Identity Provider keys from provider successfully",
          code: "CONJ00009I"
        )

        IdentityProviderKeysFetchedFromCache = ::Util::TrackableLogMessageClass.new(
          msg:  "Fetched Identity Provider keys from cache successfully",
          code: "CONJ00017I"
        )

        ValidateProviderKeysAreUpdated = ::Util::TrackableLogMessageClass.new(
          msg:  "Validating that Identity Provider keys are up to date",
          code: "CONJ00019I"
        )

      end

      module Jwt

        TokenDecodeSuccess = ::Util::TrackableLogMessageClass.new(
          msg:  "Token decoded successfully",
          code: "CONJ00005I"
        )

        TokenDecodeFailed = ::Util::TrackableLogMessageClass.new(
          msg:  "Failed to decode the token with the error '{0-exception}'",
          code: "CONJ00018I"
        )

      end

      module AuthnOidc

        ExtractedUsernameFromIDToked = ::Util::TrackableLogMessageClass.new(
          msg:  "Extracted username '{0}' from ID token field '{1-id-token-username-field}'",
          code: "CONJ00004I"
        )

      end

      module AuthnK8s

        PodChannelOpen = ::Util::TrackableLogMessageClass.new(
          msg:  "Pod '{0-pod-name}' : channel open",
          code: "CONJ00010I"
        )

        PodChannelClosed = ::Util::TrackableLogMessageClass.new(
          msg:  "Pod '{0-pod-name}' : channel closed",
          code: "CONJ00011I"
        )

        PodChannelData = ::Util::TrackableLogMessageClass.new(
          msg:  "Pod '{0-pod-name}', channel '{1-cahnnel-name}': {2-message-data}",
          code: "CONJ00012I"
        )

        PodMessageData = ::Util::TrackableLogMessageClass.new(
          msg:  "Pod: '{0-pod-name}', message: '{1-message-type}', data: '{2-message-data}'",
          code: "CONJ00013I"
        )

        PodError = ::Util::TrackableLogMessageClass.new(
          msg:  "Pod '{0-pod-name}' error : '{1}'",
          code: "CONJ00014I"
        )

        CopySSLToPod = ::Util::TrackableLogMessageClass.new(
          msg:  "Copying SSL certificate to {0-pod-namespace}/{1-pod-name}",
          code: "CONJ00015I"
        )

        ValidatingHostId = ::Util::TrackableLogMessageClass.new(
          msg:  "Validating host id {0}",
          code: "CONJ00026I"
        )

        HostIdFromCommonName = ::Util::TrackableLogMessageClass.new(
          msg:  "Host id {0} extracted from CSR common name",
          code: "CONJ00027I"
        )

        SetCommonName = ::Util::TrackableLogMessageClass.new(
          msg:  "Setting common name to {0-full-host-name}",
          code: "CONJ00028I"
        )
      end

      module AuthnAzure

        ExtractedApplicationIdentityFromToken = ::Util::TrackableLogMessageClass.new(
          msg:  "Extracted application identity from token",
          code: "CONJ00029I"
        )

        ValidatedApplicationIdentity = ::Util::TrackableLogMessageClass.new(
          msg:  "Application identity validated",
          code: "CONJ00030I"
        )

        ExtractedFieldFromAzureToken = ::Util::TrackableLogMessageClass.new(
          msg:  "Extracted field '{0-field-name}' with value {1-field-value} from token",
          code: "CONJ00031I"
        )

        ValidatingTokenFieldExists = ::Util::TrackableLogMessageClass.new(
          msg:  "Validating that field '{0}' exists in token",
          code: "CONJ00032I"
        )

      end
    end

    module Util

      RateLimitedCacheUpdated = ::Util::TrackableLogMessageClass.new(
        msg:  "Rate limited cache updated successfully",
        code: "CONJ00016I"
      )

      RateLimitedCacheLimitReached = ::Util::TrackableLogMessageClass.new(
        msg:  "Rate limited cache reached the '{0-limit}' limit and will not " \
              "call target for the next '{1-seconds}' seconds",
        code: "CONJ00020I"
      )

      ConcurrencyLimitedCacheUpdated = ::Util::TrackableLogMessageClass.new(
        msg:  "Concurrency limited cache updated successfully",
        code: "CONJ00021I"
      )

      ConcurrencyLimitedCacheReached = ::Util::TrackableLogMessageClass.new(
        msg:  "Concurrency limited cache reached the '{0-limit}' limit and will not call target",
        code: "CONJ00022I"
      )

      ConcurrencyLimitedCacheConcurrentRequestsUpdated = ::Util::TrackableLogMessageClass.new(
        msg:  "Concurrency limited cache concurrent requests updated to '{0-concurrent-requests}'",
        code: "CONJ00023I"
      )

    end
  end
end
