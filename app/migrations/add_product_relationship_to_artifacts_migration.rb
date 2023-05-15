# frozen_string_literal: true

class AddProductRelationshipToArtifactsMigration < BaseMigration
  description %(adds product relationship to a collection of Artifacts)

  migrate if: -> body { body in data: [*] } do |body|
    case body
    in data: [*, { type: /\Aartifacts\z/, id: _, relationships: { account: { data: { type: /\Aaccounts\z/, id: _ } } } }, *]
      account_ids  = body[:data].collect { _1[:relationships][:account][:data][:id] }.compact.uniq
      artifact_ids = body[:data].collect { _1[:id] }.compact.uniq

      products = Product.joins(:release_artifacts)
                        .where(account_id: account_ids, release_artifacts: { id: artifact_ids })
                        .select(:id, 'release_artifacts.id as artifact_id')
                        .group_by(&:artifact_id)

      body[:data].each do |artifact|
        case artifact
        in type: /\Aartifacts\z/, id: artifact_id, relationships: { account: { data: { type: /\Aaccounts\z/, id: account_id } } }
          product = products[artifact_id]&.first

          artifact[:relationships][:product] = {
            data: product.present? ? { type: :products, id: product.id } : nil,
            links: {
              related: v1_account_product_path(account_id, product.id),
            },
          }
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
