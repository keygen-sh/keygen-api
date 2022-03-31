# frozen_string_literal: true

class ReleaseFiletype < ApplicationRecord
  include Limitable
  include Orderable
  include Pageable

  belongs_to :account,
    inverse_of: :release_filetypes
  has_many :releases,
    inverse_of: :filetype

  validates :key,
    presence: true,
    uniqueness: { message: 'already exists', scope: :account_id }
end
