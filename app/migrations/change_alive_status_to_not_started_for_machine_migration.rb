# frozen_string_literal: true

class ChangeAliveStatusToNotStartedForMachineMigration < BaseMigration
  description %(changes the ALIVE status to NOT_STARTED for a new Machine)

  migrate if: -> body { body in data: { ** } } do |body|
    case body
    in data: { type: /\Amachines\z/, attributes: { heartbeatStatus: 'ALIVE' } }
      body[:data][:attributes][:heartbeatStatus] = 'NOT_STARTED'
    else
    end
  end

  response if: -> res { res.status < 400 && res.request.params in controller: 'api/v1/machines',
                                                                  action: 'create' } do |res|
    body = JSON.parse(res.body, symbolize_names: true)

    migrate!(body)

    res.body = JSON.generate(body)
  end
end
