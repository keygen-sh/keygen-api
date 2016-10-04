require "uri"

class Webhook < ApplicationRecord
  belongs_to :account

  validates :account, presence: { message: "must exist" }
  validates :endpoint, presence: true, format: URI::regexp(%w[http https])
end
