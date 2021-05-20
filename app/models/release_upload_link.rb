# frozen_string_literal: true

class ReleaseUploadLink < ApplicationRecord
  include Limitable
  include Pageable

  belongs_to :account
  belongs_to :release,
    inverse_of: :upload_links

  validates :account,
    presence: { message: 'must exist' }
  validates :release,
    presence: { message: 'must exist' }

  validates :url,
    presence: true
end
