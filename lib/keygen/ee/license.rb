# frozen_string_literal: true

module Keygen
  module EE
    class License
      def self.current
        @current ||= self.new(LicenseFile.current)
      end

      def initialize(lic)
        @lic = lic
      end

      def id           = lic.license['id']
      def entitlements = lic.entitlements.collect { _1['attributes']['code'] }
      def product      = lic.product['id']
      def policy       = lic.policy['id']

      def expiry   = Time.parse(attributes['expiry'])
      def expired? = expiry < Time.current
      def valid?   = lic.valid? && !expired?

      private

      attr_reader :lic

      def attributes    = lic.license['attributes']
      def relationships = lic.license['relationships']
    end
  end
end
