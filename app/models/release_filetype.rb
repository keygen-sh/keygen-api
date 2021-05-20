# frozen_string_literal: true

class ReleaseFiletype < ApplicationRecord
  include Limitable
  include Pageable

  belongs_to :account,
    inverse_of: :release_filetypes
  has_many :releases,
    inverse_of: :filetype

  validates :account,
    presence: { message: 'must exist' }

  validates :key,
    presence: true,
    uniqueness: { message: 'already exists', scope: :account_id }
end
