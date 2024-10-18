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
    inverse_of: :specification,
    default: -> { artifact&.release }
  belongs_to :package,
    class_name: 'ReleasePackage',
    foreign_key: :release_package_id,
    inverse_of: :specifications,
    default: -> { release&.package }
  belongs_to :engine,
    class_name: 'ReleaseEngine',
    foreign_key: :release_engine_id,
    inverse_of: :specifications,
    default: -> { package&.engine }
  has_one :product,
    through: :release

  has_environment default: -> { artifact&.environment_id }
  has_account default: -> { artifact&.account_id }
end
