# frozen_string_literal: true

class Release < ApplicationRecord
  include Limitable
  include Pageable
  include Diffable

  belongs_to :account,
    inverse_of: :releases
  belongs_to :product,
    inverse_of: :releases
  has_many :users,
    through: :product
  has_many :licenses,
    through: :product
  belongs_to :platform,
    class_name: 'ReleasePlatform',
    foreign_key: :release_platform_id,
    inverse_of: :releases,
    autosave: true,
    optional: true
  belongs_to :filetype,
    class_name: 'ReleaseFiletype',
    foreign_key: :release_filetype_id,
    inverse_of: :releases,
    autosave: true,
    optional: true
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
    through: :constraints
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
  has_one :artifact,
    class_name: 'ReleaseArtifact',
    inverse_of: :release,
    dependent: :delete

  accepts_nested_attributes_for :constraints, limit: 20, reject_if: :reject_duplicate_associated_records_for_constraints
  accepts_nested_attributes_for :platform
  accepts_nested_attributes_for :filetype
  accepts_nested_attributes_for :channel

  before_create :enforce_release_limit_on_account!

  validates :account,
    presence: { message: 'must exist' }
  validates :product,
    presence: { message: 'must exist' },
    scope: { by: :account_id }
  validates :filetype,
    presence: { message: 'must exist' },
    scope: { by: :account_id },
    unless: -> { filetype.nil? }
  validates :platform,
    presence: { message: 'must exist' },
    scope: { by: :account_id },
    unless: -> { platform.nil? }
  validates :channel,
    presence: { message: 'must exist' },
    scope: { by: :account_id }

  validates :version,
    presence: true,
    semver: true,
    uniqueness: {
      # This error scenario is one of our most confusing, so we're giving as
      # much context as possible to the end-user.
      scope: %i[account_id product_id release_platform_id release_channel_id release_filetype_id],
      message: proc { |release|
        filetype = release.filetype.key
        platform = release.platform.key
        channel  = release.channel.key

        # We're going to remove % chars since Rails treats these special,
        # e.g. %{value}.
        "version already exists for '#{platform}' platform with '#{filetype}' filetype on '#{channel}' channel".remove('%')
      },
      # We only want to assert this validation if the filetype and platform
      # are present, since the unique index doesn't include nulls, and we
      # want to allow duplicates when these attrs are nil.
      if: -> {
        filetype&.key.present? &&
        platform&.key.present? &&
        channel&.key.present?
      }
    }
  validates :filename,
    presence: true,
    uniqueness: { message: 'already exists', scope: %i[account_id product_id] }
  validates :filesize,
    allow_blank: true,
    numericality: { greater_than_or_equal_to: 0 }

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
         UUID_REGEX
      where(platform: platform)
    else
      joins(:platform).where(platform: { key: platform.to_s })
    end
  }

  scope :for_filetype, -> filetype {
    case filetype
    when ReleaseFiletype,
         UUID_REGEX
      where(filetype: filetype)
    else
      joins(:filetype).where(filetype: { key: filetype.to_s })
    end
  }

  scope :for_channel, -> channel {
    key =
      case channel
      when UUID_REGEX
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
  scope :with_artifact, -> { joins(:artifact) }
  scope :without_artifact, -> { where.missing(:artifact) }
  scope :with_status, -> status {
    case status.to_s.upcase
    when 'YANKED'
      self.yanked
    when 'NOT_PUBLISHED',
         'DRAFT'
      self.unyanked.without_artifact
    when 'PUBLISHED'
      self.unyanked.with_artifact
    else
      self.none
    end
  }

  delegate :stable?, :pre_release?, :rc?, :beta?, :alpha?,
    to: :channel

  def filetype_id=(id)
    self.release_platform_id = id
  end

  def platform_id=(id)
    self.release_filetype_id = id
  end

  def channel_id=(id)
    self.release_channel_id = id
  end

  def platform_id
    release_platform_id
  end

  def filetype_id
    release_filetype_id
  end

  def channel_id
    release_channel_id
  end

  def s3_object_key
    "artifacts/#{account_id}/#{id}/#{filename}"
  end

  def yanked?
    yanked_at.present?
  end

  def status
    case
    when yanked?
      :YANKED
    when artifact.nil?
      :NOT_PUBLISHED
    else
      :PUBLISHED
    end
  end

  def semver
    Semverse::Version.new(version)
  rescue Semverse::InvalidVersionFormat
    nil
  end

  private

  def validate_associated_records_for_platform
    return unless
      platform.present?

    # Clear platform if the key is empty e.g. "" or nil
    return self.platform = nil unless
      platform.key?

    # FIXME(ezekg) Performing a safe create_or_find_by so we don't poison
    #              our current transaction by using DB exceptions
    rows =  ReleasePlatform.find_by_sql [<<~SQL.squish, { account_id: account.id, key: platform.key }]
      WITH ins AS (
        INSERT INTO "release_platforms"
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
        "release_platforms"
      WHERE
        "release_platforms"."account_id" = :account_id AND
        "release_platforms"."key"        = :key
    SQL

    self.platform = rows.first
  end

  def validate_associated_records_for_filetype
    return unless
      filetype.present?

    # Clear filetype if the key is empty e.g. "" or nil
    return self.filetype = nil unless
      filetype.key?

    filetype.key.delete_prefix!('.')

    errors.add(:filename, :extension_invalid, message: "filename extension does not match filetype (expected #{filetype.key})") if
      filename.include?('.') && !filename.downcase.ends_with?(".#{filetype.key}")

    # FIXME(ezekg) Performing a safe create_or_find_by so we don't poison
    #              our current transaction by using DB exceptions
    rows = ReleaseFiletype.find_by_sql [<<~SQL.squish, { account_id: account.id, key: filetype.key }]
      WITH ins AS (
        INSERT INTO "release_filetypes"
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
        "release_filetypes"
      WHERE
        "release_filetypes"."account_id" = :account_id AND
        "release_filetypes"."key"        = :key
    SQL

    self.filetype = rows.first
  end

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
    rows = ReleaseChannel.find_by_sql [<<~SQL.squish, { account_id: account.id, key: channel.key }]
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
      errors.add :account, :release_limit_exceeded, message: "Your tier's release limit of #{release_limit.to_s :delimited} has been reached for your account. Please upgrade to a paid tier and add a payment method at https://app.keygen.sh/billing."

      throw :abort
    end
  end
end
