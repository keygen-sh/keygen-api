# frozen_string_literal: true

module Welcomeable
  extend ActiveSupport::Concern

  included do
    attr_accessor :skip_welcome_email

    after_commit :send_welcome_email, on: :create,
      unless: -> { skip_welcome_email? || free_or_disposable_domain? },
      if: -> { Keygen.multiplayer? }
  end

  def skip_welcome_email? = !!skip_welcome_email
  def send_welcome_email
    PlaintextMailer.prompt_for_first_impression(account: self)
                   .deliver_later(wait: rand(2..5).days)
  end
end
