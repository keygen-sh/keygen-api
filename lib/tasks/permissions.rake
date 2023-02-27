# frozen_string_literal: true

desc 'tasks for managing permissions'
namespace :permissions do
  desc 'tasks for managing user permissions'
  namespace :users do
    desc 'add a new set of permissions to all users with default permissions'
    task add: %i[environment] do |_, args|
      new_permission_actions = args.extras
      new_permission_ids     = Permission.where(action: new_permission_actions)
                                         .ids

      raise 'one or more permissions were not found' unless
        new_permission_actions.size == new_permission_ids.size

      puts "Adding #{new_permission_actions} permissions to #{User.count} users..."

      User.find_each.with_index do |user, i|
        next unless
          user.default_permissions?(except: new_permission_ids)

        permission_ids = new_permission_ids & user.allowed_permission_ids

        puts "[#{i}] #{user.role.name.humanize} #{user.email} has default permissions"

        if permission_ids.any?
          puts "  => Adding #{permission_ids.size} to permission set..."
        else
          puts "  => Skipping..."
        end
      end
    end
  end
end
