# frozen_string_literal: true

class AddProductRelationshipToArtifactMigration < BaseMigration
  description %(adds product relationship to an Artifact)

  migrate if: -> body { body in data: { ** } } do |body|
    case body
    in data: { type: /\Aartifacts\z/, id:, relationships: { account: { data: { type: /\Aaccounts\z/, id: account_id } } } }
      product_id = Product.joins(:release_artifacts)
                          .where(account_id:, release_artifacts: { id: })
                          .limit(1)
                          .pluck(:id)
                          .first

      body[:data][:relationships][:product] = {
        data: product_id.present? ? { type: :products, id: product_id } : nil,
        links: {
          related: v1_account_product_path(account_id, product_id),
        },
      }
    else
    end
  end

  response if: -> res { res.status < 400 && res.status != 204 &&
                        res.request.params in controller: 'api/v1/artifacts' | 'api/v1/products/relationships/artifacts' | 'api/v1/releases/relationships/artifacts' | 'api/v1/releases/relationships/v1x0/artifacts' | 'api/v1/releases/actions/v1x0/upgrades',
                                              action: 'show' | 'create' | 'update' | 'check_for_upgrade_by_query' | 'check_for_upgrade_by_id' } do |res|
    body = JSON.parse(res.body, symbolize_names: true)

    migrate!(body)

    res.body = JSON.generate(body)
  end
end
