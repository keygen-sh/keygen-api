# frozen_string_literal: true

class ReleaseManifest < ApplicationRecord
  include Keygen::PortableClass
  include Environmental
  include Accountable
  include Limitable
  include Orderable
  include Pageable

  belongs_to :artifact,
    class_name: 'ReleaseArtifact',
    foreign_key: :release_artifact_id,
    inverse_of: :manifest
  belongs_to :release,
    inverse_of: :manifest,
    default: -> { artifact&.release }
  belongs_to :package,
    class_name: 'ReleasePackage',
    foreign_key: :release_package_id,
    inverse_of: :manifests,
    default: -> { release&.package }
  belongs_to :engine,
    class_name: 'ReleaseEngine',
    foreign_key: :release_engine_id,
    inverse_of: :manifests,
    default: -> { release&.engine }
  has_one :product,
    through: :release

  has_environment default: -> { artifact&.environment_id }
  has_account default: -> { artifact&.account_id }
end
