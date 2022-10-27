# frozen_string_literal: true

module Keygen
  module Console
    extend self

    CONSOLE_WIDTH = 80
    LOGOMARK_PAD  = 13
    LOGOMARK      = <<~TXT.freeze
                        ...
                      .oooo*°°.
                     °oooooooooo**°..
                    *oooo*.°**oooooooo*°°.
                  .*oooo°      .°°*oooooooo*°°..
                 .ooooo.            ..°**ooooooo**°..
                °oooo*.                   .°°*ooooooo*.
               *oooo°                          .°oooo*
             .*oooo°                            .oooo°
            .ooooo.                             °oooo°
           °oooo*                               *oooo.
          *oooo°                                *ooo*.
        .ooooo°                                .oooo*
       °oooo*.                                 .oooo°
      °ooooo*°.                                °oooo°
      ..**ooooo**°.                            *oooo.
          .°*oooooo*°.                         *ooo*
              .°*oooooo*°.                 ..°*oooo*
                  .°*oooooo*°.          .°*oooooo*°.
                     .°*oooooo*°.   .°*oooooo*°..
                         .°*oooooo*oooooo*°.
                             .°*ooooo*°.
                                .°°..
    TXT

    def welcome!
      return if
        Keygen.console?

      puts '-' * CONSOLE_WIDTH
      puts
      puts LOGOMARK.lines.map { ' ' * LOGOMARK_PAD + _1 }.join
      puts
      puts '-' * CONSOLE_WIDTH
      puts " Ruby: #{RUBY_DESCRIPTION}"
      puts " Rails: #{Rails.version} (RubyGems #{Gem::VERSION}, Rack #{Rack.release})"
      puts " Keygen: #{Keygen::VERSION} (#{Keygen.ee? ? 'EE' : 'CE'})"
      Keygen.ee do |key, lic|
        puts "   License: #{key.name || 'Unnamed'} (#{key.id})"
        puts "   Entitlements: #{key.entitlements.join(', ')}"
        puts "   Expiry: #{key.expiry || 'None'}"
        puts "   Reup: #{lic.expiry || 'None'}"
      end
      puts " Env: #{Rails.env}"
      puts '-' * CONSOLE_WIDTH

      warn!
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

    private

    def helpers
      @helpers ||= Module.new { extend ActionView::Helpers::DateHelper }
    end
  end
end
