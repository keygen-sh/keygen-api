module Welcomeable
  extend ActiveSupport::Concern

  included do
    after_commit :send_welcome_email, on: :create
  end

  def send_welcome_email
    AccountMailer.welcome(account: self).deliver_later
  end
end
