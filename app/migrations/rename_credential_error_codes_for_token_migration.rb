# frozen_string_literal: true

class RenameCredentialErrorCodesForTokenMigration < BaseMigration
  description %(renames the EMAIL/PASSWORD_REQUIRED, EMAIL/PASSWORD_INVALID and PASSWORD_NOT_SUPPORTED error codes to CREDENTIALS_INVALID when generating a new Token)

  migrate if: -> body { body in errors: [*] } do |body|
    case body
    in errors: [*, { code: 'EMAIL_REQUIRED' | 'EMAIL_INVALID' | 'PASSWORD_REQUIRED' | 'PASSWORD_INVALID' | 'PASSWORD_NOT_SUPPORTED' }, *] => errs
      errs.each do |err|
        next unless
          err in code: 'EMAIL_REQUIRED' | 'EMAIL_INVALID' | 'PASSWORD_REQUIRED' | 'PASSWORD_INVALID' | 'PASSWORD_NOT_SUPPORTED'

        err.merge!(
          detail: 'email and password must be valid',
          code: 'CREDENTIALS_INVALID',
        )
      end
    else
    end
  end

  response if: -> res { res.status == 401 && res.request.params in controller: 'api/v1/tokens',
                                                                   action: 'generate' } do |res|
    body = JSON.parse(res.body, symbolize_names: true)

    migrate!(body)

    res.body = JSON.generate(body)
  end
end
