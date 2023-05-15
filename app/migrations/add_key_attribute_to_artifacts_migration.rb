# frozen_string_literal: true

class AddKeyAttributeToArtifactsMigration < BaseMigration
  description %(adds key attributes to a collection of Artifacts)

  migrate if: -> body { body in data: [*] } do |body|
    case body
    in data: [*, { type: /\Aartifacts\z/, attributes: { ** } }, *]
      body[:data].each do |artifact|
        case artifact
        in type: /\Aartifacts\z/, attributes: { filename: }
          artifact[:attributes][:key] = filename
        else
        end
      end
    else
    end
  end

  response if: -> res { res.status < 400 && res.request.params in controller: 'api/v1/release_artifacts' | 'api/v1/products/relationships/release_artifacts' | 'api/v1/releases/relationships/release_artifacts',
                                                                  action: 'index' } do |res|
    body = JSON.parse(res.body, symbolize_names: true)

    migrate!(body)

    res.body = JSON.generate(body)
  end
end
