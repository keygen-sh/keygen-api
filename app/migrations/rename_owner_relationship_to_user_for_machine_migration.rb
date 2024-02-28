# frozen_string_literal: true

class RenameOwnerRelationshipToUserForMachineMigration < BaseMigration
  description %(renames the owner relationship to user for a Machine)

  migrate if: -> body { body in data: { ** } } do |body|
    body => data:

    case data
    in type: /\Amachines\z/, id: machine_id, relationships: { account: { data: { id: account_id } }, owner: { ** } } => rels
      rels[:user] = rels.delete(:owner)
                        .merge!(
                          links: {
                            related: v1_account_machine_user_path(account_id, machine_id),
                          },
                        )
    else
    end
  end

  response if: -> res { res.status < 400 && res.request.params in controller: 'api/v1/machines' | 'api/v1/licenses/relationships/machines' | 'api/v1/products/relationships/machines' | 'api/v1/policies/relationships/machines' |
                                                                              'api/v1/users/relationships/machines' | 'api/v1/groups/relationships/machines' | 'api/v1/machine_components/relationships/machines' |
                                                                              'api/v1/machine_processes/relationships/machines',
                                                                  action: 'show' | 'create' | 'update' } do |res|
    body = JSON.parse(res.body, symbolize_names: true)

    migrate!(body)

    res.body = JSON.generate(body)
  end
end
