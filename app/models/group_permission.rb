# frozen_string_literal: true

class GroupPermission < ApplicationRecord
  include Keygen::Exportable

  belongs_to :group
  belongs_to :permission
end
