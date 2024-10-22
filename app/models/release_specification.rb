# frozen_string_literal: true

class ReleaseSpecification < ApplicationRecord
  MIN_CONTENT_LENGTH = 5.bytes     # to avoid processing empty or invalid specs
  MAX_CONTENT_LENGTH = 5.megabytes # to avoid downloading large specs

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

  # scope :waiting,    -> { joins(:artifact).where(release_artifacts: { status: 'WAITING' }) }
  # scope :processing, -> { joins(:artifact).where(release_artifacts: { status: 'PROCESSING' }) }
  # scope :uploaded,   -> { joins(:artifact).where(release_artifacts: { status: 'UPLOADED' }) }
  # scope :failed,     -> { joins(:artifact).where(release_artifacts: { status: 'FAILED' }) }

  # scope :draft,      -> { joins(:release).where(releases: { status: 'DRAFT' }) }
  # scope :published,  -> { joins(:release).where(releases: { status: 'PUBLISHED' }) }
  # scope :yanked,     -> { joins(:release).where(releases: { status: 'YANKED' }) }

  # scope :for_channel_key, -> key { joins(artifact: :channel).where(release_channels: { key: }) }
  # scope :stable, -> { for_channel_key(%i(stable)) }
  # scope :rc, -> { for_channel_key(%i(stable rc)) }
  # scope :beta, -> { for_channel_key(%i(stable rc beta)) }
  # scope :alpha, -> { for_channel_key(%i(stable rc beta alpha)) }
  # scope :dev, -> { for_channel_key(%i(dev)) }

  # scope :order_by_version, -> {
  #   joins(:release).reorder(<<~SQL.squish)
  #     releases.semver_major             DESC,
  #     releases.semver_minor             DESC NULLS LAST,
  #     releases.semver_patch             DESC NULLS LAST,
  #     releases.semver_pre_word          DESC NULLS FIRST,
  #     releases.semver_pre_num           DESC NULLS LAST,
  #     releases.semver_build_word        DESC NULLS LAST,
  #     releases.semver_build_num         DESC NULLS LAST,
  #     release_specifications.created_at DESC
  #   SQL
  # }
end
