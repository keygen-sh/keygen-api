# frozen_string_literal: true

class ReleaseFiletype < ApplicationRecord
  include Environmental
  include Limitable
  include Orderable
  include Pageable

  belongs_to :account,
    inverse_of: :release_filetypes
  has_many :artifacts,
    class_name: 'ReleaseArtifact',
    inverse_of: :filetype
  has_many :releases,
    through: :artifacts

  validates :key,
    presence: true,
    uniqueness: { message: 'already exists', scope: :account_id }

  before_create -> { self.key = key.downcase.strip }
end
