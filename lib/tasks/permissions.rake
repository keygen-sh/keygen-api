# frozen_string_literal: true

desc 'tasks for managing permissions'
namespace :permissions do
  desc 'tasks for managing user permissions'
  namespace :admins do
    desc 'add a new set of permissions to all admins with default permissions'
    task add: %i[environment] do |_, args|
      sleep_duration = ENV.fetch('SLEEP_DURATION') { 0.1 }.to_f
      batch_size     = ENV.fetch('BATCH_SIZE') { 1_000 }.to_i
      permissions    = args.extras
      admins         = User.includes(role: { role_permissions: :permission })
                           .where(role: {
                             name: %i[admin read_only support_agent sales_agent],
                           })

      Keygen.logger.info { "Adding #{permissions} permissions to #{admins.count} admins..." }

      admins.find_each(batch_size:).with_index do |user, i|
        next Keygen.logger.info { "[#{i}] Skipping #{user.id}..." } unless
          user.default_permissions?(
            except: permissions,
            # NOTE(ezekg) Use preloaded permissions to save on superfluous queries.
            with: user.role_permissions.map { _1.permission.action },
          )

        next_permissions = permissions & user.allowed_permissions

        if next_permissions.any?
          Keygen.logger.info { "[#{i}] Adding #{next_permissions.join(',')} permissions to #{user.id}..." }

          user.update!(
            permissions: next_permissions,
          )
        else
          Keygen.logger.info { "[#{i}] Nothing to add to #{user.id}..." }
        end

        sleep sleep_duration
      end
    end
  end
end
