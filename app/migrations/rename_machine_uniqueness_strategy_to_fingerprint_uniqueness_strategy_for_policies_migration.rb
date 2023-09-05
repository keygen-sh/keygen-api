# frozen_string_literal: true

class RenameMachineUniquenessStrategyToFingerprintUniquenessStrategyForPoliciesMigration < BaseMigration
  description %(renames machine uniqueness strategy to fingerprint uniqueness strategy for Policies)

  migrate if: -> body { body in data: [*] } do |body|
    case body
    in data: [
      *,
      { type: /\Apolicies\z/, attributes: { machineUniquenessStrategy: String } },
      *
    ] => data
      data.each do |policy|
        case policy
        in type: /\Apolicies\z/, attributes: { machineUniquenessStrategy: String } => attrs
          attrs[:fingerprintUniquenessStrategy] = attrs.delete(:machineUniquenessStrategy)
        else
        end
      end
    else
    end
  end

  response if: -> res { res.status < 400 && res.request.params in controller: 'api/v1/policies' | 'api/v1/products/relationships/policies',
                                                                  action: 'index' } do |res|
    body = JSON.parse(res.body, symbolize_names: true)

    migrate!(body)

    res.body = JSON.generate(body)
  end
end
