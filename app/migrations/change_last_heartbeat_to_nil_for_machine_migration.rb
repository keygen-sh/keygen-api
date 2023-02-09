# frozen_string_literal: true

class ChangeLastHeartbeatToNilForMachineMigration < BaseMigration
  description %(changes lastHeartbeat to nil for a new Machine)

  migrate if: -> body { body in data: { ** } } do |body|
    case body
    in data: { type: /\Amachines\z/, attributes: { lastHeartbeat: String | Time } }
      body[:data][:attributes][:lastHeartbeat] = nil
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
