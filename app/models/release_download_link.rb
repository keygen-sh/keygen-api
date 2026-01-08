# frozen_string_literal: true

class ReleaseDownloadLink < ApplicationRecord
  include Environmental
  include Accountable
  include AsyncCreatable
  include Limitable
  include Orderable
  include Pageable

  belongs_to :release,
    counter_cache: :download_count,
    inverse_of: :download_links

  has_environment default: -> { release&.environment_id }
  has_account default: -> { release&.account_id }

  encrypts :url

  validates :release,
    scope: { by: :account_id }

  validates :url,
    presence: true
end
