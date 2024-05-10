# frozen_string_literal: true

namespace :keygen do
  desc 'Setup Keygen and the environment'
  task setup: %i[environment db:schema:load db:migrate db:seed] do |_, args|
    require 'io/console'

    def tty!      = STDIN.tty? || abort('Setup requires stdin to be a TTY')
    def getp(...) = tty! && STDIN.getpass(...)&.chomp
    def gets(...) = tty! && STDIN.gets(...)&.chomp

    ActiveRecord::Base.logger.silence do
      edition = (args.extras[0] || ENV.fetch('KEYGEN_EDITION') { 'CE' }).upcase
      mode    = (args.extras[1] || ENV.fetch('KEYGEN_MODE')    { 'singleplayer' }).downcase
      config  = {}

      unless ENV.key?('NO_SECRETS')
        config['SECRET_KEY_BASE']                = ENV.fetch('SECRET_KEY_BASE')
        config['ENCRYPTION_DETERMINISTIC_KEY']   = ENV.fetch('ENCRYPTION_DETERMINISTIC_KEY')
        config['ENCRYPTION_PRIMARY_KEY']         = ENV.fetch('ENCRYPTION_PRIMARY_KEY')
        config['ENCRYPTION_KEY_DERIVATION_SALT'] = ENV.fetch('ENCRYPTION_KEY_DERIVATION_SALT')
      end

      config['KEYGEN_EDITION'] = edition
      config['KEYGEN_MODE']    = mode
      config['KEYGEN_HOST']    = ENV.fetch('KEYGEN_HOST') {
        print 'Enter your domain name (e.g. licensing.example.com): '
        gets
      }

      case edition
      when 'CE'
        puts 'Setting up CE edition...'
      when 'EE'
        puts 'Setting up EE edition...'

        config['KEYGEN_LICENSE_FILE_PATH'] = '/etc/keygen/ee.lic'
        config['KEYGEN_LICENSE_KEY']       = ENV.fetch('KEYGEN_LICENSE_KEY') {
          print 'Enter your EE license key: '
          gets
        }
      else
        abort "Invalid edition: #{edition}"
      end

      case mode
      when 'singleplayer'
        puts 'Setting up singleplayer mode...'

        id = ENV.fetch('KEYGEN_ACCOUNT_ID') {
          print 'Choose an account ID (leave blank for default): '
          gets
        }

        email = ENV.fetch('KEYGEN_ADMIN_EMAIL') {
          print 'Choose a primary email: '
          gets
        }

        password = ENV.fetch('KEYGEN_ADMIN_PASSWORD') {
          print 'Choose a password: '
          getp
        }

        account = Account.create!(
          billing_attributes: { state: 'subscribed' },
          users_attributes: [{ email:, password: }],
          plan_attributes: { name: 'Ent 0', price: 1 },
          protected: true,
          id:,
        )

        config['KEYGEN_ACCOUNT_ID'] = account.id
      when 'multiplayer'
        puts 'Setting up multiplayer mode...'

        unless edition == 'EE'
          abort "Multiplayer mode is not supported in CE"
        end

        Account.transaction do
          print 'Choose an account ID (leave blank for default): '
          id = gets

          print 'Choose a primary email: '
          email = gets

          print 'Choose a password: '
          password = getp

          account = Account.create!(
            billing_attributes: { state: 'subscribed' },
            users_attributes: [{ email:, password: }],
            plan_attributes: { name: 'Ent 0', price: 1 },
            protected: true,
            id:,
          )

          print 'Would you like to create another account? y/N '
          answer = gets

          if answer.downcase == 'y'
            redo
          end
        end
      else
        abort "Invalid mode: #{mode}"
      end

      puts <<~MSG
        To complete setup, run the following in a shell, or add it to a shell profile:

          #{config.reduce(+'') { |s, (k, v)| s << "export #{k}=#{v}\n  " }.strip.chomp}

      MSG

      if mode == 'singleplayer'
        puts <<~MSG
          In addition, you may want to keep track of the following information:

            Account ID: #{account.id}
            Account slug: #{account.slug}
            Admin email: #{account.email}

        MSG
      end

      puts <<~MSG
        Then run the following to start the server:

          rails s

        *keygen music intensifies*
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
