# frozen_string_literal: true

class RenameFilenameExtErrorCodeForReleaseMigration < BaseMigration
  description %(renames the ARTIFACT_FILENAME_EXTENSION_INVALID error code to FILENAME_EXTENSION_INVALID for a new Release)

  migrate if: -> body { body in errors: [*] } do |body|
    case body
    in errors: [*, { code: 'ARTIFACT_FILENAME_EXTENSION_INVALID' }, *]
      body[:errors].each do |err|
        next unless
          err in code: 'ARTIFACT_FILENAME_EXTENSION_INVALID'

        err.merge!(
          code: 'FILENAME_EXTENSION_INVALID',
          source: {
            pointer: '/data/attributes/filename',
          },
        )
      end
    else
    end
  end

  response if: -> res { res.status == 422 && res.request.params in controller: 'api/v1/releases',
                                                                   action: 'create' } do |res|
    body = JSON.parse(res.body, symbolize_names: true)

    migrate!(body)

    res.body = JSON.generate(body)
  end
end
