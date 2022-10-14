# frozen_string_literal: true

module Keygen
  module EE
    class LicenseFile
      class InvalidLicenseFileError < StandardError; end

      HEADER_RE = /\A-----BEGIN LICENSE FILE-----\n/.freeze
      FOOTER_RE = /-----END LICENSE FILE-----\n*\z/.freeze

      def self.current = @current ||= self.new

      def license      = data['data']
      def entitlements = data['included']&.filter { _1['type'] == 'entitlements' }
      def product      = data['included']&.find { _1['type'] == 'products' }
      def policy       = data['included']&.find { _1['type'] == 'policies' }

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

      def path = ENV['KEYGEN_LICENSE_FILE']
      def key  = ENV['KEYGEN_LICENSE_KEY']
      def data = @data ||= load!

      def import!(path)
        raise InvalidLicenseFileError, 'license file is missing' unless
          File.exist?(path)

        File.read(path)
      end

      def parse!(cert)
        raise InvalidLicenseFileError, 'license file is malformed' if
          cert.nil?

        dec = Base64.decode64(
          cert.gsub(HEADER_RE, '')
              .gsub(FOOTER_RE, ''),
        )

        JSON.parse(dec)
      end

      def verify!(data)
        ed   = Ed25519::VerifyKey.new(PUBLIC_KEY)
        enc  = data['enc']
        sig  = data['sig']

        raise InvalidLicenseFileError, 'license file signature is invalid' unless
          ed.verify(Base64.strict_decode64(sig), "license/#{enc}")

        nil
      rescue
        raise InvalidLicenseFileError, 'failed to verify license file'
      end

      def decrypt!(data)
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
      rescue
        raise InvalidLicenseFileError, 'failed to decrypt license file'
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
