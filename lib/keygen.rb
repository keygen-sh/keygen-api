# frozen_string_literal: true

require_relative 'keygen/console'
require_relative 'keygen/ee'
require_relative 'keygen/error'
require_relative 'keygen/jsonapi'
require_relative 'keygen/logger'
require_relative 'keygen/middleware'

module Keygen
  PUBLIC_KEY = %(\xB8\xF3\xEBL\xD2`\x13_g\xA5\tn\x8D\xC1\xC9\xB9\xDC\xB8\x1E\xE9\xFEP\xD1,\xDC\xD9A\xF6`z\x901).freeze
  VERSION    = '1.2.0'.freeze

  class << self
    def logger = Logger

    def console? = Rails.const_defined?(:Console)
    def server?  = Rails.const_defined?(:Server) || puma?
    def worker?  = sidekiq?

    def ce? = !lic? && !key?
    def ee? = !ce?

    def ee(&block)
      return unless
        ee?

      case block.arity
      when 2
        yield EE.license, EE.license_file
      when 1
        yield EE.license
      when 0
        yield
      else
        raise ArgumentError, 'expected block with 0..2 arguments'
      end
    end

    private

    def lic? = ENV.key?('KEYGEN_LICENSE_FILE_PATH') || ENV.key?('KEYGEN_LICENSE_FILE')
    def key? = ENV.key?('KEYGEN_LICENSE_KEY')

    def puma?    = Puma.const_defined?(:Server) && $0.include?('puma')
    def sidekiq? = Sidekiq.const_defined?(:CLI)
  end
end
