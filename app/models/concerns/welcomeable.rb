module Welcomeable
  extend ActiveSupport::Concern

  included do
    # TODO: This is disabled while we're in the beta period
    after_create :send_welcome_email
  end

  def send_welcome_email
    AccountMailer.welcome(account: self).deliver_later
  rescue Redis::CannotConnectError
    false
  end
end
