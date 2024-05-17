class Current < ActiveSupport::CurrentAttributes
  attribute :account,
            :environment,
            :bearer,
            :token,
            :resource

  attribute :api_version,
            :request_id,
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

  def account_id     = account&.id
  def environment_id = environment&.id
  def bearer_id      = bearer&.id
  def token_id       = token&.id
  def resource_id    = resource&.id
end
