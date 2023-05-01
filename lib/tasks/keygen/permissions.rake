# frozen_string_literal: true

namespace :keygen do
  desc 'Tasks for managing permissions'
  namespace :permissions do
    desc 'Tasks for managing admin permissions'
    namespace :admins do
      desc 'Add a new set of permissions to all admins with default permissions'
      task add: %i[environment] do |_, args|
        batch_size  = ENV.fetch('BATCH_SIZE') { 1_000 }.to_i
        batch_wait  = ENV.fetch('BATCH_WAIT') { 0.1 }.to_f
        permissions = args.extras
        admins      = User.includes(:account, role: { role_permissions: :permission })
                          .where(role: {
                            name: %i[admin read_only developer support_agent sales_agent],
                          })

        Keygen.logger.info { "Adding #{permissions.join(',')} permissions to #{admins.count} admins..." }

        admins.find_each(batch_size:).with_index do |user, i|
          # NOTE(ezekg) Use preloaded permissions to save on superfluous queries.
          prev_permissions = user.role_permissions.map { _1.permission.action }

          unless user.default_permissions?(except: permissions, with: prev_permissions)
            Keygen.logger.info { "[#{i}] Skipping #{user.id}..." }

            next
          end

          next_permissions = prev_permissions + (permissions & user.allowed_permissions)

          if next_permissions.any?
            new_permissions = next_permissions - prev_permissions

            Keygen.logger.info { "[#{i}] Adding #{new_permissions.join(',')} permissions to #{user.id}..." }

            user.update!(
              permissions: next_permissions,
            )
          else
            Keygen.logger.info { "[#{i}] Nothing to add to #{user.id}..." }
          end

          sleep batch_wait
        end
      end
    end
  end
end
