# frozen_string_literal: true

class ReleaseSpecification < ApplicationRecord
  include Keygen::PortableClass
  include Environmental
  include Accountable
  include Limitable
  include Orderable
  include Pageable

  belongs_to :artifact,
    class_name: 'ReleaseArtifact',
    foreign_key: :release_artifact_id,
    inverse_of: :specification
  belongs_to :release,
    inverse_of: :specification
  has_one :product,
    through: :release
  has_one :package,
    through: :release
  has_one :engine,
    through: :package

  has_environment default: -> { artifact&.environment_id }
  has_account default: -> { artifact&.account_id }

  validates :artifact,
    uniqueness: { message: 'already exists', scope: %i[release_artifact_id] },
    scope: { by: :account_id }

  validates :release,
    uniqueness: { message: 'already exists', scope: %i[release_id] },
    scope: { by: :account_id }

  # assert that release matches the artifact's release
  validate on: %i[create update] do
    next unless
      release_artifact_id_changed? || release_id_changed?

    unless artifact.nil? || artifact.release_id == release_id
      errors.add :release, :not_allowed, message: 'release must match artifact release'
    end
  end
end
