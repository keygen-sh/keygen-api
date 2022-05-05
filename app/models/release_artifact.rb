# frozen_string_literal: true

class ReleaseArtifact < ApplicationRecord
  include Limitable
  include Orderable
  include Pageable

  STATUSES = %w[
    WAITING
    UPLOADED
    FAILED
  ]

  belongs_to :account
  belongs_to :release
  belongs_to :platform,
    class_name: 'ReleasePlatform',
    foreign_key: :release_platform_id,
    inverse_of: :artifacts,
    autosave: true,
    optional: true
  belongs_to :arch,
    class_name: 'ReleaseArch',
    foreign_key: :release_arch_id,
    inverse_of: :artifacts,
    autosave: true,
    optional: true
  belongs_to :filetype,
    class_name: 'ReleaseFiletype',
    foreign_key: :release_filetype_id,
    inverse_of: :artifacts,
    autosave: true,
    optional: true
  has_one :channel,
    through: :release
  has_one :product,
    through: :release
  has_many :users,
    through: :product
  has_many :licenses,
    through: :product

  accepts_nested_attributes_for :filetype
  accepts_nested_attributes_for :platform
  accepts_nested_attributes_for :arch

  before_validation -> { self.account_id ||= release&.account_id }
  before_validation -> { self.status ||= 'WAITING' }

  validates :product,
    scope: { by: :account_id }

  validates :release,
    scope: { by: :account_id }

  validates :filetype,
    presence: { message: 'must exist' },
    scope: { by: :account_id },
    unless: -> { filetype.nil? }

  validates :platform,
    presence: { message: 'must exist' },
    scope: { by: :account_id },
    unless: -> { platform.nil? }

  validates :arch,
    presence: { message: 'must exist' },
    scope: { by: :account_id },
    unless: -> { arch.nil? }

  validates :filename,
    presence: true,
    uniqueness: { message: 'already exists', scope: %i[account_id release_id] }

  validates :filesize,
    allow_blank: true,
    numericality: { greater_than_or_equal_to: 0 }

  validates :status,
    presence: true,
    inclusion: {
      message: 'unsupported status',
      in: STATUSES,
    }

  delegate :version, :semver, :channel,
    to: :release

  scope :order_by_version, -> {
    joins(:release).order(<<~SQL.squish)
      releases.semver_major        DESC,
      releases.semver_minor        DESC,
      releases.semver_patch        DESC,
      releases.semver_prerelease   DESC NULLS FIRST,
      releases.semver_build        DESC NULLS FIRST
    SQL
  }

  scope :for_channel, -> channel {
    key =
      case channel
      when UUID_RE
        # NOTE(ezekg) We need to obtain the key because e.g. alpha channel should
        #             also show artifacts for stable, rc and beta channels.
        joins(release: :channel).select('release_channels.key')
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

  scope :for_channel_key, -> key { joins(release: :channel).where(channel: { key: key }) }
  scope :stable, -> { for_channel_key(%i(stable)) }
  scope :rc, -> { for_channel_key(%i(stable rc)) }
  scope :beta, -> { for_channel_key(%i(stable rc beta)) }
  scope :alpha, -> { for_channel_key(%i(stable rc beta alpha)) }
  scope :dev, -> { for_channel_key(%i(dev)) }

  scope :for_product, -> product {
    joins(release: :product).where(product: { id: product })
  }

  scope :for_user, -> user {
    joins(release: { product: %i[users] })
      .where(
        product: { distribution_strategy: ['LICENSED', nil] },
        users: { id: user },
      )
      .union(
        self.open
      )
  }

  scope :for_license, -> license {
    joins(release: { product: %i[licenses] })
      .where(
        product: { distribution_strategy: ['LICENSED', nil] },
        licenses: { id: license },
      )
      .union(
        self.open
      )
  }

  scope :licensed, -> { joins(release: :product).where(product: { distribution_strategy: ['LICENSED', nil] }) }
  scope :open, -> { joins(release: :product).where(product: { distribution_strategy: 'OPEN' }) }
  scope :closed, -> { joins(release: :product).where(product: { distribution_strategy: 'CLOSED' }) }

  scope :with_statuses, -> statuses { where(status: statuses.map { _1.to_s.upcase }) }
  scope :with_status, -> status { where(status: status.to_s.upcase) }

  scope :waiting,  -> { with_status(:WAITING) }
  scope :uploaded, -> { with_status(:UPLOADED) }
  scope :failed,   -> { with_status(:FAILED) }

  scope :draft,     -> { joins(:release).where(release: { status: 'DRAFT' })}
  scope :published, -> { joins(:release).where(release: { status: 'PUBLISHED' })}
  scope :yanked,    -> { joins(:release).where(release: { status: 'YANKED' })}

  delegate :draft?, :published?, :yanked?,
    to: :release

  def s3_object_key
    "artifacts/#{account_id}/#{release_id}/#{filename}"
  end

  def filetype_id=(id)
    self.release_platform_id = id
  end

  def filetype_id
    release_filetype_id
  end

  def platform_id=(id)
    self.release_filetype_id = id
  end

  def platform_id
    release_platform_id
  end

  def arch_id=(id)
    self.release_arch_id = id
  end

  def arch_id
    release_arch_id
  end

  # TODO(ezekg) Check if IP address is from EU and use: bucket=keygen-dist-eu region=eu-west-2
  # NOTE(ezekg) Check obj.replication_status for EU
  def download!(ttl: 1.hour)
    signer = Aws::S3::Presigner.new
    url    = signer.presigned_url(:get_object, bucket: 'keygen-dist', key: s3_object_key, expires_in: ttl&.to_i)

    release.download_links.create!(account:, url:, ttl:)
  end

  def upgrade!(ttl: 1.hour)
    signer = Aws::S3::Presigner.new
    url    = signer.presigned_url(:get_object, bucket: 'keygen-dist', key: s3_object_key, expires_in: ttl&.to_i)

    release.upgrade_links.create!(account:, url:, ttl:)
  end

  def upload!(ttl: 1.hour)
    signer = Aws::S3::Presigner.new
    url    = signer.presigned_url(:put_object, bucket: 'keygen-dist', key: s3_object_key, expires_in: ttl.to_i)

    # TODO(ezekg) Add waiter job and then send artifact.uploaded event

    release.upload_links.create!(account:, url:, ttl:)
  end

  def yank!
    s3 = Aws::S3::Client.new
    s3.delete_object(bucket: 'keygen-dist', key: s3_object_key)
  end

  def waiting?
    status == 'WAITING'
  end

  def uploaded?
    # NOTE(ezekg) Backwards compat
    return true if
      status.nil?

    status == 'UPLOADED'
  end

  def failed?
    status == 'FAILED'
  end

  def downloadable?
    uploaded? && published?
  end

  private

  def validate_associated_records_for_filetype
    return unless
      filetype.present?

    # Clear filetype if the key is empty e.g. "" or nil
    return self.filetype = nil unless
      filetype.key?

    # Clean up filetype
    key = filetype.key.downcase
                      .delete_prefix('.')
                      .strip

    errors.add(:filename, :extension_invalid, message: "filename extension does not match filetype (expected #{key})") if
      filename.include?('.') && !filename.downcase.ends_with?(".#{key}")

    # FIXME(ezekg) Performing a safe create_or_find_by so we don't poison
    #              our current transaction by using DB exceptions
    rows = ReleaseFiletype.find_by_sql [<<~SQL.squish, { account_id:, key: }]
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

  def validate_associated_records_for_platform
    return unless
      platform.present?

    # Clear platform if the key is empty e.g. "" or nil
    return self.platform = nil unless
      platform.key?

    # FIXME(ezekg) Performing a safe create_or_find_by so we don't poison
    #              our current transaction by using DB exceptions
    rows =  ReleasePlatform.find_by_sql [<<~SQL.squish, { account_id:, key: platform.key.downcase.strip.presence }]
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

  def validate_associated_records_for_arch
    return unless
      arch.present?

    # Clear arch if the key is empty e.g. "" or nil
    return self.arch = nil unless
      arch.key?

    # FIXME(ezekg) Performing a safe create_or_find_by so we don't poison
    #              our current transaction by using DB exceptions
    rows =  ReleaseArch.find_by_sql [<<~SQL.squish, { account_id:, key: arch.key.downcase.strip.presence }]
      WITH ins AS (
        INSERT INTO "release_arches"
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
        "release_arches"
      WHERE
        "release_arches"."account_id" = :account_id AND
        "release_arches"."key"        = :key
    SQL

    self.arch = rows.first
  end
end
