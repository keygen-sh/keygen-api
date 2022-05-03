# frozen_string_literal: true

class Release < ApplicationRecord
  # FIXME(ezekg) Drop these columns after they're moved to artifacts
  self.ignored_columns = %w[release_platform_id release_filetype_id filename filesize signature checksum]

  include Limitable
  include Orderable
  include Pageable
  include Diffable

  STATUSES = %w[
    DRAFT
    PUBLISHED
    YANKED
  ]

  belongs_to :account,
    inverse_of: :releases
  belongs_to :product,
    inverse_of: :releases
  has_many :users,
    through: :product
  has_many :licenses,
    through: :product
  belongs_to :channel,
    class_name: 'ReleaseChannel',
    foreign_key: :release_channel_id,
    inverse_of: :releases,
    autosave: true
  has_many :constraints,
    class_name: 'ReleaseEntitlementConstraint',
    inverse_of: :release,
    dependent: :delete_all,
    index_errors: true,
    autosave: true
  has_many :entitlements,
    through: :constraints,
    index_errors: true
  has_many :download_links,
    class_name: 'ReleaseDownloadLink',
    inverse_of: :release,
    dependent: :delete_all
  has_many :upgrade_links,
    class_name: 'ReleaseUpgradeLink',
    inverse_of: :release,
    dependent: :delete_all
  has_many :upload_links,
    class_name: 'ReleaseUploadLink',
    inverse_of: :release,
    dependent: :delete_all
  has_many :artifacts,
    class_name: 'ReleaseArtifact',
    inverse_of: :release,
    dependent: :delete_all
  has_many :filetypes,
    through: :artifacts
  has_many :platforms,
    through: :artifacts
  has_many :arches,
    through: :artifacts
  has_many :event_logs,
    as: :resource

  # FIXME(ezekg) For v1.0 backwards compatibility
  has_one :artifact,
    class_name: 'ReleaseArtifact',
    inverse_of: :release,
    dependent: :delete

  accepts_nested_attributes_for :constraints, limit: 20, reject_if: :reject_duplicate_associated_records_for_constraints
  accepts_nested_attributes_for :artifact
  accepts_nested_attributes_for :channel

  before_validation -> { self.status ||= 'DRAFT' }
  before_create :enforce_release_limit_on_account!

  validates :product,
    scope: { by: :account_id }

  validates :channel,
    scope: { by: :account_id }

  validates :version,
    presence: true,
    semver: true,
    uniqueness: {
      scope: %i[account_id product_id release_channel_id],
      message: 'version already exists',
    }

  validates :status,
    presence: true,
    inclusion: {
      message: 'unsupported status',
      in: STATUSES,
    }

  scope :for_product, -> product {
    where(product: product)
  }

  scope :for_user, -> user {
    joins(:users, :product)
      .where(
        product: { distribution_strategy: ['LICENSED', nil] },
        users: { id: user },
      )
      .union(
        self.open
      )
  }

  scope :for_license, -> license {
    # Should we be applying a LIMIT to these UNION'd queries?
    joins(:licenses, :product)
      .where(
        product: { distribution_strategy: ['LICENSED', nil] },
        licenses: { id: license },
      )
      .union(
        self.open
      )
  }

  scope :for_platform, -> platform {
    case platform
    when ReleasePlatform,
         UUID_RE
      where(platform: platform)
    else
      joins(:platform).where(platform: { key: platform.to_s })
    end
  }

  scope :for_filetype, -> filetype {
    case filetype
    when ReleaseFiletype,
         UUID_RE
      where(filetype: filetype)
    else
      joins(:filetype).where(filetype: { key: filetype.to_s })
    end
  }

  scope :for_channel, -> channel {
    key =
      case channel
      when UUID_RE
        # NOTE(ezekg) We need to obtain the key because e.g. alpha channel should
        #             also show releases for stable, rc and beta channels.
        joins(:channel).select('release_channels.key')
                       .where(channel: channel)
                       .first
                       .try(:key)
      when ReleaseChannel
        channel.key
      else
        channel.to_s
      end

    case key
    when 'stable'
      self.stable
    when 'rc'
      self.rc
    when 'beta'
      self.beta
    when 'alpha'
      self.alpha
    when 'dev'
      self.dev
    else
      self.none
    end
  }

  scope :for_channel_key, -> key { joins(:channel).where(channel: { key: key }) }
  scope :stable, -> { for_channel_key(%i(stable)) }
  scope :rc, -> { for_channel_key(%i(stable rc)) }
  scope :beta, -> { for_channel_key(%i(stable rc beta)) }
  scope :alpha, -> { for_channel_key(%i(stable rc beta alpha)) }
  scope :dev, -> { for_channel_key(%i(dev)) }

  scope :unyanked, -> { where(yanked_at: nil) }
  scope :yanked, -> { where.not(yanked_at: nil) }

  scope :licensed, -> { joins(:product).where(product: { distribution_strategy: ['LICENSED', nil] }) }
  scope :open, -> { joins(:product).where(product: { distribution_strategy: 'OPEN' }) }
  scope :closed, -> { joins(:product).where(product: { distribution_strategy: 'CLOSED' }) }

  scope :with_version, -> version { where(version: version) }
  scope :with_artifacts, -> { where.associated(:artifacts) }
  scope :without_artifacts, -> { where.missing(:artifacts) }
  scope :with_status, -> status {
    case status.to_s.upcase
    when 'YANKED'
      self.yanked
    when 'NOT_PUBLISHED',
         'DRAFT'
      self.unyanked.without_artifacts
    when 'PUBLISHED'
      self.unyanked.with_artifacts
    else
      self.none
    end
  }

  delegate :stable?, :pre_release?, :rc?, :beta?, :alpha?,
    to: :channel

  # FIXME(ezekg) For v1.0 backwards compatibility
  delegate :s3_object_key,
    to: :artifact

  # FIXME(ezekg) Setters for v1.0 backwards compatibility
  def platform=(key)
    assign_attributes(artifact_attributes: { platform_attributes: { key: } })
  end

  def filetype=(key)
    assign_attributes(artifact_attributes: { filetype_attributes: { key: } })
  end

  def filename=(filename)
    assign_attributes(artifact_attributes: { filename: })
  end

  def filesize=(filesize)
    assign_attributes(artifact_attributes: { filesize: })
  end

  def signature=(signature)
    assign_attributes(artifact_attributes: { signature: })
  end

  def checksum=(checksum)
    assign_attributes(artifact_attributes: { checksum: })
  end

  def yanked?
    yanked_at.present?
  end

  def semver
    Semverse::Version.new(version)
  rescue Semverse::InvalidVersionFormat
    nil
  end

  private

  def validate_associated_records_for_channel
    return unless
      channel.present?

    case
    when pre_release?
      errors.add(:version, :channel_invalid, message: "version does not match prerelease channel (expected x.y.z-#{channel.key}.n got #{semver})") if
        semver&.pre_release.nil? || !semver&.pre_release.starts_with?(channel.key)
    when stable?
      errors.add(:version, :channel_invalid, message: "version does not match stable channel (expected x.y.z got #{semver})") if
        semver&.pre_release.present?
    end

    # FIXME(ezekg) Performing a safe create_or_find_by so we don't poison
    #              our current transaction by using DB exceptions
    rows = ReleaseChannel.find_by_sql [<<~SQL.squish, { account_id:, key: channel.key.downcase.strip }]
      WITH ins AS (
        INSERT INTO "release_channels"
          (
            "account_id",
            "key",
            "created_at",
            "updated_at"
          )
        VALUES
          (
            :account_id,
            :key,
            current_timestamp(6),
            current_timestamp(6)
          )
        ON CONFLICT ("account_id", "key")
          DO NOTHING
        RETURNING
          *
      )
      SELECT
        *
      FROM
        ins

      UNION

      SELECT
        *
      FROM
        "release_channels"
      WHERE
        "release_channels"."account_id" = :account_id AND
        "release_channels"."key"        = :key
    SQL

    self.channel = rows.first
  end

  def validate_associated_records_for_constraints
    return if
      constraints.nil? || constraints.empty?

    constraints.each_with_index do |constraint, i|
      constraint.account = account if
        constraint.account.nil?

      next if
        constraint.valid?

      constraint.errors.each do |err|
        errors.import(err, attribute: "constraints[#{i}].#{err.attribute}")
      end
    end
  end

  def reject_duplicate_associated_records_for_constraints(attrs)
    return if
      new_record?

    constraints.exists?(attrs)
  end

  def enforce_release_limit_on_account!
    return unless account.trialing_or_free_tier?

    release_count = account.releases.count

    # TODO(ezekg) Add max_releases to plans
    release_limit = 10

    return if release_count.nil? ||
              release_limit.nil?

    if release_count >= release_limit
      errors.add :account, :release_limit_exceeded, message: "Your tier's release limit of #{release_limit.to_fs(:delimited)} has been reached for your account. Please upgrade to a paid tier and add a payment method at https://app.keygen.sh/billing."

      throw :abort
    end
  end
end
