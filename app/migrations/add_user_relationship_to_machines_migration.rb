# frozen_string_literal: true

class AddUserRelationshipToMachinesMigration < BaseMigration
  description %(adds user relationship to Machines)

  migrate if: -> body { body in included: [*] } do |body|
    case body
    in included: [
      *,
      { type: /\Amachines\z/, relationships: { account: { data: { type: /\Aaccounts\z/, id: _ } }, license: { data: { type: /\Alicenses\z/, id: _ } } } },
      *
    ] => includes
      account_ids = includes.collect { it[:relationships][:account][:data][:id] }.compact.uniq
      license_ids = includes.collect { it[:relationships][:license][:data][:id] }.compact.uniq

      licenses = License.where(account_id: account_ids, id: license_ids)
                        .select(:id, :user_id)
                        .group_by(&:id)

      includes.each do |record|
        case record
        in type: /\Amachines\z/, id: machine_id, relationships: { account: { data: { id: account_id } }, license: { data: { id: license_id } } } => rels
          license = licenses[license_id]&.first

          rels[:user] = {
            data: license&.owner_id? ? { type: :users, id: license.owner_id } : nil,
            links: {
              related: v1_account_machine_v1_5_user_path(account_id, machine_id),
            },
          }
        else
        end
      end
    else
    end
  end

  migrate if: -> body { body in data: [*] } do |body|
    case body
    in data: [
      *,
      { type: /\Amachines\z/, relationships: { account: { data: { type: /\Aaccounts\z/, id: _ } }, license: { data: { type: /\Alicenses\z/, id: _ } } } },
      *
    ] => data
      account_ids = data.collect { it[:relationships][:account][:data][:id] }.compact.uniq
      license_ids = data.collect { it[:relationships][:license][:data][:id] }.compact.uniq

      licenses = License.where(account_id: account_ids, id: license_ids)
                        .select(:id, :user_id)
                        .group_by(&:id)

      data.each do |machine|
        case machine
        in type: /\Amachines\z/, id: machine_id, relationships: { account: { data: { id: account_id } }, license: { data: { id: license_id } } } => rels
          license = licenses[license_id]&.first

          rels[:user] = {
            data: license&.owner_id? ? { type: :users, id: license.owner_id } : nil,
            links: {
              related: v1_account_machine_v1_5_user_path(account_id, machine_id),
            },
          }

          rels.delete(:owner)
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
