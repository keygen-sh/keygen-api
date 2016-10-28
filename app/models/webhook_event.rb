class WebhookEvent < ApplicationRecord
  include Paginatable

  belongs_to :account

  validates :account, presence: { message: "must exist" }
  validates :endpoint, url: true, presence: true
  validates :jid, presence: true, uniqueness: true

  def status
    Sidekiq::Status.status jid rescue :unavailable
  end
end
