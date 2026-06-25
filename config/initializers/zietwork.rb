# frozen_string_literal: true

Rails.autoloaders.each do |autoloader|
  autoloader.collapse(
    # NB(ezekg) the clickhouse/ directory is only for organizational purposes to facilitate below
    Rails.root.join('app/models/clickhouse'),
  )

  # avoid eager loading analytics models in environments that don't have clickhouse
  unless Keygen.database.clickhouse_available? && Keygen.database.clickhouse_enabled?
    autoloader.do_not_eager_load(
      Rails.root.join('app/models/clickhouse_record.rb'),
      Rails.root.join('app/models/clickhouse'),
      Rails.root.join('app/models/analytics'),
    )
  end

  # FIXME(ezekg) should we rename these to follow conventions?
  autoloader.inflector.inflect(
    'enumerator_io' => 'EnumeratorIO',
    'digest_io' => 'DigestIO',
    'jsonapi' => 'JSONAPI',
    'ee' => 'EE',
    'sso' => 'SSO',
  )
end
