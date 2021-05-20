# frozen_string_literal: true

class ReleaseDownloadLink < ApplicationRecord
  include Limitable
  include Pageable

  belongs_to :account
  belongs_to :release,
    counter_cache: :download_count,
    inverse_of: :download_links

  validates :account,
    presence: { message: 'must exist' }
  validates :release,
    presence: { message: 'must exist' }

  validates :url,
    presence: true
end
