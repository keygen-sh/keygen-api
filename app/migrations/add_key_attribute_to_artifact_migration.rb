# frozen_string_literal: true

class AddKeyAttributeToArtifactMigration < BaseMigration
  description %(adds key attribute to an Artifact)

  migrate if: -> body { body in data: { ** } } do |body|
    case body
    in data: { type: /\Aartifacts\z/, attributes: { filename: } }
      body[:data][:attributes][:key] = filename
    else
    end
  end

  response if: -> res { res.status < 400 && res.status != 204 &&
                        res.request.params in controller: 'api/v1/release_artifacts' | 'api/v1/products/relationships/release_artifacts' | 'api/v1/releases/relationships/release_artifacts' | 'api/v1/releases/relationships/v1x0/release_artifacts' | 'api/v1/releases/actions/v1x0/upgrades',
                                              action: 'show' | 'create' | 'update' | 'check_for_upgrade_by_query' | 'check_for_upgrade_by_id' } do |res|
    body = JSON.parse(res.body, symbolize_names: true)

    migrate!(body)

    res.body = JSON.generate(body)
  end
end
