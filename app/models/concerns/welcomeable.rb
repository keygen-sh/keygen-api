# frozen_string_literal: true

module Welcomeable
  extend ActiveSupport::Concern

  included do
    after_commit :send_welcome_email, on: :create
  end

  def send_welcome_email
    PlaintextMailer.prompt_for_first_impression(account: self)
                   .deliver_later(wait: rand(2..5).days)
  end
end
