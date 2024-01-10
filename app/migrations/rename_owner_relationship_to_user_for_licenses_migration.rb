# frozen_string_literal: true

class RenameOwnerRelationshipToUserForLicensesMigration < BaseMigration
  description %(renames the owner relationship to user for Licenses)

  migrate if: -> body { body in included: [*] } do |body|
    case body
    in included: [
      *,
      { type: /\Alicenses\z/, relationships: { ** } },
      *
    ] => includes
      includes.each do |record|
        case record
        in type: /\Alicenses\z/, id: license_id, relationships: { account: { data: { id: account_id } }, owner: { ** } } => rels
          rels[:user] = rels.delete(:owner)
                            .merge!(
                              links: {
                                related: v1_account_license_v1_5_user_path(account_id, license_id),
                              },
                            )
        else
        end
      end
    else
    end
  end

  migrate if: -> body { body in data: [*] } do |body|
    case body
    in data: [*, { type: /\Alicenses\z/, relationships: { ** } }, *] => data
      data.each do |license|
        case license
        in type: /\Alicenses\z/, id: license_id, relationships: { account: { data: { id: account_id } }, owner: { ** } } => rels
          rels[:user] = rels.delete(:owner)
                            .merge!(
                              links: {
                                related: v1_account_license_v1_5_user_path(account_id, license_id),
                              },
                            )
        else
        end
      end
    else
    end
  end

  response if: -> res { res.status < 400 && res.request.params in controller: 'api/v1/licenses' | 'api/v1/products/relationships/licenses' | 'api/v1/policies/relationships/licenses' |
                                                                              'api/v1/users/relationships/licenses' | 'api/v1/groups/relationships/licenses',
                                                                  action: 'index' } do |res|
    body = JSON.parse(res.body, symbolize_names: true)

    migrate!(body)

    res.body = JSON.generate(body)
  end
end
