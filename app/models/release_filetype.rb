# frozen_string_literal: true

class ReleaseFiletype < ApplicationRecord
  include Accountable
  include Limitable
  include Orderable
  include Pageable

  has_many :artifacts,
    class_name: 'ReleaseArtifact',
    inverse_of: :filetype
  has_many :releases,
    through: :artifacts

  has_account inverse_of: :release_filetypes

  validates :key,
    presence: true,
    uniqueness: { message: 'already exists', scope: :account_id }

  before_create -> { self.key = key.downcase.strip }

  scope :for_environment, -> environment, strict: false {
    joins(:artifacts)
      .reorder(created_at: DEFAULT_SORT_ORDER)
      .where(
        artifacts: ReleaseArtifact.where('release_artifacts.account_id = release_filetypes.account_id')
                                  .for_environment(environment, strict:),
      )
      .distinct
  }
end
