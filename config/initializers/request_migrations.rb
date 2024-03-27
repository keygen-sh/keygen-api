# frozen_string_literal: true

MAJOR_API_VERSION,
MINOR_API_VERSION,
PATCH_API_VERSION,
*                   = Keygen.version.segments
CURRENT_API_VERSION = "#{MAJOR_API_VERSION}.#{MINOR_API_VERSION}"
DEFAULT_API_VERSION = CURRENT_API_VERSION

RequestMigrations.configure do |config|
  config.request_version_resolver = -> request {
    Current.account ||= ResolveAccountService.call(request:)

    request.headers['Keygen-Version']&.delete_prefix('v') ||
      Current.account&.api_version ||
      CURRENT_API_VERSION
  }

  config.current_version = CURRENT_API_VERSION
  config.versions        = {
    '1.5' => %i[
      rename_owner_relationship_to_user_for_licenses_migration
      rename_owner_relationship_to_user_for_license_migration
      rename_owner_not_found_error_code_for_license_migration
      add_user_relationship_to_machines_migration
      add_user_relationship_to_machine_migration
    ],
    '1.4' => %i[
      update_nested_key_casing_to_snakecase_for_metadata_migration
    ],
    '1.3' => %i[
      rename_machine_uniqueness_strategy_to_fingerprint_uniqueness_strategy_for_policies_migration
      rename_machine_uniqueness_strategy_to_fingerprint_uniqueness_strategy_for_policy_migration
      rename_machine_matching_strategy_to_fingerprint_matching_strategy_for_policies_migration
      rename_machine_matching_strategy_to_fingerprint_matching_strategy_for_policy_migration
      rename_keygen_id_headers_for_responses_migration
    ],
    '1.2' => %i[
      change_alive_status_to_not_started_for_machine_migration
    ],
    '1.1' => %i[
      adjust_validity_for_validation_codes_migration
      rename_code_to_constant_for_validation_migration
      add_concurrent_attribute_to_policies_migration
      add_concurrent_attribute_to_policy_migration
    ],
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

  config.logger = Rails.logger
end
