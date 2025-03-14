# frozen_string_literal: true

Rails.autoloaders.each do |autoloader|
  # FIXME(ezekg) Should we rename these to follow conventions?
  autoloader.inflector.inflect(
    'enumerator_io' => 'EnumeratorIO',
    'digest_io' => 'DigestIO',
    'jsonapi' => 'JSONAPI',
    'ee' => 'EE',
    'sso' => 'SSO',
  )
end
