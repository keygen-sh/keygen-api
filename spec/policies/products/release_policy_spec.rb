# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe Products::ReleasePolicy, type: :policy do
  subject { described_class.new(record, account:, environment:, bearer:, token:, product:) }

  with_role_authorization :admin do
    with_scenarios %i[accessing_a_product accessing_its_releases] do
      with_token_authentication do
        with_permissions %w[release.read] do
          without_token_permissions { denies :index }

          allows :index
        end

        with_wildcard_permissions { allows :index }
        with_default_permissions  { allows :index }
        without_permissions       { denies :index }

        within_environment :isolated do
          with_bearer_and_token_trait :in_shared_environment do
            denies :index
          end

          with_bearer_and_token_trait :in_nil_environment do
            denies :index
          end

          allows :index
        end

        within_environment :shared do
          with_bearer_and_token_trait :in_isolated_environment do
            denies :index
          end

          with_bearer_and_token_trait :in_nil_environment do
            allows :index
          end

          allows :index
        end

        within_environment nil do
          with_bearer_and_token_trait :in_isolated_environment do
            denies :index
          end

          with_bearer_and_token_trait :in_shared_environment do
            denies :index
          end

          allows :index
        end
      end
    end

    with_scenarios %i[accessing_a_product accessing_its_release] do
      with_token_authentication do
        with_permissions %w[release.read] do
          without_token_permissions { denies :show }

          allows :show
        end

        with_wildcard_permissions do
          without_token_permissions { denies :show }

          allows :show
        end

        with_default_permissions do
          without_token_permissions { denies :show }

          allows :show
        end

        without_permissions do
          denies :show
        end

        within_environment :isolated do
          with_bearer_and_token_trait :in_shared_environment do
            denies :show
          end

          with_bearer_and_token_trait :in_nil_environment do
            denies :show
          end

          allows :show
        end

        within_environment :shared do
          with_bearer_and_token_trait :in_isolated_environment do
            denies :show
          end

          with_bearer_and_token_trait :in_nil_environment do
            allows :show
          end

          allows :show
        end

        within_environment nil do
          with_bearer_and_token_trait :in_isolated_environment do
            denies :show
          end

          with_bearer_and_token_trait :in_shared_environment do
            denies :show
          end

          allows :show
        end
      end
    end
  end

  with_role_authorization :environment do
    within_environment :self do
      with_scenarios %i[accessing_a_product accessing_its_releases] do
        with_token_authentication do
          with_permissions %w[release.read] do
            without_token_permissions { denies :show }

            allows :show
          end

          with_wildcard_permissions { allows :index }
          with_default_permissions  { allows :index }
          without_permissions       { denies :index }
        end
      end

      with_scenarios %i[accessing_a_product accessing_its_release] do
        with_token_authentication do
          with_permissions %w[release.read] do
            without_token_permissions { denies :show }

            allows :show
          end

          with_wildcard_permissions do
            without_token_permissions { denies :show }

            allows :show
          end

          with_default_permissions do
            without_token_permissions { denies :show }

            allows :show
          end

          without_permissions do
            denies :show
          end
        end
      end
    end

    with_scenarios %i[accessing_a_product accessing_its_releases] do
      with_token_authentication do
        with_permissions %w[release.read] do
          denies :show
        end

        with_wildcard_permissions { denies :index }
        with_default_permissions  { denies :index }
        without_permissions       { denies :index }
      end
    end

    with_scenarios %i[accessing_a_product accessing_its_release] do
      with_token_authentication do
        with_permissions %w[release.read] do
          denies :show
        end

        with_wildcard_permissions do
          denies :show
        end

        with_default_permissions do
          denies :show
        end

        without_permissions do
          denies :show
        end
      end
    end
  end

  with_role_authorization :product do
    with_scenarios %i[accessing_itself accessing_its_releases] do
      with_token_authentication do
        with_permissions %w[release.read] do
          without_token_permissions { denies :show }

          allows :show
        end

        with_wildcard_permissions { allows :index }
        with_default_permissions  { allows :index }
        without_permissions       { denies :index }
      end
    end

    with_scenarios %i[accessing_itself accessing_its_release] do
      with_token_authentication do
        with_permissions %w[release.read] do
          without_token_permissions { denies :show }

          allows :show
        end

        with_wildcard_permissions do
          without_token_permissions { denies :show }

          allows :show
        end

        with_default_permissions do
          without_token_permissions { denies :show }

          allows :show
        end

        without_permissions do
          denies :show
        end
      end
    end

    with_scenarios %i[accessing_a_product accessing_its_releases] do
      with_token_authentication do
        with_permissions %w[release.read] do
          denies :show
        end

        with_wildcard_permissions { denies :index }
        with_default_permissions  { denies :index }
        without_permissions       { denies :index }
      end
    end

    with_scenarios %i[accessing_a_product accessing_its_release] do
      with_token_authentication do
        with_permissions %w[release.read] do
          denies :show
        end

        with_wildcard_permissions do
          denies :show
        end

        with_default_permissions do
          denies :show
        end

        without_permissions do
          denies :show
        end
      end
    end
  end

  with_role_authorization :license do
    with_scenarios %i[accessing_its_product accessing_its_releases] do
      with_license_authentication do
        with_permissions %w[release.read] do
          allows :index
        end

        with_wildcard_permissions { allows :index }
        with_default_permissions  { allows :index }
        without_permissions       { denies :index }
      end

      with_token_authentication do
        with_permissions %w[release.read] do
          allows :index
        end

        with_wildcard_permissions { allows :index }
        with_default_permissions  { allows :index }
        without_permissions       { denies :index }
      end
    end

    with_scenarios %i[accessing_its_product accessing_its_release] do
      with_license_authentication do
        with_release_traits %i[created_last_year] do
          with_bearer_traits %i[expired restrict_access_expiration_strategy] do
            allows :show
          end

          with_bearer_traits %i[expired revoke_access_expiration_strategy] do
            denies :show
          end

          with_bearer_traits %i[expired maintain_access_expiration_strategy] do
            allows :show
          end

          with_bearer_traits %i[expired allow_access_expiration_strategy] do
            allows :show
          end
        end

        with_release_traits %i[with_constraints] do
          with_bearer_traits %i[with_entitlements] do
            allows :show
          end

          denies :show
        end

        with_bearer_traits %i[expired restrict_access_expiration_strategy] do
          denies :show
        end

        with_bearer_traits %i[expired revoke_access_expiration_strategy] do
          denies :show
        end

        with_bearer_traits %i[expired maintain_access_expiration_strategy] do
          denies :show
        end

        with_bearer_traits %i[expired allow_access_expiration_strategy] do
          allows :show
        end

        with_bearer_traits %i[expired] do
          denies :show
        end

        with_permissions %w[release.read] do
          allows :show
        end

        with_wildcard_permissions do
          allows :show
        end

        with_default_permissions do
          allows :show
        end

        without_permissions do
          denies :show
        end
      end

      with_token_authentication do
        with_permissions %w[release.read] do
          without_token_permissions { denies :show }

          allows :show
        end

        with_wildcard_permissions do
          without_token_permissions { denies :show }

          allows :show
        end

        with_default_permissions do
          without_token_permissions { denies :show }

          allows :show
        end

        without_permissions do
          denies :show
        end
      end
    end

    with_scenarios %i[accessing_a_product accessing_its_releases] do
      with_license_authentication do
        with_permissions %w[release.read] do
          denies :index
        end

        with_wildcard_permissions { denies :index }
        with_default_permissions  { denies :index }
        without_permissions       { denies :index }
      end

      with_token_authentication do
        with_permissions %w[release.read] do
          denies :index
        end

        with_wildcard_permissions { denies :index }
        with_default_permissions  { denies :index }
        without_permissions       { denies :index }
      end
    end

    with_scenarios %i[accessing_a_product accessing_its_release] do
      with_license_authentication do
        with_permissions %w[release.read] do
          denies :show
        end

        with_wildcard_permissions do
          denies :show
        end

        with_default_permissions do
          denies :show
        end

        without_permissions do
          denies :show
        end
      end

      with_token_authentication do
        with_permissions %w[release.read] do
          denies :show
        end

        with_wildcard_permissions do
          denies :show
        end

        with_default_permissions do
          denies :show
        end

        without_permissions do
          denies :show
        end
      end
    end
  end

  with_role_authorization :user do
    with_bearer_trait :with_licenses do
      with_scenarios %i[accessing_its_product accessing_its_releases] do
        with_token_authentication do
          with_permissions %w[release.read] do
            allows :index
          end

          with_wildcard_permissions { allows :index }
          with_default_permissions  { allows :index }
          without_permissions       { denies :index }
        end
      end

      with_scenarios %i[accessing_its_product accessing_its_release] do
        with_token_authentication do
          with_permissions %w[release.read] do
            without_token_permissions { denies :show }

            allows :show
          end

          with_wildcard_permissions do
            without_token_permissions { denies :show }

            allows :show
          end

          with_default_permissions do
            without_token_permissions { denies :show }

            allows :show
          end

          without_permissions do
            denies :show
          end
        end
      end
    end

    with_scenarios %i[accessing_a_product accessing_its_releases] do
      with_token_authentication do
        with_permissions %w[release.read] do
          denies :index
        end

        with_wildcard_permissions { denies :index }
        with_default_permissions  { denies :index }
        without_permissions       { denies :index }
      end
    end

    with_scenarios %i[accessing_a_product accessing_its_release] do
      with_token_authentication do
        with_permissions %w[release.read] do
          denies :show
        end

        with_wildcard_permissions do
          denies :show
        end

        with_default_permissions do
          denies :show
        end

        without_permissions do
          denies :show
        end
      end
    end
  end

  without_authorization do
    with_scenarios %i[accessing_a_product accessing_its_releases] do
      without_authentication do
        denies :index
      end
    end

    with_scenarios %i[accessing_a_product accessing_its_release] do
      without_authentication do
        denies :show
      end
    end
  end
end
