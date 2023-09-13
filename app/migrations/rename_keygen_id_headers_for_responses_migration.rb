# frozen_string_literal: true

class RenameKeygenIdHeadersForResponsesMigration < BaseMigration
  description %(renames Keygen-X headers to Keygen-X-Id for all responses)

  response do |res|
    res.headers['Keygen-Account-Id'] = res.headers.delete('Keygen-Account') if res.headers.key?('Keygen-Account')
    res.headers['Keygen-Bearer-Id']  = res.headers.delete('Keygen-Bearer')  if res.headers.key?('Keygen-Bearer')
    res.headers['Keygen-Token-Id']   = res.headers.delete('Keygen-Token')   if res.headers.key?('Keygen-Token')
  end
end
