# frozen_string_literal: true

class ReleaseUploadLink < ApplicationRecord
  include Environmental
  include Accountable
  include Limitable
  include Orderable
  include Pageable

  belongs_to :release,
    inverse_of: :upload_links

  has_environment default: -> { release&.environment_id }
  has_account default: -> { release&.account_id }

  encrypts :url

  validates :release,
    scope: { by: :account_id }

  validates :url,
    presence: true
end
