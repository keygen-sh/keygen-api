# frozen_string_literal: true

class RenameMachineMatchingStrategyToFingerprintMatchingStrategyForPoliciesMigration < BaseMigration
  description %(renames machine matching strategy to fingerprint matching strategy for Policies)

  migrate if: -> body { body in data: [*] } do |body|
    case body
    in data: [
      *,
      { type: /\Apolicies\z/, attributes: { machineMatchingStrategy: String } },
      *
    ] => data
      data.each do |policy|
        case policy
        in type: /\Apolicies\z/, attributes: { machineMatchingStrategy: String } => attrs
          attrs[:fingerprintMatchingStrategy] = attrs.delete(:machineMatchingStrategy)
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
