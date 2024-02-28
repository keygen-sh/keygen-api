# frozen_string_literal: true

class RenameOwnerNotFoundErrorCodeForLicenseMigration < BaseMigration
  description %(renames the OWNER_NOT_FOUND error code to USER_NOT_FOUND for a new or updated License)

  migrate if: -> body { body in errors: [*] } do |body|
    case body
    in errors: [*, { code: 'OWNER_NOT_FOUND' }, *] => errs
      errs.each do |err|
        next unless
          err in code: 'OWNER_NOT_FOUND'

        err.merge!(
          code: 'USER_NOT_FOUND',
          source: {
            pointer: '/data/relationships/user',
          },
        )
      end
    else
    end
  end

  response if: -> res { res.status == 422 && res.request.params in controller: 'api/v1/licenses' | 'api/v1/licenses/relationships/owners',
                                                                   action: 'create' | 'update' } do |res|
    body = JSON.parse(res.body, symbolize_names: true)

    migrate!(body)

    res.body = JSON.generate(body)
  end
end
