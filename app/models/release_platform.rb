# frozen_string_literal: true

class ReleasePlatform < ApplicationRecord
  include Limitable
  include Pageable

  belongs_to :account,
    inverse_of: :release_platforms
  has_many :releases,
    inverse_of: :platform

  validates :account,
    presence: { message: 'must exist' }

  validates :key,
    presence: true,
    uniqueness: { message: 'already exists', scope: :account_id }
end
