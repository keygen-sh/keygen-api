# frozen_string_literal: true

class ReleaseArtifact < ApplicationRecord
  include Keygen::PortableClass
  include Environmental
  include Accountable
  include Limitable
  include Orderable
  include Pageable

  STATUSES = %w[
    WAITING
    PROCESSING
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
  has_many :manifests,
    class_name: 'ReleaseManifest',
    foreign_key: :release_artifact_id,
    inverse_of: :artifact,
    dependent: :delete_all
  # NOTE(ezekg) not a strict has-one but this is a convenience
  has_one :manifest,
    class_name: 'ReleaseManifest',
    foreign_key: :release_artifact_id,
    inverse_of: :artifact,
    dependent: :delete
  has_many :descriptors,
    class_name: 'ReleaseDescriptor',
    foreign_key: :release_artifact_id,
    inverse_of: :artifact,
    dependent: :delete_all
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

  scope :order_by_version, -> (order = :desc) {
    sql = case order
          in :desc
            <<~SQL
              releases.semver_major        DESC,
              releases.semver_minor        DESC NULLS LAST,
              releases.semver_patch        DESC NULLS LAST,
              releases.semver_pre_word     DESC NULLS FIRST,
              releases.semver_pre_num      DESC NULLS LAST,
              releases.semver_build_word   DESC NULLS LAST,
              releases.semver_build_num    DESC NULLS LAST,
              release_artifacts.created_at DESC
            SQL
          in :asc
            <<~SQL
              releases.semver_major        ASC,
              releases.semver_minor        ASC NULLS FIRST,
              releases.semver_patch        ASC NULLS FIRST,
              releases.semver_pre_word     ASC NULLS LAST,
              releases.semver_pre_num      ASC NULLS FIRST,
              releases.semver_build_word   ASC NULLS FIRST,
              releases.semver_build_num    ASC NULLS FIRST,
              release_artifacts.created_at ASC
            SQL
          end

    joins(:release).reorder(sql.squish)
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
      stable
    when 'rc'
      rc
    when 'beta'
      beta
    when 'alpha'
      alpha
    when 'dev'
      dev
    else
      none
    end
  }

  scope :for_channel_key, -> key { joins(:channel).where(channel: { key: key }) }
  scope :stable, -> { for_channel_key(%i(stable)) }
  scope :rc, -> { for_channel_key(%i(stable rc)) }
  scope :beta, -> { for_channel_key(%i(stable rc beta)) }
  scope :alpha, -> { for_channel_key(%i(stable rc beta alpha)) }
  scope :dev, -> { for_channel_key(%i(dev)) }
  scope :prerelease, -> { for_channel_key(%i(rc beta alpha dev)) }

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

  scope :for_release, -> release {
    case release
    in UUID_RE => release_id
      where(release_id:)
    in Release => release
      where(release:)
    in String => term
      joins(:release).where(releases: { version: term })
                     .or(
                       joins(:release).where(releases: { tag: term }),
                     )
    else
      none
    end
  }

  scope :for_user, -> user {
    # Collect artifacts for each of the user's licenses. This is the only way
    # we can ensure we scope to exactly what the user has access to, e.g.
    # when taking into account expiration and distribution strategies,
    # as well as entitlements per-license.
    scopes = License.preload(:policy)
                    .for_user(user)
                    .collect do |license|
      # Users should only be able to access artifacts with constraints
      # intersecting their entitlements, or no constraints at all.
      scope = within_constraints(license.entitlement_codes, strict: true)

      # Users should only be able to access artifacts within their licenses'
      # expiration windows, i.e. not artifacts of releases published after
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

    # Licenses should only be able to access artifacts with constraints
    # intersecting their entitlements, or no constraints at all.
    scope = within_constraints(license.entitlement_codes, strict: true)

    # Licenses should only be able to access artifacts within their
    # expiration window, i.e. not artifacts of releases published
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

  scope :for_packages, -> packages {
    joins(:package).where(package: { id: packages })
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

  scope :for_filetypes, -> *filetypes { joins(:filetype).where(filetype: { key: filetypes }) }
  scope :for_filetype, -> filetype {
    case filetype.presence
    when ReleaseFiletype,
         UUID_RE
      joins(:filetype).where(filetype: { id: filetype })
    when nil
      where.missing(:filetype)
    when Symbol
      joins(:filetype).where(
        filetype: { key: filetype.to_s },
      )
    when String
      joins(:filetype).where(
        filetype: { key: filetype.downcase.delete_prefix('.').strip },
      )
    else
      none
    end
  }

  scope :licensed, -> { joins(release: :product).where(product: { distribution_strategy: ['LICENSED', nil] }) }
  scope :open,     -> { joins(release: :product).where(product: { distribution_strategy: 'OPEN' }) }
  scope :closed,   -> { joins(release: :product).where(product: { distribution_strategy: 'CLOSED' }) }

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

  scope :waiting,    -> { with_status('WAITING') }
  scope :processing, -> { with_status('PROCESSING') }
  scope :uploaded,   -> { with_status('UPLOADED') }
  scope :failed,     -> { with_status('FAILED') }

  scope :draft,     -> { joins(:release).where(releases: { status: 'DRAFT' }) }
  scope :published, -> { joins(:release).where(releases: { status: 'PUBLISHED' }) }
  scope :yanked,    -> { joins(:release).where(releases: { status: 'YANKED' }) }
  scope :unyanked,  -> { joins(:release).where.not(releases: { status: 'YANKED' }) }

  scope :gems,     -> { for_filetype(:gem) }
  scope :tarballs, -> { for_filetypes(:tgz, :tar, :'tar.gz') }

  delegate :version, :semver, :channel, :tag,
    :tag?, :licensed?, :open?, :closed?,
    allow_nil: true,
    to: :release

  def key_for(path) = "artifacts/#{account_id}/#{release_id}/#{path}"
  def key           = key_for(filename)

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

  def download!(path: filename, ttl: 1.hour)
    self.redirect_url = presigner.presigned_url(:get_object, bucket:, key: key_for(path), expires_in: ttl&.to_i)

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

  def processing?
    status == 'PROCESSING'
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

  def checksum_encoding
    case checksum
    in HEX_RE    then :hex
    in BASE64_RE then :base64
    else              nil
    end
  rescue Encoding::CompatibilityError # invalid encoding
    nil
  end

  def checksum_bytes
    case checksum_encoding
    in :base64 then Base64.decode64(checksum)
    in :hex    then [checksum].pack('H*')
    else            nil
    end
  rescue ArgumentError # invalid base64
    nil
  end

  def checksum_bytesize
    case checksum_bytes
    in String then checksum_bytes.size
    else           nil
    end
  end

  def checksum_algorithm
    case checksum_bytesize
    in 16 then :md5
    in 20 then :sha1
    in 28 then :sha224
    in 32 then :sha256
    in 48 then :sha384
    in 64 then :sha512
    else       nil
    end
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
