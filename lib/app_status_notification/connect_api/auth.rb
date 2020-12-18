# frozen_string_literal: true

require 'jwt'

module AppStatusNotification
  class ConnectAPI
    class Auth
      AUDIENCE = 'appstoreconnect-v1'
      ALGORITHM = 'ES256'
      EXPIRE_DURATION = 20 * 60

      attr_reader :issuer_id, :key_id, :private_key

      def initialize(**kargs)
        @issuer_id = kargs[:issuer_id]
        @key_id = kargs[:key_id]
        @private_key = handle_private_key(kargs[:private_key])
      end

      def token
        JWT.encode(payload, private_key, ALGORITHM, header_fields)
      end

      private

      def payload
        {
          aud: AUDIENCE,
          iss: issuer_id,
          exp: Time.now.to_i + EXPIRE_DURATION
        }
      end

      def header_fields
        { kid: key_id }
      end

      def handle_private_key(key)
        key = File.open(key) if File.file?(key)
        OpenSSL::PKey.read(key)
      end
    end
  end
end
