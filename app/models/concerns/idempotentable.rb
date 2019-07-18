# frozen_string_literal: true

module Idempotentable
  extend ActiveSupport::Concern
  include Tokenable

  included do
    after_initialize :set_idempotency_token, if: -> { idempotency_token.nil? }
  end

  private

  def set_idempotency_token
    self.idempotency_token = generate_token :idempotency_token, length: 32
  end
end
