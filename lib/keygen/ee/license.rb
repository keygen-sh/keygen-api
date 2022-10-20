# frozen_string_literal: true

module Keygen
  module EE
    class License
      def self.current = @current ||= self.new(LicenseFile.current)
      def self.reset!  = @current = nil if Rails.env.test?

      def initialize(lic)
        @lic = lic
      end

      def id           = lic.license['id']
      def entitlements = lic.entitlements.collect { _1['attributes']['code'].downcase.to_sym }
      def product      = lic.product['id']
      def policy       = lic.policy['id']

      def present? = lic.present?
      def expiry   = attributes['expiry'].present? ? Time.parse(attributes['expiry']) : nil
      def expires? = expiry.present?
      def expired? = present? && expires? && expiry < Time.current
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
