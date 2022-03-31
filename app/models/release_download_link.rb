# frozen_string_literal: true

class ReleaseDownloadLink < ApplicationRecord
  include Limitable
  include Orderable
  include Pageable

  belongs_to :account
  belongs_to :release,
    counter_cache: :download_count,
    inverse_of: :download_links

  validates :release,
    scope: { by: :account_id }

  validates :url,
    presence: true
end
