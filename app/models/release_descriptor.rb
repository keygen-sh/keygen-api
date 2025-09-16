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

  validates :content_path,
    length: { maximum: 4.kilobytes }

  validates :metadata,
    json: {
      maximum_bytesize: 16.kilobytes,
      maximum_depth: 4,
      maximum_keys: 64,
    }

  # assert that release matches the artifact's release
  validate on: %i[create update] do
    next unless
      release_artifact_id_changed? || release_id_changed?

    unless artifact.nil? || artifact.release_id == release_id
      errors.add :release, :not_allowed, message: 'release must match artifact release'
    end
  end

  scope :accessible_by, -> accessor {
    case accessor
    in role: Role(:admin)
      all
    in role: Role(:environment)
      for_environment(accessor.id)
    in role: Role(:product)
      for_product(accessor.id)
    in role: Role(:license)
      for_license(accessor.id).published
                              .uploaded
    in role: Role(:user)
      for_user(accessor.id).published
                            .uploaded
    else
      open.without_constraints
          .published
          .uploaded
    end
  }

  scope :for_product, -> product {
    case product
    in UUID_RE => product_id
      joins(:product).where(product: { id: product_id })
    in Product => product
      joins(:product).where(product:)
    in String => code
      joins(:product).where(product: { code: })
    else
      none
    end
  }

  scope :for_user, -> user {
    # Collect manifests for each of the user's licenses. This is the only way
    # we can ensure we scope to exactly what the user has access to, e.g.
    # when taking into account expiration and distribution strategies,
    # as well as entitlements per-license.
    scopes = License.preload(:policy)
                    .for_user(user)
                    .collect do |license|
      # Users should only be able to access manifests with constraints
      # intersecting their entitlements, or no constraints at all.
      scope = within_constraints(license.entitlement_codes, strict: true)

      # Users should only be able to access manifests within their licenses'
      # expiration windows, i.e. not manifests of releases published after
      # their licenses' expiration dates.
      scope = scope.within_expiry_for(license)

      scope.joins(release: { product: %i[licenses] })
            .reorder("#{table_name}.created_at": DEFAULT_SORT_ORDER)
            .where(
              product: { distribution_strategy: ['LICENSED', 'OPEN', nil] },
              licenses: { id: license },
            )
    end

    # Combine all scopes into a single query via UNIONs
    scope = scopes.reduce(&:union) || none

    scope.union(
            open.without_constraints
                .published
                .uploaded,
          )
          .reorder(
            "#{table_name}.created_at": DEFAULT_SORT_ORDER,
          )
  }

  scope :for_license, -> license {
    license = case license
              when UUID_RE
                License.find(license)
              else
                license
              end

    # Licenses should only be able to access manifests with constraints
    # intersecting their entitlements, or no constraints at all.
    scope = within_constraints(license.entitlement_codes, strict: true)

    # Licenses should only be able to access manifests within their
    # expiration window, i.e. not manifests of releases published
    # after the license's expiration date.
    scope = scope.within_expiry_for(license)

    scope.joins(release: { product: %i[licenses] })
          .where(
            product: { distribution_strategy: ['LICENSED', 'OPEN', nil] },
            licenses: { id: license },
          )
          .union(
            open.without_constraints
                .published
                .uploaded,
          )
          .reorder(
            "#{table_name}.created_at": DEFAULT_SORT_ORDER,
          )
  }

  scope :licensed, -> { joins(release: :product).where(product: { distribution_strategy: ['LICENSED', nil] }) }
  scope :open,     -> { joins(release: :product).where(product: { distribution_strategy: 'OPEN' }) }
  scope :closed,   -> { joins(release: :product).where(product: { distribution_strategy: 'CLOSED' }) }

  ##
  # without_constraints returns manifests without any release entitlement constraints.
  scope :without_constraints, -> {
    where_assoc_not_exists([:release, :constraints])
  }

  ##
  # with_constraints returns manifests with release entitlement constraints.
  scope :with_constraints, -> {
    where_assoc_exists([:release, :constraints])
  }

  ##
  # within_constraints returns manifests with specific release entitlement constraints.
  #
  # See Release.within_constraints for a detailed explanation.
  scope :within_constraints, -> *codes, strict: false {
    codes = codes.flatten
                  .compact_blank
                  .uniq

    return without_constraints if
      codes.empty?

    scp = joins(release: { constraints: :entitlement })
    scp = if strict
            agg = scp.reorder("#{table_name}.created_at": DEFAULT_SORT_ORDER)
                      .group(:id)

            agg.having(<<~SQL.squish, codes:)
              count(release_entitlement_constraints) = count(entitlements) filter (
                where entitlements.code in (:codes)
              )
            SQL
          else
            scp.where(entitlements: { code: codes })
          end

    scp.union(without_constraints)
        .reorder(
          "#{table_name}.created_at": DEFAULT_SORT_ORDER,
        )
  }

  scope :within_expiry_for, -> license {
    return none if license.nil?
    return all  unless license.expires?

    case
    when license.revoke_access?
      license.expired? ? none : all
    when license.restrict_access?,
         license.maintain_access?
      joins(:release).where(releases: { created_at: ..license.expiry }).or(
        joins(:release).where(releases: { backdated_to: ..license.expiry }),
      )
    when license.allow_access?
      all
    else
      none
    end
  }

  scope :waiting,    -> { joins(:artifact).where(release_artifacts: { status: 'WAITING' }) }
  scope :processing, -> { joins(:artifact).where(release_artifacts: { status: 'PROCESSING' }) }
  scope :uploaded,   -> { joins(:artifact).where(release_artifacts: { status: 'UPLOADED' }) }
  scope :failed,     -> { joins(:artifact).where(release_artifacts: { status: 'FAILED' }) }

  scope :draft,     -> { joins(:release).where(releases: { status: 'DRAFT' }) }
  scope :published, -> { joins(:release).where(releases: { status: 'PUBLISHED' }) }
  scope :yanked,    -> { joins(:release).where(releases: { status: 'YANKED' }) }
  scope :unyanked,  -> { joins(:release).where.not(releases: { status: 'YANKED' }) }

  def client = artifact.client
  def bucket = artifact.bucket
  def key    = artifact.key_for(content_path)

  def download!(**) = artifact.download!(**, path: content_path)
end
