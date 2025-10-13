# frozen_string_literal: true

module Keygen
  module EE
    class ExpiredLicenseError < StandardError; end

    class License
      class << self
        def current = @current ||= self.new(LicenseFile.current)
        def reset!  = (@current = nil; LicenseFile.reset!) if Rails.env.test?
      end

      def initialize(lic)
        @lic = lic
      end

      def id           = lic.license['id']
      def entitlements = lic.entitlements.collect { it['attributes']['code'].downcase.to_sym }
      def product      = lic.product&.[]('id')
      def policy       = lic.policy&.[]('id')

      def expiry = attributes['expiry'].present? ? Time.parse(attributes['expiry']) : nil
      def name   = attributes['name']

      def present?  = lic.present?
      def expires?  = expiry.present?
      def expiring? = expires? && expiry > Time.current && expiry < 30.days.from_now
      def expired?  = expires? && expiry < Time.current

      def valid?
        raise ExpiredLicenseError, 'license is expired' if
          expired? && expiry < 30.days.ago

         !expired?
      end

      def entitled?(*codes)
        (codes & entitlements) == codes
      end

      private

      attr_reader :lic

      def attributes    = lic.license['attributes']
      def relationships = lic.license['relationships']
    end
  end
end
