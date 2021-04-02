# frozen_string_literal: true

class LicenseEntitlement < ApplicationRecord
  include Limitable
  include Pageable

  belongs_to :account
  belongs_to :license
  belongs_to :entitlement
  has_one :product, through: :license
  has_one :policy, through: :license
  has_one :user, through: :license

  validates :account, presence: { message: 'must exist' }
  validates :license, presence: { message: 'must exist' }
  validates :entitlement, presence: { message: 'must exist' }, uniqueness: { message: 'already exists', scope: [:account_id, :license_id, :entitlement_id] }

  delegate :name, to: :entitlement
  delegate :code, to: :entitlement
  delegate :metadata, to: :entitlement
end
