# frozen_string_literal: true

class Release < ApplicationRecord
  include Limitable
  include Pageable

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
    autosave: true
  belongs_to :filetype,
    class_name: 'ReleaseFiletype',
    foreign_key: :release_filetype_id,
    inverse_of: :releases,
    autosave: true
  belongs_to :channel,
    class_name: 'ReleaseChannel',
    foreign_key: :release_channel_id,
    inverse_of: :releases,
    autosave: true
  has_many :entitlement_constraints,
    class_name: 'ReleaseEntitlementConstraint',
    inverse_of: :release,
    dependent: :delete_all
  has_many :entitlements,
    through: :entitlement_constraints
  has_many :download_links,
    class_name: 'ReleaseDownloadLink',
    inverse_of: :release,
    dependent: :delete_all
  has_many :update_links,
    class_name: 'ReleaseUpdateLink',
    inverse_of: :release,
    dependent: :delete_all
  has_many :upload_links,
    class_name: 'ReleaseUploadLink',
    inverse_of: :release,
    dependent: :delete_all

  accepts_nested_attributes_for :platform
  accepts_nested_attributes_for :filetype
  accepts_nested_attributes_for :channel

  validates :account,
    presence: { message: 'must exist' }
  validates :product,
    presence: { message: 'must exist' }
  validates :filetype,
    presence: { message: 'must exist' }
  validates :platform,
    presence: { message: 'must exist' }
  validates :channel,
    presence: { message: 'must exist' }

  validates :version,
    presence: true,
    semver: true,
    uniqueness: { message: 'already exists', scope: %i[account_id product_id release_platform_id release_channel_id release_filetype_id] }
  validates :key,
    presence: true,
    uniqueness: { message: 'already exists', scope: %i[account_id product_id] }
  validates :filesize,
    allow_blank: true,
    numericality: { greater_than_or_equal_to: 0 }

  scope :for_product, -> product {
    where(product: product)
  }

  scope :for_user, -> user {
    joins(:users).where(users: { id: user })
  }

  scope :for_license, -> license {
    joins(:licenses).where(licenses: { id: license })
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
    case channel
    when ReleaseChannel,
         UUID_REGEX
      where(channel: channel)
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
    "blobs/#{account_id}/#{id}/#{key}"
  end

  def semver
    @semver ||= Semverse::Version.new(version)
  end

  def stable?
    channel.key == 'stable'
  end

  def pre_release?
    !stable?
  end

  def rc?
    channel.key == 'rc'
  end

  def beta?
    channel.key == 'beta'
  end

  def alpha?
    channel.key == 'alpha'
  end

  def dev?
    channel.key == 'dev'
  end

  private

  def validate_associated_records_for_platform
    self.platform = account.release_platforms.find_or_initialize_by(key: platform.key)
  rescue ActiveRecord::RecordNotUnique
    retry
  end

  def validate_associated_records_for_filetype
    errors.add(:key, :extension_invalid, message: "key extension does not match filetype (expected #{filetype.key})") unless
      key.ends_with?(filetype.key)

    self.filetype = account.release_filetypes.find_or_initialize_by(key: filetype.key)
  rescue ActiveRecord::RecordNotUnique
    retry
  end

  def validate_associated_records_for_channel
    case
    when pre_release?
      errors.add(:version, :channel_invalid, message: "version does not match prerelease channel (expected x.y.z-#{channel.key}.n got #{semver})") if
        semver.pre_release.nil? || !semver.pre_release.include?(channel.key)
    when stable?
      errors.add(:version, :channel_invalid, message: "version does not match stable channel (expected x.y.z got #{semver})") if
        semver.pre_release.present?
    end

    self.channel = account.release_channels.find_or_initialize_by(key: channel.key)
  rescue ActiveRecord::RecordNotUnique
    retry
  end
end
