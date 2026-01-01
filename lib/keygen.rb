# frozen_string_literal: true

require_relative 'keygen/console'
require_relative 'keygen/database'
require_relative 'keygen/ee'
require_relative 'keygen/error'
require_relative 'keygen/jsonapi'
require_relative 'keygen/logger'
require_relative 'keygen/middleware'
require_relative 'keygen/version'
require_relative 'keygen/portable_class'
require_relative 'keygen/exporter'
require_relative 'keygen/importer'
require_relative 'keygen/url_for'

module Keygen
  PUBLIC_KEY = %(\xB8\xF3\xEBL\xD2`\x13_g\xA5\tn\x8D\xC1\xC9\xB9\xDC\xB8\x1E\xE9\xFEP\xD1,\xDC\xD9A\xF6`z\x901).freeze
  EDITION    = ENV['KEYGEN_EDITION']
  MODE       = ENV['KEYGEN_MODE']
  HOST       = ENV['KEYGEN_HOST']

  # effective top-level domain + 1 e.g. keygen.sh
  DOMAIN = ENV.fetch('KEYGEN_DOMAIN') {
    domains = HOST.downcase.strip.split('.')[-2..-1]
    next if
      domains.blank?

    domains.join('.')
  }

  # subdomain e.g. api
  SUBDOMAIN = ENV.fetch('KEYGEN_SUBDOMAIN') {
    subdomains = HOST.downcase.strip.split('.')[0..-3]
    next if
      subdomains.blank?

    subdomains.join('.')
  }

  class << self
    def revision = Version.revision
    def version  = Version.version

    def database = Database
    def logger   = Logger

    def console?   = Rails.const_defined?(:Console)
    def server?    = Rails.const_defined?(:Server) || puma?
    def test?      = Rails.env.test?
    def worker?    = sidekiq?
    def task?(...) = rake?(...)

    def multiplayer?(strict: true) = ENV['KEYGEN_MODE'] == 'multiplayer' && (!strict || !!ee { it.entitled?(:multiplayer) })
    def singleplayer?(...)         = !multiplayer?(...)

    def ee?    = ENV['KEYGEN_EDITION'] == 'EE'
    def ce?    = !ee?
    def cloud? = ee? && multiplayer? && ENV['KEYGEN_HOST'] == 'api.keygen.sh'

    def mode    = multiplayer? ? 'multiplayer' : 'singleplayer'
    def edition = ee? ? 'EE' : 'CE'

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
        tasks.all? { task.starts_with?(it) }
      }
    end
  end

  class Portal
    extend UrlFor

    HOST   = ENV.fetch('KEYGEN_PORTAL_HOST') { "portal.#{DOMAIN}" }
    ORIGIN = "https://#{HOST}"

    def self.url_for(record_or_path = nil, **)
      case record_or_path
      in Account => account
        super(ORIGIN, path: account.slug, **)
      in String | Symbol => path
        super(ORIGIN, path:, **)
      else
        super(ORIGIN, **)
      end
    end
  end

  class Docs
    extend UrlFor

    HOST   = ENV.fetch('KEYGEN_DOCS_HOST') { "#{DOMAIN}" }
    ORIGIN = "https://#{HOST}"

    def self.url_for(topic = nil, **) = super("#{ORIGIN}/docs/api/", path: topic.presence, trailing_slash: true, **)
  end
end
