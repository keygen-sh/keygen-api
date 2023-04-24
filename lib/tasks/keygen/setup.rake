# frozen_string_literal: true

namespace :keygen do
  desc 'Setup Keygen and the environment'
  task setup: %i[environment] do |_, args|
    require 'io/console'

    def getp(...) = STDIN.getpass(...).chomp
    def gets(...) = STDIN.gets(...).chomp

    ActiveRecord::Base.logger.silence do
      edition = (args.extras[0] || ENV.fetch('KEYGEN_EDITION') { 'CE' }).upcase
      mode    = (args.extras[1] || ENV.fetch('KEYGEN_MODE')    { 'singleplayer' }).downcase
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

        id = ENV.fetch('KEYGEN_ACCOUNT_ID') {
          print 'Choose an account ID (leave blank for default): '
          gets
        }

        print 'Choose a primary email: '
        email = gets

        print 'Choose a password: '
        password = getp

        account = Account.create!(
          users_attributes: [{ email:, password: }],
          plan_attributes: { name: 'Ent 0' },
          id:,
        )

        config['KEYGEN_MODE']       = 'singleplayer'
        config['KEYGEN_ACCOUNT_ID'] = account.id
      when 'multiplayer'
        puts 'Setting up multiplayer mode...'

        unless edition == 'EE'
          abort "Multiplayer mode is not supported in CE"
        end

        # TODO(ezekg) Allow multiple accounts to be created in a transaction?
        Account.transaction do
          print 'Choose an account ID (leave blank for default): '
          id = gets

          print 'Choose a primary email: '
          email = gets

          print 'Choose a password: '
          password = getp

          account = Account.create!(
            users_attributes: [{ email:, password: }],
            plan_attributes: { name: 'Ent 0' },
            id:,
          )

          print 'Would you like to create another account? y/N '
          answer = gets

          if answer.downcase == 'y'
            redo
          end
        end

        config['KEYGEN_MODE'] = 'multiplayer'
      else
        abort "Invalid mode: #{mode}"
      end

      puts <<~MSG
        To complete setup, run the following in a shell, or add it to a shell profile:

          #{config.reduce(+'') { |s, (k, v)| s << "export #{k}=#{v}\n  " }.strip.chomp}

        In addition, you may want to keep track of the following information:

          Account ID: #{account.id}
          Account slug: #{account.slug}
          Admin email: #{account.email}

        Then run the following:

          rails s

        Happy hacking!
      MSG
    rescue ActiveRecord::RecordNotSaved,
           ActiveRecord::RecordInvalid => e
      errs = e.record.errors

      abort <<~MSG
        Please resolve the following errors before continuing:

          #{errs.reduce(+'') { |s, e| s << "#{e.full_message}\n  " }.strip.chomp}

        To continue, rerun this task.
      MSG
    end
  end
end
