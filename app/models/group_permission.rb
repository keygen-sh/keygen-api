# frozen_string_literal: true

class GroupPermission < ApplicationRecord
  belongs_to :group
  belongs_to :permission
end
