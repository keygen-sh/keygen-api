# frozen_string_literal: true

class ReleaseUpgradeLink < ApplicationRecord
  include Limitable
  include Pageable

  belongs_to :account
  belongs_to :release,
    counter_cache: :upgrade_count,
    inverse_of: :upgrade_links

  validates :account,
    presence: { message: 'must exist' }
  validates :release,
    presence: { message: 'must exist' },
    scope: { by: :account_id }

  validates :url,
    presence: true
end
