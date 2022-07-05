# frozen_string_literal: true

class AdjustValidityForValidationCodesMigration < BaseMigration
  # With v1.2, some validation codes such as TOO_MANY_MACHINES may now have a
  # validity that is true, rather than always being false, depending on the
  # policy's overage strategy. This reverses that breaking change.
  description %(adjusts validity of non-VALID or EXPIRED validation codes to be false)

  migrate if: -> body { body in meta: { ** } } do |body|
    case body
    in meta: { valid: true, code: }
      body[:meta][:valid] = code == 'VALID' || code == 'EXPIRED'
    else
    end
  end

  response if: -> res { res.status < 400 && res.request.params in controller: 'api/v1/licenses/actions/validations',
                                                                  action: 'quick_validate_by_id' | 'validate_by_id' | 'validate_by_key' } do |res|
    body = JSON.parse(res.body, symbolize_names: true)

    migrate!(body)

    res.body = JSON.generate(body)
  end
end
