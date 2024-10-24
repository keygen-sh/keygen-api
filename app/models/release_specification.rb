# frozen_string_literal: true

require 'rubygems/specification'

class ReleaseSpecification < ApplicationRecord
  MIN_CONTENT_LENGTH = 5.bytes     # to avoid storing empty or invalid specs
  MAX_CONTENT_LENGTH = 5.megabytes # to avoid storing large specs

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
    inverse_of: :specifications
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

  validates :content,
    length: { minimum: MIN_CONTENT_LENGTH, maximum: MAX_CONTENT_LENGTH },
    presence: true

  # assert that release matches the artifact's release
  validate on: %i[create update] do
    next unless
      release_artifact_id_changed? || release_id_changed?

    unless artifact.nil? || artifact.release_id == release_id
      errors.add :release, :not_allowed, message: 'release must match artifact release'
    end
  end

  def as_gemspec = Gem::Specification.from_yaml(content)
end
