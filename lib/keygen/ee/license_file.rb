# frozen_string_literal: true

module Keygen
  module EE
    class InvalidLicenseFileError < StandardError; end
    class ExpiredLicenseFileError < StandardError; end

    class LicenseFile
      DEFAULT_PATH = '/etc/keygen/ee.lic'.freeze

      HEADER_RE = /\A-----BEGIN LICENSE FILE-----\n/.freeze
      FOOTER_RE = /-----END LICENSE FILE-----\n*\z/.freeze

      class << self
        def current = @current ||= self.new
        def reset!  = @current = nil if Rails.env.test?
      end

      def initialize(data = nil)
        @data = data&.with_indifferent_access
      end

      def license      = data['data']
      def entitlements = data['included']&.filter { it['type'] == 'entitlements' } || []
      def environment  = data['included']&.find { it['type'] == 'environments' }
      def product      = data['included']&.find { it['type'] == 'products' }
      def policy       = data['included']&.find { it['type'] == 'policies' }

      def present?  = data.present? rescue false
      def issued    = Time.parse(data['meta']['issued'])
      def expiry    = data['meta']['expiry'].present? ? Time.parse(data['meta']['expiry']) : nil
      def expires?  = expiry.present?
      def expiring? = expires? && expiry > Time.current && expiry < 30.days.from_now
      def expired?  = expires? && expiry < Time.current
      def desync?   = issued > Time.current

      def valid?
        unless environment.nil? || (environment in attributes: { code: /#{Rails.env}/i => code })
          raise InvalidLicenseFileError, "environment does not match (expected #{Rails.env.inspect} got #{code.inspect.downcase})"
        end

        raise InvalidLicenseFileError, 'system clock is desynchronized' if
          desync?

        raise ExpiredLicenseFileError, 'license file is expired' if
          expired? && expiry < 30.days.ago

        !expired?
      end

      private

      def data = @data ||= load!

      def import!(path: DEFAULT_PATH, enc: nil)
        return Base64.strict_decode64(enc) if
          enc.present?

        path = if (p = Pathname.new(path)) && p.relative?
                 Rails.root.join(p)
               else
                 path
               end

        File.read(path)
      rescue => e
        raise InvalidLicenseFileError, "license file is missing or invalid: #{e}"
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

      def decrypt!(data, key:)
        raise InvalidLicenseFileError, 'license key is missing' unless
          key.present?

        aes = OpenSSL::Cipher::AES256.new(:GCM)
        aes.decrypt

        enc                 = data['enc']
        ciphertext, iv, tag = enc.split('.')
                                 .map { Base64.strict_decode64(it) }

        aes.key = OpenSSL::Digest::SHA256.digest(key)
        aes.iv  = iv

        aes.auth_tag  = tag
        aes.auth_data = ''

        aes.update(ciphertext) + aes.final
      rescue => e
        raise InvalidLicenseFileError, "failed to decrypt license file: #{e}"
      end

      def decode!(s)
        JSON.parse(s)
      rescue => e
        raise InvalidLicenseFileError, "failed to decode license file: #{e}"
      end

      def load!
        path = ENV['KEYGEN_LICENSE_FILE_PATH']
        enc  = ENV['KEYGEN_LICENSE_FILE']
        key  = ENV['KEYGEN_LICENSE_KEY']

        kwargs = { path:, enc: }.compact
        cert   = import!(**kwargs)
        lic    = parse!(cert)

        verify!(lic)

        s = decrypt!(lic, key:)

        decode!(s)
      end
    end
  end
end
