# frozen_string_literal: true

class Permission < ApplicationRecord
  has_many :role_permissions
  has_many :token_permissions
  has_many :group_permissions
end
