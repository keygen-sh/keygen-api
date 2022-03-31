# frozen_string_literal: true

class ReleaseUploadLink < ApplicationRecord
  include Limitable
  include Orderable
  include Pageable

  belongs_to :account
  belongs_to :release,
    inverse_of: :upload_links

  validates :release,
    scope: { by: :account_id }

  validates :url,
    presence: true
end
