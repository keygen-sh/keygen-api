# frozen_string_literal: true

module Keygen
  module EE
    class LicenseFile
      class InvalidLicenseFileError < StandardError; end

      HEADER_RE = /\A-----BEGIN LICENSE FILE-----\n/.freeze
      FOOTER_RE = /-----END LICENSE FILE-----\n*\z/.freeze

      def self.current = @current ||= self.new

      def license      = data['data']
      def entitlements = data['included']&.filter { _1['type'] == 'entitlements' } || []
      def product      = data['included']&.find { _1['type'] == 'products' }
      def policy       = data['included']&.find { _1['type'] == 'policies' }

      def present?  = data.present? rescue false
      def issued    = Time.parse(data['meta']['issued'])
      def expiry    = Time.parse(data['meta']['expiry'])
      def tampered? = issued > Time.current
      def expired?  = expiry < Time.current

      def valid?
        raise InvalidLicenseFileError, 'system clock is out of sync' if
          tampered?

        !expired?
      end

      private

      def path = ENV.fetch('KEYGEN_LICENSE_FILE') { '/etc/keygen/ee.lic' }
      def key  = ENV['KEYGEN_LICENSE_KEY']
      def data = @data ||= load!

      def import!(path)
        File.read(path)
      rescue => e
        raise InvalidLicenseFileError, "license file is missing: #{e}"
      end

      def parse!(cert)
        dec = Base64.decode64(
          cert.gsub(HEADER_RE, '')
              .gsub(FOOTER_RE, ''),
        )

        JSON.parse(dec)
      rescue => e
        raise InvalidLicenseFileError, "license file is malformed: #{e}"
      end

      def verify!(data)
        ed   = Ed25519::VerifyKey.new(PUBLIC_KEY)
        enc  = data['enc']
        sig  = data['sig']

        raise InvalidLicenseFileError, 'license file signature is invalid' unless
          ed.verify(Base64.strict_decode64(sig), "license/#{enc}")

        nil
      rescue => e
        raise InvalidLicenseFileError, "failed to verify license file: #{e}"
      end

      def decrypt!(data)
        raise InvalidLicenseFileError, 'license key is missing' unless
          key.present?

        aes = OpenSSL::Cipher::AES256.new(:GCM)
        aes.decrypt

        enc                 = data['enc']
        ciphertext, iv, tag = enc.split('.')
                                 .map { Base64.strict_decode64(_1) }

        aes.key = OpenSSL::Digest::SHA256.digest(key)
        aes.iv  = iv

        aes.auth_tag  = tag
        aes.auth_data = ''

        aes.update(ciphertext) + aes.final
      rescue => e
        raise InvalidLicenseFileError, "failed to decrypt license file: #{e}"
      end

      def load!
        cert = import!(path)
        lic  = parse!(cert)

        verify!(lic)

        dec = decrypt!(lic)

        JSON.parse(dec)
      end
    end
  end
end
