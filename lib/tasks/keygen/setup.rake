# frozen_string_literal: true

namespace :keygen do
  desc 'Setup Keygen and the environment'
  task setup: %i[environment] do |_, args|
    require 'io/console'

    module Console
      refine Kernel do
        def getp(...) = STDIN.getpass(...).chomp
        def gets(...) = STDIN.gets(...).chomp
      end

      refine String do
        def black   = "\e[30m#{self}\e[0m"
        def red     = "\e[31m#{self}\e[0m"
        def green   = "\e[32m#{self}\e[0m"
        def brown   = "\e[33m#{self}\e[0m"
        def blue    = "\e[34m#{self}\e[0m"
        def magenta = "\e[35m#{self}\e[0m"
        def cyan    = "\e[36m#{self}\e[0m"
        def gray    = "\e[37m#{self}\e[0m"
        def yellow  = "\e[1;33m#{self}\e[0m"
      end
    end

    using Console

    edition = args.extras[0]&.upcase || 'CE'
    mode    = args.extras[1]&.downcase || 'singleplayer'
    config  = {}

    case edition
    when 'CE'
      puts 'Setting up CE edition...'

      config[:KEYGEN_EDITION] = edition
    when 'EE'
      puts 'Setting up EE edition...'

      print 'Enter your EE license key: '
      license_key = gets

      config[:KEYGEN_LICENSE_FILE_PATH] = '/etc/keygen/ee.lic'
      config[:KEYGEN_LICENSE_KEY]       = license_key
      config[:KEYGEN_EDITION]           = edition
    else
      abort "Invalid edition: #{edition}"
    end

    case mode
    when 'singleplayer',
         nil
      puts 'Setting up singleplayer mode...'

      print 'Enter an account ID: '
      account_id = gets

      # TODO(ezekg) Create the account
      # TODO(ezekg) Admin setup

      config[:KEYGEN_MODE]       = 'singleplayer'
      config[:KEYGEN_ACCOUNT_ID] = account_id
    when 'multiplayer'
      puts 'Setting up multiplayer mode...'

      unless edition == 'EE'
        abort "Multiplayer mode is not supported in CE"
      end

      # TODO(ezekg) Account and admin setup

      config[:KEYGEN_MODE] = 'multiplayer'
    else
      abort "Invalid mode: #{mode}"
    end

    puts
    puts <<~MSG
      To complete setup, run the following in a shell, or add it to a shell profile:

        #{config.reduce(+'') { |s, (k, v)| s << "export #{k}=#{v}\n  " }.strip.chomp}

      Then run the following:

        rails s

      Happy hacking!
    MSG
  end
end
