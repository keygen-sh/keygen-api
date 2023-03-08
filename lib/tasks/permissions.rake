# frozen_string_literal: true

desc 'tasks for managing permissions'
namespace :permissions do
  desc 'tasks for managing user permissions'
  namespace :users do
    desc 'add a new set of permissions to all users with default permissions'
    task add: %i[environment] do |_, args|
      sleep_duration = ENV.fetch('SLEEP_DURATION') { 0.1 }.to_f
      batch_size     = ENV.fetch('BATCH_SIZE') { 1_000 }.to_i
      permissions    = args.extras

      Keygen.logger.info { "Adding #{permissions} permissions to #{User.count} users..." }

      User.preload(role: { role_permissions: :permission })
          .find_each(batch_size:)
          .with_index do |user, i|
        next unless
          user.default_permissions?(
            except: permissions,
            # NOTE(ezekg) Use preloaded permissions to save on superfluous queries.
            with: user.role_permissions.map { _1.permission.action },
          )

        next_permissions = permissions & user.allowed_permissions

        Keygen.logger.info { "[#{i}] #{user.role.name.humanize} #{user.email} has default permissions" }

        if next_permissions.any?
          Keygen.logger.info { "  => Adding #{next_permissions.size} to permission set..." }

          user.update!(
            permissions: next_permissions,
          )
        else
          Keygen.logger.info { "  => Skipping..." }
        end

        sleep sleep_duration
      end
    end
  end
end
