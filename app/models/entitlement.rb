# frozen_string_literal: true

class Entitlement < ApplicationRecord
  include Limitable
  include Pageable

  belongs_to :account
  has_many :license_entitlements, dependent: :delete_all
  has_many :policy_entitlements, dependent: :delete_all
  has_many :release_entitlement_constraints,
    inverse_of: :entitlement_constraints,
    dependent: :delete_all

  validates :account, presence: { message: 'must exist' }

  validates :code, presence: true, allow_blank: false, length: { minimum: 1, maximum: 255 }, uniqueness: { case_sensitive: false, scope: :account_id }
  validates :name, presence: true, allow_blank: false, length: { minimum: 1, maximum: 255 }
end
