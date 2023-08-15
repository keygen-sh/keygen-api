# frozen_string_literal: true

module Keygen
  module Console
    extend self

    CONSOLE_WIDTH = 80
    LOGOMARK_PAD  = 20
    LOGOMARK      = <<~TXT.freeze
                                  -*%@@@#+:
                                :%@@@@@@@@@#
                                @@@@@@@@@@@@#
                                :@@@@@@@@@@@@@
                                #@@@@@@@@@@@+
                                  +@@@@@@@@%=
                        ::::        -+**+=:
                    -#@@@@@@#=
                    #@@@@@@@@@@#.
                  +@@@@@@@@@@@@+
                  +@@@@@@@@@@@@#
                    #@@@@@@@@@@@@=
                    =%@@@@@@@@@@@*:
        :=+*+=-       .:--=+%@@@@@@@#**+=:
      -%@@@@@@@@*            :#@@@@@@@@@@@%=
      =@@@@@@@@@@@%             *@@@@@@@@@@@@+
      @@@@@@@@@@@@@-            -@@@@@@@@@@@@@
      #@@@@@@@@@@@@.             @@@@@@@@@@@@#
      #@@@@@@@@@%-              :%@@@@@@@@@#.
        :+#@@@%*-                  -*%@@@#+:
    TXT

    def about!
      puts '-' * CONSOLE_WIDTH
      puts
      puts LOGOMARK.lines.map { ' ' * LOGOMARK_PAD + _1 }.join
      puts
      puts '-' * CONSOLE_WIDTH
      puts " Ruby: #{RUBY_DESCRIPTION}"
      puts " Rails: #{Rails.version} #{Rails.env} (RubyGems #{Gem::VERSION}, Rack #{Rack.release})"
      puts " Keygen: #{Keygen.version} (#{Keygen.edition}, #{Keygen.mode})"
      Keygen.ee do |key, lic|
        puts "   License: #{key.name || 'Unnamed'} (#{key.id})"
        puts "   Entitlements: #{key.entitlements.join(', ')}"
        puts "   Environment: #{lic.environment || 'nil'}"
        puts "   Expiry: #{key.expiry || 'None'}"
        puts "   Reup: #{lic.expiry || 'None'}"
      end
      puts '-' * CONSOLE_WIDTH
    end

    def welcome!
      return unless
        Keygen.server? || Keygen.worker?

      about!
      warn!
      err!
    end

    def warn!
      Keygen.ee do |key, lic|
        case
        when key.expiring?
          puts
          warn '!' * CONSOLE_WIDTH
          warn "Your Keygen EE license key is expiring in #{helpers.time_ago_in_words(key.expiry)}! Please renew soon.".center(CONSOLE_WIDTH)
          warn '!' * CONSOLE_WIDTH
          puts
        when key.expired?
          puts
          warn '!' * CONSOLE_WIDTH
          warn "Your Keygen EE license key expired #{helpers.time_ago_in_words(key.expiry)} ago! Please renew.".center(CONSOLE_WIDTH)
          warn '!' * CONSOLE_WIDTH
          puts
        when lic.expiring?
          puts
          warn '!' * CONSOLE_WIDTH
          warn "Your Keygen EE license file is expiring in #{helpers.time_ago_in_words(lic.expiry)}! Please reup soon.".center(CONSOLE_WIDTH)
          warn '!' * CONSOLE_WIDTH
          puts
        when lic.expired?
          puts
          warn '!' * CONSOLE_WIDTH
          warn "Your Keygen EE license file expired #{helpers.time_ago_in_words(lic.expiry)} ago! Please reup.".center(CONSOLE_WIDTH)
          warn '!' * CONSOLE_WIDTH
          puts
        end
      end
    end

    # This will raise if either the license or license file are expired
    # and past the expiry grace period, or otherwise tampered with.
    #
    # FIXME(ezekg) Eventually move this out into a boot/lifecycle
    #              system on the Keygen module?
    def err! = Keygen.ee { |key, lic| key.valid? && lic.valid? }

    private

    def helpers
      @helpers ||= Module.new { extend ActionView::Helpers::DateHelper }
    end
  end
end
