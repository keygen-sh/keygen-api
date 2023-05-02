# frozen_string_literal: true

require_relative 'keygen/console'
require_relative 'keygen/ee'
require_relative 'keygen/error'
require_relative 'keygen/jsonapi'
require_relative 'keygen/logger'
require_relative 'keygen/middleware'

module Keygen
  PUBLIC_KEY = %(\xB8\xF3\xEBL\xD2`\x13_g\xA5\tn\x8D\xC1\xC9\xB9\xDC\xB8\x1E\xE9\xFEP\xD1,\xDC\xD9A\xF6`z\x901).freeze
  VERSION    = '1.3.0'.freeze

  class << self
    def logger = Logger

    def console?   = Rails.const_defined?(:Console)
    def server?    = Rails.const_defined?(:Server) || puma?
    def test?      = Rails.env.test?
    def worker?    = sidekiq?
    def task?(...) = rake?(...)

    def multiplayer?(strict: true) = ENV['KEYGEN_MODE'] == 'multiplayer' && (!strict || !!ee { _1.entitled?(:multiplayer) })
    def singleplayer?(...)         = !multiplayer?(...)

    def ee? = ENV['KEYGEN_EDITION'] == 'EE'
    def ce? = !ee?

    def mode    = multiplayer? ? 'multiplayer' : 'singleplayer'
    def edition = ee? ? 'EE' : 'CE'
    def version = VERSION

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

    def puma?    = Puma.const_defined?(:Server) && $0.ends_with?('puma')
    def sidekiq? = Sidekiq.const_defined?(:CLI)

    def rake?(*tasks)
      Rake.respond_to?(:application) && Rake.application.top_level_tasks.any? { |task|
        tasks.all? { task.starts_with?(_1) }
      }
    end
  end
end
