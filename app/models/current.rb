class Current < ActiveSupport::CurrentAttributes
  attribute :account,
            :bearer,
            :token,
            :resource

  attribute :request_id,
            :host,
            :ip
end
