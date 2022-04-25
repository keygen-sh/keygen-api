# frozen_string_literal: true

require_dependency Rails.root.join('lib', 'versionist')

Versionist.configure do |config|
  config.current_version = KEYGEN_API_VERSION
  config.versions        = {
    '1.0' => [
      :artifact_has_many_to_has_one_for_releases_migration,
      :artifact_has_many_to_has_one_for_release_migration,
    ],
  }
end
