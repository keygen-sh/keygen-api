# frozen_string_literal: true

module SignatureHeader
  extend ActiveSupport::Concern
  include Signable

  included do
    after_action :add_signature_header
  end

  def add_signature_header
    return if current_account.nil?

    response.headers["X-Signature"] = sign(
      key: current_account.private_key,
      data: response.body
    )
  end
end
