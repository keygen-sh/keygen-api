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

  def account_id    = account&.id
  def bearer_type   = bearer&.class&.name
  def bearer_id     = bearer&.id
  def token_id      = token&.id
  def resource_type = resource&.class&.name
  def resource_id   = resource&.id
end
