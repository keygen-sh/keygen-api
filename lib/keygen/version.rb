# frozen_string_literal: true

require_relative './logger'

module Keygen
  VERSION = '1.7.0'.freeze

  module Version
    class << self
      def revision
        return @revision if defined? @revision

        @revision = from_environment || from_git || from_file
      end

      def version
        return @version if defined? @version

        @version = Gem::Version.new(VERSION)
      end

      private

      def from_environment = ENV['COMMIT_HASH'] || ENV['COMMIT_SHA'] || ENV['HEROKU_SLUG_COMMIT']

      def from_git
        commit = `git rev-parse HEAD --quiet 2>/dev/null`.chomp

        commit.presence
      rescue => e
        Keygen.logger.exception(e)

        nil
      end

      def from_file(path = Rails.root / 'VERSION')
        return nil unless File.exist?(path)

        ident = File.read(path).chomp

        ident[/\h{40}/, 0].presence
      rescue => e
        Keygen.logger.exception(e)

        nil
      end
    end
  end
end
