# frozen_string_literal: true

class ReleaseArtifact < ApplicationRecord
  include Limitable
  include Orderable
  include Pageable

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
  has_one :product,
    through: :release
  has_many :users,
    through: :product
  has_many :licenses,
    through: :product

  accepts_nested_attributes_for :filetype
  accepts_nested_attributes_for :platform
  accepts_nested_attributes_for :arch

  before_validation -> { self.account_id ||= release.account_id }

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

  delegate :version, :semver, :channel,
    to: :release

  scope :for_product, -> product {
    where(product: product)
  }

  scope :for_user, -> user {
    joins(product: %i[users])
      .where(
        product: { distribution_strategy: ['LICENSED', nil] },
        users: { id: user },
      )
      .union(
        self.open
      )
  }

  scope :for_license, -> license {
    joins(product: %i[licenses])
      .where(
        product: { distribution_strategy: ['LICENSED', nil] },
        licenses: { id: license },
      )
      .union(
        self.open
      )
  }

  scope :licensed, -> { joins(:product).where(product: { distribution_strategy: ['LICENSED', nil] }) }
  scope :open, -> { joins(:product).where(product: { distribution_strategy: 'OPEN' }) }
  scope :closed, -> { joins(:product).where(product: { distribution_strategy: 'CLOSED' }) }

  delegate :yanked?,
    to: :release

  def s3_object_key
    "artifacts/#{account_id}/#{release_id}/#{key}"
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
    rows =  ReleasePlatform.find_by_sql [<<~SQL.squish, { account_id:, key: platform.key.downcase.strip }]
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
    rows =  ReleaseArch.find_by_sql [<<~SQL.squish, { account_id:, key: arch.key.downcase.strip }]
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
