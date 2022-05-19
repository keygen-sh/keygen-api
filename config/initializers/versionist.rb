# frozen_string_literal: true

require_dependency Rails.root.join('lib', 'versionist')

Versionist.configure do |config|
  config.request_version_resolver = -> request {
    Current.account ||= ResolveAccountService.call(request:)

    request.headers['Keygen-Version']&.delete_prefix('v') ||
      Current.account&.api_version ||
      KEYGEN_API_VERSION
  }

  config.current_version = KEYGEN_API_VERSION
  config.versions        = {
    '1.0' => %i[
      artifact_has_many_to_has_one_for_releases_migration
      artifact_has_many_to_has_one_for_release_migration
      copy_artifact_attributes_to_releases_migration
      copy_artifact_attributes_to_release_migration
      rename_draft_status_to_not_published_for_releases_migration
      rename_draft_status_to_not_published_for_release_migration
      rename_filename_ext_error_code_for_release_migration
      add_key_attribute_to_artifacts_migration
      add_key_attribute_to_artifact_migration
      add_product_relationship_to_artifacts_migration
      add_product_relationship_to_artifact_migration
    ],
  }
end
