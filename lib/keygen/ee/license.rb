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
      def entitlements = lic.entitlements.collect { _1['attributes']['code'].downcase.to_sym }
      def product      = lic.product['id']
      def policy       = lic.policy['id']

      def present? = lic.present?
      def expiry   = Time.parse(attributes['expiry'])
      def expired? = present? && expiry < Time.current
      def valid?   = present? && lic.valid? && !expired?

      def entitled?(*codes)
        present? && (codes & entitlements) == codes
      end

      private

      attr_reader :lic

      def attributes    = lic.license['attributes']
      def relationships = lic.license['relationships']
    end
  end
end
