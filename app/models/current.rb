class Current < ActiveSupport::CurrentAttributes
  attribute :account,
            :environment,
            :bearer,
            :session,
            :token,
            :resource

  attribute :api_version,
            :request_id,
            :host,
            :ip

  def account=(account)
    super

    # ensure these are always reset when account is changed
    self.environment = nil
    self.bearer      = nil
    self.session     = nil
    self.token       = nil
    self.resource    = nil
  end

  def account_id     = account&.id
  def environment_id = environment&.id
  def bearer_type    = bearer&.class&.name
  def bearer_id      = bearer&.id
  def session_id     = session&.id
  def token_id       = token&.id
  def resource_type  = resource&.class&.name
  def resource_id    = resource&.id
end
