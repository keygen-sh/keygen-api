# frozen_string_literal: true

class ReleaseDescriptor < ApplicationRecord
  include Keygen::PortableClass
  include Environmental
  include Accountable

  belongs_to :artifact,
    class_name: 'ReleaseArtifact',
    foreign_key: :release_artifact_id,
    inverse_of: :descriptors
  belongs_to :release,
    inverse_of: :descriptors
  has_one :product,
    through: :release
  has_one :package,
    through: :release
  has_one :engine,
    through: :package

  has_environment default: -> { artifact&.environment_id }
  has_account default: -> { artifact&.account_id }

  validates :artifact,
    scope: { by: :account_id }

  validates :release,
    scope: { by: :account_id }

  scope :for_artifacts, -> artifacts {
    joins(:artifact).where(artifact: { id: artifacts })
  }

  def client = artifact.client
  def bucket = artifact.bucket
  def key    = artifact.key_for(content_path)

  def download!(**) = artifact.download!(**, filename: content_path)
end
