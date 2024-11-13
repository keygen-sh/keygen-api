# frozen_string_literal: true

require 'rubygems/specification'

class ReleaseManifest < ApplicationRecord
  MIN_CONTENT_LENGTH = 5.bytes     # to avoid storing empty or invalid manifests
  MAX_CONTENT_LENGTH = 5.megabytes # to avoid storing large manifests

  include Keygen::PortableClass
  include Environmental
  include Accountable

  belongs_to :artifact,
    class_name: 'ReleaseArtifact',
    foreign_key: :release_artifact_id,
    inverse_of: :manifest
  belongs_to :release,
    inverse_of: :manifests
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

  def as_gemspec      = Gem::Specification.from_yaml(content)
  def as_package_json = JSON.parse(content)

  def self.find_by_reference!(reference)
    base = joins(:release)

    base.where(content_digest: reference)
        .or(base.where(release: { version: reference }))
        .or(base.where(release: { tag: reference }))
        .take!
  end

  def self.find_by_reference(...)
    find_by_reference!(...)
  rescue ActiveRecord::RecordNotFound
    nil
  end
end
