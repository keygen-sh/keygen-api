# frozen_string_literal: true

class AddUserRelationshipToMachineMigration < BaseMigration
  description %(adds user relationship to a Machine)

  migrate if: -> body { body in data: { ** } } do |body|
    body => data:

    case data
    in type: /\Amachines\z/, id: machine_id, relationships: { account: { data: { id: account_id } }, license: { data: { id: license_id } } } => rels
      license_owner_id, * = License.where(id: license_id, account_id:)
                                   .limit(1)
                                   .pluck(:user_id)

      rels[:user] = {
        data: license_owner_id.present? ? { type: :users, id: license_owner_id } : nil,
        links: {
          related: v1_account_machine_v1_5_user_path(account_id, machine_id),
        },
      }

      rels.delete(:owner)
    else
    end
  end

  response if: -> res { res.status < 400 && res.request.params in controller: 'api/v1/machines' | 'api/v1/machines/actions/v1x0/proofs' | 'api/v1/machines/actions/heartbeats' | 'api/v1/machines/relationships/groups' |
                                                                              'api/v1/licenses/relationships/machines' | 'api/v1/products/relationships/machines' | 'api/v1/policies/relationships/machines' |
                                                                              'api/v1/users/relationships/machines' | 'api/v1/groups/relationships/machines' | 'api/v1/machine_components/relationships/machines' |
                                                                              'api/v1/machine_processes/relationships/machines',
                                                                  action: 'show' | 'create' | 'update' | 'ping' } do |res|
    body = JSON.parse(res.body, symbolize_names: true)

    migrate!(body)

    res.body = JSON.generate(body)
  end
end
