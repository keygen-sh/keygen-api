# frozen_string_literal: true

namespace :keygen do
  desc 'Tasks for managing permissions'
  namespace :permissions do
    task :add, %i[type] => %i[environment] do |_, args|
      batch_size = ENV.fetch('BATCH_SIZE') { 1_000 }.to_i
      batch_wait = ENV.fetch('BATCH_WAIT') { 0.1 }.to_f

      model = args[:type].to_s.classify.safe_constantize

      # Split args up into ID and permission buckets.
      new_permissions,
      record_ids =
        args.extras.flatten.partition { Permission::ALL_PERMISSIONS.include?(_1) }

      records = model.includes(:account, role: { role_permissions: :permission })
                     .where(id: record_ids)

      records.find_each(batch_size:) do |record|
        # Use preloaded permissions to save on superfluous queries.
        prev_permissions = record.role_permissions.map { _1.permission.action }

        # We only want to add new permissions to records that have the default
        # permission set, i.e. not to records with a custom permission set.
        unless record.default_permissions?(except: new_permissions, with: prev_permissions)
          Keygen.logger.info { "Skipping #{record.id}..." }

          next
        end

        next_permissions = prev_permissions + (new_permissions & record.allowed_permissions)

        if next_permissions.any?
          diff_permissions = next_permissions - prev_permissions

          Keygen.logger.info { "Adding #{diff_permissions.join(',')} permissions to #{record.id}..." }

          record.update!(
            permissions: next_permissions,
          )
        else
          Keygen.logger.info { "Nothing to add to #{record.id}..." }
        end

        sleep batch_wait
      rescue ActiveRecord::RecordInvalid => e
        Keygen.logger.info { "Failed #{record.id}: #{e.message}" }
      end
    end

    desc 'Tasks for managing admin permissions'
    namespace :admins do
      desc 'Add a new set of permissions to all admins with default permissions'
      task add: %i[environment] do |_, args|
        batch_size = ENV.fetch('BATCH_SIZE') { 1_000 }.to_i

        permissions = args.extras
        admins      = User.joins(:role)
                          .where(role: {
                            name: %i[admin read_only developer support_agent sales_agent],
                          })

        Keygen.logger.info { "Adding #{permissions.join(',')} permissions to #{admins.count} admins..." }

        admins.in_batches(of: batch_size).each do |batch|
          Rake::Task['keygen:permissions:add'].invoke(User.name, *batch.ids, *permissions)
        end

        Keygen.logger.info { 'Done' }
      end
    end

    desc 'Tasks for managing environment permissions'
    namespace :environments do
      desc 'Add a new set of permissions to all environments with default permissions'
      task add: %i[environment] do |_, args|
        batch_size = ENV.fetch('BATCH_SIZE') { 1_000 }.to_i

        permissions  = args.extras
        environments = Environment.all

        Keygen.logger.info { "Adding #{permissions.join(',')} permissions to #{environments.count} environments..." }

        environments.in_batches(of: batch_size).each do |batch|
          Rake::Task['keygen:permissions:add'].invoke(Environment.name, *batch.ids, *permissions)
        end

        Keygen.logger.info { 'Done' }
      end
    end

    desc 'Tasks for managing product permissions'
    namespace :products do
      desc 'Add a new set of permissions to all products with default permissions'
      task add: %i[environment] do |_, args|
        batch_size = ENV.fetch('BATCH_SIZE') { 1_000 }.to_i

        permissions = args.extras
        products    = Product.all

        Keygen.logger.info { "Adding #{permissions.join(',')} permissions to #{products.count} products..." }

        products.in_batches(of: batch_size).each do |batch|
          Rake::Task['keygen:permissions:add'].invoke(Product.name, *batch.ids, *permissions)
        end

        Keygen.logger.info { 'Done' }
      end
    end

    desc 'Tasks for managing license permissions'
    namespace :licenses do
      desc 'Add a new set of permissions to all licenses with default permissions'
      task add: %i[environment] do |_, args|
        batch_size = ENV.fetch('BATCH_SIZE') { 1_000 }.to_i

        permissions = args.extras
        licenses    = License.all

        Keygen.logger.info { "Adding #{permissions.join(',')} permissions to #{licenses.count} licenses..." }

        licenses.in_batches(of: batch_size).each do |batch|
          Rake::Task['keygen:permissions:add'].invoke(License.name, *batch.ids, *permissions)
        end

        Keygen.logger.info { 'Done' }
      end
    end

    desc 'Tasks for managing user permissions'
    namespace :users do
      desc 'Add a new set of permissions to all users with default permissions'
      task add: %i[environment] do |_, args|
        batch_size = ENV.fetch('BATCH_SIZE') { 1_000 }.to_i

        permissions = args.extras
        users       = User.joins(:role).where(role: { name: %i[user] })

        Keygen.logger.info { "Adding #{permissions.join(',')} permissions to #{users.count} users..." }

        users.in_batches(of: batch_size).each do |batch|
          Rake::Task['keygen:permissions:add'].invoke(User.name, *batch.ids, *permissions)
        end

        Keygen.logger.info { 'Done' }
      end
    end
  end
end
