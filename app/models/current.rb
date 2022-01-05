class Current < ActiveSupport::CurrentAttributes
  attribute :account,
            :bearer,
            :token,
            :resource

  attribute :request_id,
            :host,
            :ip

  def account=(account)
    super

    # Ensure these are always reset when account is changed
    self.bearer   = nil
    self.token    = nil
    self.resource = nil
  end
end
