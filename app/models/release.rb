# frozen_string_literal: true

class Release < ApplicationRecord
  include Limitable
  include Pageable

  belongs_to :account
  belongs_to :product
  belongs_to :platform, class_name: 'ReleasePlatform', foreign_key: :release_platform_id, autosave: true
  belongs_to :filetype, class_name: 'ReleaseFiletype', foreign_key: :release_filetype_id, autosave: true
  belongs_to :channel, class_name: 'ReleaseChannel', foreign_key: :release_channel_id, autosave: true
  has_many :entitlement_constraints, class_name: 'ReleaseEntitlementConstraint', dependent: :delete_all
  has_many :entitlements, through: :entitlement_constraints
  has_many :download_links, class_name: 'ReleaseDownloadLink', dependent: :delete_all
  has_many :update_links, class_name: 'ReleaseUpdateLink', dependent: :delete_all
  has_many :upload_links, class_name: 'ReleaseUploadLink', dependent: :delete_all

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

  scope :for_platform, -> platform {
    case platform
    when ReleasePlatform
      where(platform: platform)
    else
      joins(:platform).where(platform: { key: platform.to_s })
    end
  }

  scope :for_filetype, -> filetype {
    case filetype
    when ReleasePlatform
      where(filetype: filetype)
    else
      joins(:filetype).where(filetype: { key: filetype.to_s })
    end
  }

  scope :for_channel, -> channel {
    key =
      case channel
      when ReleaseChannel
        channel.key
      else
        channel.to_s
      end

    case key.to_sym
    when :stable then self.stable
    when :rc     then self.rc
    when :beta   then self.beta
    when :alpha  then self.alpha
    when :dev    then self.dev
    else              self.none
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

  def s3_object_key
    "blobs/#{account_id}/#{id}/#{key}"
  end

  def semver
    Semverse::Version.new(version)
  end

  def stable?
    channel.key == 'stable'
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
  end

  def validate_associated_records_for_filetype
    self.filetype = account.release_filetypes.find_or_initialize_by(key: filetype.key)
  end

  def validate_associated_records_for_channel
    self.channel = account.release_channels.find_or_initialize_by(key: channel.key)
  end
end
