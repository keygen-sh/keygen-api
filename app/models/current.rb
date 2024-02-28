class Current < ActiveSupport::CurrentAttributes
  attribute :account,
            :environment,
            :bearer,
            :token,
            :resource

  attribute :request_id,
            :host,
            :ip

  def account=(account)
    super

    # Ensure these are always reset when account is changed
    self.environment = nil
    self.bearer      = nil
    self.token       = nil
    self.resource    = nil
  end
end
