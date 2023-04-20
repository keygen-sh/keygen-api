# frozen_string_literal: true

namespace :keygen do
  desc 'Setup Keygen and the environment'
  task setup: %i[environment] do |_, args|
    require 'io/console'

    def getp(...) = STDIN.getpass(...).chomp
    def gets(...) = STDIN.gets(...).chomp

    edition = args.extras[0] || ENV.fetch('KEYGEN_EDITION') { 'CE' }.upcase
    mode    = args.extras[1] || ENV.fetch('KEYGEN_MODE')    { 'singleplayer' }.downcase
    config  = {}

    case edition
    when 'CE'
      puts 'Setting up CE edition...'

      config['KEYGEN_EDITION'] = edition
    when 'EE'
      puts 'Setting up EE edition...'

      license_key = ENV.fetch('KEYGEN_LICENSE_KEY') {
        print 'Enter your EE license key: '
        gets
      }

      config['KEYGEN_LICENSE_FILE_PATH'] = '/etc/keygen/ee.lic'
      config['KEYGEN_LICENSE_KEY']       = license_key
      config['KEYGEN_EDITION']           = edition
    else
      abort "Invalid edition: #{edition}"
    end

    case mode
    when 'singleplayer',
         nil
      puts 'Setting up singleplayer mode...'

      account_id = ENV.fetch('KEYGEN_ACCOUNT_ID') {
        print 'Enter an account ID: '
        gets
      }

      # TODO(ezekg) Create the account
      # TODO(ezekg) Admin setup

      config['KEYGEN_MODE']       = 'singleplayer'
      config['KEYGEN_ACCOUNT_ID'] = account_id
    when 'multiplayer'
      puts 'Setting up multiplayer mode...'

      unless edition == 'EE'
        abort "Multiplayer mode is not supported in CE"
      end

      # TODO(ezekg) Account and admin setup

      config['KEYGEN_MODE'] = 'multiplayer'
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
