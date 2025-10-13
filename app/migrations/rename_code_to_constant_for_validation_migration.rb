# frozen_string_literal: true

class RenameCodeToConstantForValidationMigration < BaseMigration
  description %(renames the code key to constant for a validation)

  migrate if: -> body { body in meta: { ** } } do |body|
    case body
    in meta: { code: }
      body[:meta].tap { it[:constant] = it.delete(:code) }
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
