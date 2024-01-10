# frozen_string_literal: true

class RenameOwnerRelationshipToUserForMachinesMigration < BaseMigration
  description %(renames the owner relationship to user for Machines)

  migrate if: -> body { body in included: [*] } do |body|
    case body
    in included: [
      *,
      { type: /\Amachines\z/, relationships: { ** } },
      *
    ] => includes
      includes.each do |record|
        case record
        in type: /\Amachines\z/, id: machine_id, relationships: { account: { data: { id: account_id } }, owner: { ** } } => rels
          rels[:user] = rels.delete(:owner)
                            .merge!(
                              links: {
                                related: v1_account_machine_v1_5_user_path(account_id, machine_id),
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
    in data: [*, { type: /\Amachines\z/, relationships: { ** } }, *] => data
      data.each do |machine|
        case machine
        in type: /\Amachines\z/, id: machine_id, relationships: { account: { data: { id: account_id } }, owner: { ** } } => rels
          rels[:user] = rels.delete(:owner)
                            .merge!(
                              links: {
                                related: v1_account_machine_v1_5_user_path(account_id, machine_id),
                              },
                            )
        else
        end
      end
    else
    end
  end

  response if: -> res { res.status < 400 && res.request.params in controller: 'api/v1/machines' | 'api/v1/licenses/relationships/machines' | 'api/v1/products/relationships/machines' |
                                                                              'api/v1/policies/relationships/machines' | 'api/v1/users/relationships/machines' | 'api/v1/groups/relationships/machines',
                                                                  action: 'index' } do |res|
    body = JSON.parse(res.body, symbolize_names: true)

    migrate!(body)

    res.body = JSON.generate(body)
  end
end
