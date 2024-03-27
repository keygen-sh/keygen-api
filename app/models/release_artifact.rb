# frozen_string_literal: true

class ReleaseArtifact < ApplicationRecord
  include Environmental
  include Accountable
  include Limitable
  include Orderable
  include Pageable

  STATUSES = %w[
    WAITING
    UPLOADED
    FAILED
    YANKED
  ]

  attr_accessor :redirect_url

  belongs_to :release,
    inverse_of: :artifacts
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
  has_one :package,
    through: :release
  has_one :engine,
    through: :package
  has_many :constraints,
    through: :release

  has_environment default: -> { release&.environment_id }
  has_account default: -> { release&.account_id }

  accepts_nested_attributes_for :filetype
  accepts_nested_attributes_for :platform
  accepts_nested_attributes_for :arch

  before_validation -> { self.status ||= 'WAITING' }

  before_create -> { self.backend ||= account.backend }

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
    numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 5.gigabytes }

  validates :status,
    presence: true,
    inclusion: {
      message: 'unsupported status',
      in: STATUSES,
    }

  delegate :version, :semver, :channel,
    :licensed?, :open?, :closed?,
    to: :release

  scope :order_by_version, -> {
    joins(:release).reorder(<<~SQL.squish)
      releases.semver_major        DESC,
      releases.semver_minor        DESC NULLS LAST,
      releases.semver_patch        DESC NULLS LAST,
      releases.semver_pre_word     DESC NULLS FIRST,
      releases.semver_pre_num      DESC NULLS LAST,
      releases.semver_build_word   DESC NULLS LAST,
      releases.semver_build_num    DESC NULLS LAST,
      release_artifacts.created_at DESC
    SQL
  }

  scope :for_channel, -> channel {
    key =
      case channel
      when UUID_RE
        # NOTE(ezekg) We need to obtain the key because e.g. alpha channel should
        #             also show artifacts for stable, rc and beta channels.
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

  scope :for_product, -> product {
    joins(:product).where(product: { id: product })
  }

  scope :for_release, -> product {
    joins(:release).where(releases: { id: product })
  }

  scope :for_user, -> user {
    user = case user
           when UUID_RE
             User.find(user)
           else
             user
           end

    # Users should only be able to access artifacts with constraints
    # intersecting their entitlements, or no constraints at all.
    entl = within_constraints(user.entitlement_codes, strict: true)

    entl.joins(product: %i[users])
        .where(
          product: { distribution_strategy: ['LICENSED', nil] },
          users: { id: user },
        )
        .union(
          self.open
        )
  }

  scope :for_license, -> license {
    license = case license
              when UUID_RE
                License.find(license)
              else
                license
              end

    # Licenses should only be able to access artifacts with constraints
    # intersecting their entitlements, or no constraints at all.
    entl = within_constraints(license.entitlement_codes, strict: true)

    entl.joins(product: %i[licenses])
        .where(
          product: { distribution_strategy: ['LICENSED', nil] },
          licenses: { id: license },
        )
        .union(
          self.open
        )
  }

  scope :for_engine, -> engine {
    case engine.presence
    when ReleaseEngine,
         UUID_RE
      joins(:engine).where(engine: { id: engine })
    when nil
      where.missing(:engine)
    else
      joins(:engine).where(
        engine: { key: engine.to_s },
      )
    end
  }

  scope :for_package, -> package {
    case package.presence
    when ReleasePackage,
         UUID_RE
      joins(:package).where(package: { id: package })
    when nil
      where.missing(:package)
    else
      joins(:package).where(
        package: { key: package.to_s },
      )
    end
  }

  scope :for_platform, -> platform {
    case platform.presence
    when ReleasePlatform,
         UUID_RE
      joins(:platform).where(platform: { id: platform })
    when nil
      where.missing(:platform)
    else
      joins(:platform).where(
        platform: { key: platform.to_s },
      )
    end
  }

  scope :for_arch, -> arch {
    case arch.presence
    when ReleaseArch,
         UUID_RE
      joins(:arch).where(arch: { id: arch })
    when nil
      where.missing(:arch)
    else
      joins(:arch).where(
        arch: { key: arch.to_s },
      )
    end
  }

  scope :for_filetype, -> filetype {
    case filetype.presence
    when ReleaseFiletype,
         UUID_RE
      joins(:filetype).where(filetype: { id: filetype })
    when nil
      where.missing(:filetype)
    else
      joins(:filetype).where(
        filetype: { key: filetype.to_s },
      )
    end
  }

  scope :licensed, -> { joins(:product).where(product: { distribution_strategy: ['LICENSED', nil] }) }
  scope :open,     -> { joins(:product).where(product: { distribution_strategy: 'OPEN' }) }
  scope :closed,   -> { joins(:product).where(product: { distribution_strategy: 'CLOSED' }) }

  scope :with_statuses, -> *statuses { where(status: statuses.flatten.map { _1.to_s.upcase }) }
  scope :with_status,   -> status { where(status: status.to_s.upcase) }
  scope :with_checksum, -> checksum { where(checksum:) }

  ##
  # without_constraints returns artifacts without any release entitlement constraints.
  scope :without_constraints, -> {
    where_assoc_not_exists([:release, :constraints])
  }

  ##
  # with_constraints returns artifacts with release entitlement constraints.
  scope :with_constraints, -> {
    where_assoc_exists([:release, :constraints])
  }

  ##
  # within_constraints returns artifacts with specific release entitlement constraints.
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
            scp.reorder(created_at: DEFAULT_SORT_ORDER)
               .group(:id)
               .having(<<~SQL.squish, codes:)
                 count(release_entitlement_constraints) = count(entitlements) filter (
                   where code in (:codes)
                 )
               SQL
          else
            scp.where(entitlements: { code: codes })
          end

    scp.union(
      without_constraints,
    )
  }

  scope :waiting,  -> { with_status(:WAITING) }
  scope :uploaded, -> { with_status(:UPLOADED) }
  scope :failed,   -> { with_status(:FAILED) }

  scope :draft,     -> { joins(:release).where(releases: { status: 'DRAFT' }) }
  scope :published, -> { joins(:release).where(releases: { status: 'PUBLISHED' }) }
  scope :yanked,    -> { joins(:release).where(releases: { status: 'YANKED' }) }

  def key = "artifacts/#{account_id}/#{release_id}/#{filename}"

  def presigner = Aws::S3::Presigner.new(client:)

  def client
    case backend
    when 'S3'
      Aws::S3::Client.new(**AWS_CLIENT_OPTIONS)
    when 'R2'
      Aws::S3::Client.new(**CF_CLIENT_OPTIONS)
    end
  end

  def bucket
    case backend
    when 'S3'
      AWS_BUCKET
    when 'R2'
      CF_BUCKET
    end
  end

  def constraints?
    constraints.any?
  end

  def filetype_id=(id)
    self.release_filetype_id = id
  end

  def filetype_id
    release_filetype_id
  end

  def platform_id=(id)
    self.release_platform_id = id
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

  def redirect_url?
    redirect_url.present?
  end

  def download!(ttl: 1.hour)
    self.redirect_url = presigner.presigned_url(:get_object, bucket:, key:, expires_in: ttl&.to_i)

    release.download_links.create!(url: redirect_url, ttl:, account:)
  end

  def upgrade!(ttl: 1.hour)
    self.redirect_url = presigner.presigned_url(:get_object, bucket:, key:, expires_in: ttl&.to_i)

    release.upgrade_links.create!(url: redirect_url, ttl:, account:)
  end

  def upload!(ttl: 1.hour)
    self.redirect_url = presigner.presigned_url(:put_object, bucket:, key:, expires_in: ttl.to_i)

    WaitForArtifactUploadWorker.perform_async(id)

    release.upload_links.create!(url: redirect_url, ttl:, account:)
  end

  def yank!
    YankArtifactWorker.perform_async(id)

    update!(status: 'YANKED')
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

  def yanked?
    status == 'YANKED' || release.yanked?
  end

  def downloadable?
    uploaded? && !release.yanked?
  end

  private

  def validate_associated_records_for_filetype
    return unless
      filetype.present? && account.present?

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
      platform.present? && account.present?

    # Clear platform if the key is empty e.g. "" or nil
    return self.platform = nil unless
      platform.key?

    # FIXME(ezekg) Performing a safe create_or_find_by so we don't poison
    #              our current transaction by using DB exceptions
    rows = ReleasePlatform.find_by_sql [<<~SQL.squish, { account_id:, key: platform.key.downcase.strip.presence }]
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
      arch.present? && account.present?

    # Clear arch if the key is empty e.g. "" or nil
    return self.arch = nil unless
      arch.key?

    # FIXME(ezekg) Performing a safe create_or_find_by so we don't poison
    #              our current transaction by using DB exceptions
    rows = ReleaseArch.find_by_sql [<<~SQL.squish, { account_id:, key: arch.key.downcase.strip.presence }]
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
