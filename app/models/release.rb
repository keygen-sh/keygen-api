# frozen_string_literal: true

class Release < ApplicationRecord
  # FIXME(ezekg) Drop these columns after they're moved to artifacts
  self.ignored_columns = %w[release_platform_id release_filetype_id filename filesize signature checksum]

  include Environmental
  include Limitable
  include Orderable
  include Pageable
  include Diffable

  SEMVER_TAG_RE =
    %r{
      (?:
        # Match from start of word
        \A |
        # Or from last match
        \G
      )
      (?:
        # Match full numeric tags
        (?<num>\d+$)|
        # Or match words
        (?<word>\w+)
      )
      \K
    }xi.freeze

  STATUSES = %w[
    DRAFT
    PUBLISHED
    YANKED
  ]

  belongs_to :account,
    inverse_of: :releases
  belongs_to :product,
    inverse_of: :releases
  belongs_to :package,
    class_name: 'ReleasePackage',
    foreign_key: :release_package_id,
    inverse_of: :releases,
    optional: true
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
  has_one :engine,
    through: :package

  # FIXME(ezekg) For v1.0 backwards compatibility
  has_one :artifact,
    class_name: 'ReleaseArtifact',
    inverse_of: :release,
    dependent: :delete

  has_environment default: -> { product&.environment_id }

  accepts_nested_attributes_for :constraints, limit: 20, reject_if: :reject_associated_records_for_constraints
  accepts_nested_attributes_for :artifact, update_only: true
  accepts_nested_attributes_for :channel

  before_validation -> { self.status ||= 'DRAFT' }

  before_create -> { self.api_version ||= account.api_version }
  before_create -> { self.version = semver.to_s }
  before_create :enforce_release_limit_on_account!

  before_save :set_semver_version,
    if: :version_changed?

  validates :product,
    scope: { by: :account_id }

  validates :package,
    presence: { message: 'must exist' },
    scope: { by: :account_id },
    if: :package_id?

  validates :channel,
    scope: { by: :account_id }

  validates :api_version,
    allow_nil: true,
    inclusion: {
      message: 'unsupported version',
      in: RequestMigrations.supported_versions,
    }

  validates :version,
    presence: true,
    semver: true,
    uniqueness: {
      scope: %i[version release_package_id product_id account_id],
      message: 'version already exists',
      # We only want to enforce uniqueness for >= v1.1
      if: -> { api_version != '1.0' },
    }

  validates :status,
    presence: true,
    inclusion: {
      message: 'unsupported status',
      in: STATUSES,
    }

  validates :tag,
    exclusion: { in: EXCLUDED_ALIASES, message: "is reserved" },
    uniqueness: {
      scope: %i[tag account_id],
      message: 'tag already exists',
      if: :tag?,
    }

  # Assert that package matches the release's product.
  validate on: %i[create update] do
    next unless
      release_package_id_changed?

    unless package.nil? || package.product_id == product_id
      errors.add :package, :not_allowed, message: 'package product must match release product'
    end
  end

  scope :search_id, -> (term) {
    identifier = term.to_s
    return none if
      identifier.empty?

    return where(id: identifier) if
      UUID_RE.match?(identifier)

    where('releases.id::text ILIKE ?', "%#{sanitize_sql_like(identifier)}%")
  }

  scope :search_version, -> (term) {
    return none if
      term.blank?

    where('releases.version ILIKE ?', "%#{sanitize_sql_like(term)}%")
  }

  scope :search_tag, -> (term) {
    return none if
      term.blank?

    where('releases.tag ILIKE ?', "%#{sanitize_sql_like(term)}%")
  }

  scope :search_metadata, -> (terms) {
    # FIXME(ezekg) Need to figure out a better way to do this. We need to be able
    #              to search for the original string values and type cast, since
    #              HTTP querystring parameters are strings.
    #
    #              Example we need to be able to search for:
    #
    #                { metadata: { external_id: "1624214616", internal_id: 1 } }
    #
    terms.reduce(self) do |scope, (key, value)|
      search_key       = key.to_s.underscore.parameterize(separator: '_')
      before_type_cast = { search_key => value }
      after_type_cast  =
        case value
        when 'true'
          { search_key => true }
        when 'false'
          { search_key => false }
        when 'null'
          { search_key => nil }
        when /^\d+$/
          { search_key => value.to_i }
        when /^\d+\.\d+$/
          { search_key => value.to_f }
        else
          { search_key => value }
        end

      scope.where('releases.metadata @> ?', before_type_cast.to_json)
        .or(
          scope.where('releases.metadata @> ?', after_type_cast.to_json)
        )
    end
  }

  scope :search_product, -> (term) {
    product_identifier = term.to_s
    return none if
      product_identifier.empty?

    return where(product_id: product_identifier) if
      UUID_RE.match?(product_identifier)

    scope = joins(:product).where('products.name ILIKE ?', "%#{sanitize_sql_like(product_identifier)}%")
    return scope unless
      UUID_CHAR_RE.match?(product_identifier)

    scope.or(
      joins(:product).where(<<~SQL.squish, product_identifier.gsub(SANITIZE_TSV_RE, ' '))
        to_tsvector('simple', products.id::text)
        @@
        to_tsquery(
          'simple',
          ''' ' ||
          ?     ||
          ' ''' ||
          ':*'
        )
      SQL
    )
  }

  scope :order_by_version, -> {
    reorder(<<~SQL.squish)
      releases.semver_major      DESC,
      releases.semver_minor      DESC NULLS LAST,
      releases.semver_patch      DESC NULLS LAST,
      releases.semver_pre_word   DESC NULLS FIRST,
      releases.semver_pre_num    DESC NULLS LAST,
      releases.semver_build_word DESC NULLS LAST,
      releases.semver_build_num  DESC NULLS LAST
    SQL
  }

  scope :for_product, -> product {
    where(product: product)
  }

  scope :for_user, -> user {
    user = case user
           when UUID_RE
             User.find(user)
           else
             user
           end

    # Users should only be able to access releases with constraints
    # intersecting their entitlements, or no constraints at all.
    entl = within_constraints(user.entitlement_codes, strict: true)

    # Should we be applying a LIMIT to these UNION'd queries?
    entl.joins(:users, :product)
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

    # Licenses should only be able to access releases with constraints
    # intersecting their entitlements, or no constraints at all.
    entl = within_constraints(license.entitlement_codes, strict: true)

    # Should we be applying a LIMIT to these UNION'd queries?
    entl.joins(:licenses, :product)
        .where(
          product: { distribution_strategy: ['LICENSED', nil] },
          licenses: { id: license },
        )
        .union(
          self.open
        )
  }

  scope :for_engine, -> engine {
    case engine
    when ReleaseEngine,
         UUID_RE
      joins(:engine).where(engine: { id: engine })
    else
      joins(:engine).where(engine: { key: engine.to_s })
    end
  }

  scope :for_package, -> package {
    case package
    when ReleasePackage,
         UUID_RE
      joins(:package).where(package: { id: package })
    else
      joins(:package).where(package: { key: package.to_s })
    end
  }

  scope :for_platform, -> platform {
    case platform
    when ReleasePlatform,
         UUID_RE
      joins(:platforms).where(platforms: { id: platform })
    else
      joins(:platforms).where(platforms: { key: platform.to_s })
    end
  }

  scope :for_arch, -> arch {
    case arch
    when ReleaseArch,
         UUID_RE
      joins(:arches).where(arches: { id: arch })
    else
      joins(:arches).where(arches: { key: arch.to_s })
    end
  }

  scope :for_filetype, -> filetype {
    case filetype
    when ReleaseFiletype,
         UUID_RE
      joins(:filetypes).where(filetypes: { id: filetype })
    else
      joins(:filetypes).where(filetypes: { key: filetype.to_s })
    end
  }

  scope :for_channel, -> channel {
    key =
      case channel
      when UUID_RE
        # NOTE(ezekg) We need to obtain the key because e.g. alpha channel should
        #             also show releases for stable, rc and beta channels.
        joins(:channel).select('release_channels.key')
                       .where(channel:)
                       .take
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

  scope :licensed, -> { joins(:product).where(product: { distribution_strategy: ['LICENSED', nil] }) }
  scope :open, -> { joins(:product).where(product: { distribution_strategy: 'OPEN' }) }
  scope :closed, -> { joins(:product).where(product: { distribution_strategy: 'CLOSED' }) }

  scope :with_artifacts, -> { where.associated(:artifacts) }
  scope :without_artifacts, -> { where.missing(:artifacts) }

  scope :with_statuses, -> *statuses { where(status: statuses.flatten.map { _1.to_s.upcase }) }
  scope :with_status,   -> status { where(status: status.to_s.upcase) }
  scope :with_version, -> version { where(version:) }

  ##
  # without_constraints returns releases without entitlement constraints.
  scope :without_constraints, -> { where_assoc_not_exists(:constraints) }

  ##
  # with_constraints returns releases with entitlement constraints.
  scope :with_constraints, -> { where_assoc_exists(:constraints) }

  ##
  # within_constraints returns releases with specific entitlement constraints.
  #
  # The :strict keyword ensures that the release has equal or less than
  # number of constraints as matched codes (or none), i.e. ALL vs ANY.
  # Otherwise, we just match ANY.
  #
  # For example, given a license has the entitlements FOO and BAR. We
  # want to display all releases that have constraints FOO and/or BAR,
  # but none that have BAZ. To do this, we need to ensure that the
  # release has either FOO and/or BAR constraints, but that it
  # has no other constraints.
  #
  # After filtering, that would look like:
  #
  #   count(constraints) = count(entitlements in :codes)
  #
  # This avoids authz issues later on.
  #
  scope :within_constraints, -> *codes, strict: false {
    codes = codes.flatten
                 .compact_blank
                 .uniq

    return without_constraints if
      codes.empty?

    scp = joins(constraints: :entitlement)
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

    # Union with releases without constraints as well.
    scp.union(
      without_constraints,
    )
  }

  scope :published, -> { with_status(:PUBLISHED) }
  scope :drafts,    -> { with_status(:DRAFT) }
  scope :yanked,    -> { with_status(:YANKED) }
  scope :unyanked,  -> { with_statuses(:DRAFT, :PUBLISHED) }

  delegate :licensed?, :open?, :closed?,
    to: :product

  delegate :stable?, :pre_release?, :rc?, :beta?, :alpha?,
    to: :channel

  def package_id? = release_package_id?
  def package_id  = release_package_id
  def package_id=(id)
    self.release_package_id = id
  end

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

  def upgrade!(channel: nil, constraint: nil)
    release = product.releases
      .for_channel(channel.presence || self.channel)
      .order_by_version
      .published
      .then { |scope|
        base = scope.where.not(version:)
                    .where.not(id:)

        scope = if semver_build_num.present?
                  # Build num to greater build num (e.g. +build.1 to +build.2)
                  base.where(<<~SQL.squish, semver_major:, semver_minor:, semver_patch:, semver_pre_word:, semver_pre_num:, semver_build_word:, semver_build_num:)
                    semver_major      = :semver_major      AND
                    semver_minor      = :semver_minor      AND
                    semver_patch      = :semver_patch      AND
                    semver_pre_word   = :semver_pre_word   AND
                    semver_pre_num    = :semver_pre_num    AND
                    semver_build_word = :semver_build_word AND
                    semver_build_num  > :semver_build_num
                  SQL
                else
                  # No build num to build num (e.g. +build to +build.1653508117)
                  base.where(<<~SQL.squish, semver_major:, semver_minor:, semver_patch:, semver_pre_word:, semver_pre_num:, semver_build_word:)
                    semver_major      = :semver_major      AND
                    semver_minor      = :semver_minor      AND
                    semver_patch      = :semver_patch      AND
                    semver_pre_word   = :semver_pre_word   AND
                    semver_pre_num    = :semver_pre_num    AND
                    semver_build_word = :semver_build_word AND
                    semver_build_num IS NOT NULL
                  SQL
                end

        scope = if semver_build_word.present?
                  # Build tag to greater build tag (e.g. +1 to +2)
                  scope.or(
                    base.where(<<~SQL.squish, semver_major:, semver_minor:, semver_patch:, semver_pre_word:, semver_pre_num:, semver_build_word:),
                      semver_major      = :semver_major      AND
                      semver_minor      = :semver_minor      AND
                      semver_patch      = :semver_patch      AND
                      semver_pre_word   = :semver_pre_word   AND
                      semver_pre_num    = :semver_pre_num    AND
                      semver_build_word > :semver_build_word
                    SQL
                  )
                else
                  # No build tag to build tag (e.g. alpha to alpha+build.1653508117)
                  scope.or(
                    base.where(<<~SQL.squish, semver_major:, semver_minor:, semver_patch:, semver_pre_word:, semver_pre_num:),
                      semver_major      = :semver_major    AND
                      semver_minor      = :semver_minor    AND
                      semver_patch      = :semver_patch    AND
                      semver_pre_word   = :semver_pre_word AND
                      semver_pre_num    = :semver_pre_num  AND
                      semver_build_word IS NOT NULL
                    SQL
                  )
                end

        scope = if semver_pre_num.present?
                  # Pre num to greater pre num (e.g. alpha.1 to alpha.2)
                  scope.or(
                    base.where(<<~SQL.squish, semver_major:, semver_minor:, semver_patch:, semver_pre_word:, semver_pre_num:),
                      semver_major    = :semver_major    AND
                      semver_minor    = :semver_minor    AND
                      semver_patch    = :semver_patch    AND
                      semver_pre_word = :semver_pre_word AND
                      semver_pre_num  > :semver_pre_num
                    SQL
                  )
                else
                  # No pre num to pre num (e.g. beta to beta.1)
                  scope.or(
                    base.where(<<~SQL.squish, semver_major:, semver_minor:, semver_patch:, semver_pre_word:),
                      semver_major    = :semver_major    AND
                      semver_minor    = :semver_minor    AND
                      semver_patch    = :semver_patch    AND
                      semver_pre_word = :semver_pre_word AND
                      semver_pre_num IS NOT NULL
                    SQL
                  )
                end

        if semver_pre_word.present?
          # Pre tag to greater pre tag (e.g. alpha to beta)
          scope = scope.or(
            base.where(<<~SQL.squish, semver_major:, semver_minor:, semver_patch:, semver_pre_word:),
              semver_major    = :semver_major    AND
              semver_minor    = :semver_minor    AND
              semver_patch    = :semver_patch    AND
              semver_pre_word > :semver_pre_word
            SQL
          )

          # Pre tag to no pre tag (e.g. 1.0.0-alpha to 1.0.0)
          scope = scope.or(
            base.where(<<~SQL.squish, semver_major:, semver_minor:, semver_patch:),
              semver_major    = :semver_major AND
              semver_minor    = :semver_minor AND
              semver_patch    = :semver_patch AND
              semver_pre_word IS NULL         AND
              semver_pre_num  IS NULL
            SQL
          )
        end

        # Patch to greater patch (e.g. 1.0.2 to 1.0.3)
        scope = scope.or(
          base.where(<<~SQL.squish, semver_major:, semver_minor:, semver_patch:),
            semver_major = :semver_major AND
            semver_minor = :semver_minor AND
            semver_patch > :semver_patch
          SQL
        )

        # Minor to greater minor (e.g. 1.0.3 to 1.1.0)
        scope = scope.or(
          base.where(<<~SQL.squish, semver_major:, semver_minor:),
            semver_major = :semver_major AND
            semver_minor > :semver_minor
          SQL
        )

        # Major to greater major (e.g. 1.1.0 to 2.0.0)
        scope = scope.or(
          base.where(<<~SQL.squish, semver_major:),
            semver_major > :semver_major
          SQL
        )

        scope
      }
      .then { |scope|
        next scope if
          constraint.nil?

        _, major, minor, patch, pre, build = Semverse::Constraint.split(constraint)

        # Filter pre tags if one was specified, e.g. -beta, -alpha, etc.
        if pre.present?
          pre_tags = pre.scan(SEMVER_TAG_RE)

          if pre_word = pre_tags.map { _1[1] }.compact.join('.').presence
            scope = scope.where(semver_pre_word: pre_word)
          end

          if pre_num = pre_tags.map { _1[0] }.compact.first.presence
            scope = scope.where(semver_pre_num: pre_num)
          end
        end

        # Filter pre tags if one was specified, e.g. +pkg1, +pkg2, etc.
        if build.present?
          build_tags = build.scan(SEMVER_TAG_RE)

          if build_word = build_tags.map { _1[1] }.compact.join('.').presence
            scope = scope.where(semver_build_word: build_word)
          end

          if build_num = build_tags.map { _1[0] }.compact.first.presence
            scope = scope.where(semver_build_num: build_num)
          end
        end

        # Filter based on version part.
        case
        when patch.present?
          scope.where(semver_major: major, semver_minor: minor, semver_patch: patch..)
        when minor.present?
          scope.where(semver_major: major, semver_minor: minor..)
        when major.present?
          scope.where(semver_major: major)
        end
      }
      .limit(1)
      .take

    raise Keygen::Error::NotFoundError.new(model: Release.name, message: 'upgrade not available') if
      release.nil?

    release
  end

  def upgrade(...)
    upgrade!(...)
  rescue Keygen::Error::NotFoundError
    nil
  end

  def publish!
    update!(status: 'PUBLISHED')
  end

  def yank!
    update!(status: 'YANKED')
  end

  def draft?
    status == 'DRAFT'
  end

  def published?
    status == 'PUBLISHED'
  end

  def yanked?
    status == 'YANKED'
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

    # Clear channel if the key is empty e.g. "" or nil
    return self.channel = nil unless
      channel.key?

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
    rows = ReleaseChannel.find_by_sql [<<~SQL.squish, { account_id:, key: channel.key.downcase.strip.presence }]
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

  def reject_associated_records_for_constraints(attrs)
    return if
      new_record?

    constraints.exists?(
      # Make sure we only select real columns, not e.g. _destroy.
      attrs.slice(attributes.keys),
    )
  end

  def enforce_release_limit_on_account!
    return unless account.trialing_or_free?

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

  def set_semver_version
    v = semver

    # Store individual components for sorting purposes
    self.semver_major = v.major
    self.semver_minor = v.minor
    self.semver_patch = v.patch

    if v.pre_release.present?
      pre_tags = v.pre_release.scan(SEMVER_TAG_RE)

      # Collect non-nil pre words and rejoin with delimiter
      self.semver_pre_word = pre_tags.map { _1[1] }
                                     .compact
                                     .join('.')
                                     .presence

      # Collect first numeric pre tag
      self.semver_pre_num  = pre_tags.map { _1[0] }
                                     .compact
                                     .first
                                     .presence
    end

    if v.build.present?
      build_tags = v.build.scan(SEMVER_TAG_RE)

      # Collect non-nil build words and rejoin with delimiter
      self.semver_build_word = build_tags.map { _1[1] }
                                         .compact
                                         .join('.')
                                         .presence

      # Collect first numeric build tag
      self.semver_build_num  = build_tags.map { _1[0] }
                                         .compact
                                         .first
                                         .presence
    end
  end
end
