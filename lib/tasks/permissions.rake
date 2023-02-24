# frozen_string_literal: true

desc 'tasks for managing permissions'
namespace :permissions do
  desc 'tasks for managing user permissions'
  namespace :users do
    desc 'add a new set of permissions to all users with default permissions'
    task add: %i[environment] do |_, args|
      permission_actions = args.extras
      permission_ids     = Permission.where(action: permission_actions)
                                     .ids

      User.find_each.with_index do |user, i|
        next unless
          user.default_permissions?(except: permission_ids)

        puts "[#{i}] #{user.role.name.capitalize} #{user.email} has default permissions"

        if (permission_ids & user.allowed_permission_ids).any?
          puts "  => Adding to permission set..."
        else
          puts "  => Skipping..."
        end
      end
    end
  end
end
