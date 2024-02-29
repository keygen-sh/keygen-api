# frozen_string_literal: true

class RenameOwnerRelationshipToUserForLicenseMigration < BaseMigration
  description %(renames the owner relationship to user for a License)

  migrate if: -> body { body in data: { ** } } do |body|
    body => data:

    case data
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

  response if: -> res { res.status < 400 && res.status != 204 &&
                        res.request.params in controller: 'api/v1/licenses' | 'api/v1/licenses/actions/validations' | 'api/v1/licenses/actions/uses' | 'api/v1/licenses/actions/permits' |
                                                          'api/v1/licenses/relationships/v1x5/users' | 'api/v1/products/relationships/licenses' | 'api/v1/policies/relationships/licenses' |
                                                          'api/v1/users/relationships/licenses' | 'api/v1/groups/relationships/licenses' | 'api/v1/machines/relationships/licenses' |
                                                          'api/v1/machine_components/relationships/licenses' | 'api/v1/machine_processes/relationships/licenses',
                                              action: 'show' | 'create' | 'update' |
                                                      'quick_validate_by_id' | 'validate_by_key' | 'validate_by_id' |
                                                      'check_in' | 'renew' | 'revoke' | 'suspend' | 'reinstate' |
                                                      'increment' | 'decrement' | 'reset' } do |res|
    body = JSON.parse(res.body, symbolize_names: true)

    migrate!(body)

    res.body = JSON.generate(body)
  end
end
