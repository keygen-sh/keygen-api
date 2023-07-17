# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe Releases::ReleasePackagePolicy, type: :policy do
  subject { described_class.new(record, account:, environment:, bearer:, token:, release:) }

  with_role_authorization :admin do
    with_release_traits %i[packaged] do
      with_scenarios %i[accessing_a_release accessing_its_package] do
        with_token_authentication do
          with_permissions %w[package.read] do
            without_token_permissions { denies :show }

            allows :show
          end

          with_permissions %w[release.package.update] do
            without_token_permissions { denies :update }

            allows :update
          end

          with_wildcard_permissions do
            without_token_permissions do
              denies :show, :update
            end

            allows :show, :update
          end

          with_default_permissions do
            without_token_permissions do
              denies :show, :update
            end

            allows :show, :update
          end

          without_permissions do
            denies :show, :update
          end

          within_environment :isolated do
            with_bearer_and_token_trait :in_shared_environment do
              denies :show, :update
            end

            with_bearer_and_token_trait :in_nil_environment do
              denies :show, :update
            end

            allows :show, :update
          end

          within_environment :shared do
            with_bearer_and_token_trait :in_isolated_environment do
              denies :show, :update
            end

            with_bearer_and_token_trait :in_nil_environment do
              allows :show, :update
            end

            allows :show, :update
          end

          within_environment nil do
            with_bearer_and_token_trait :in_isolated_environment do
              denies :show, :update
            end

            with_bearer_and_token_trait :in_shared_environment do
              denies :show, :update
            end

            allows :show, :update
          end
        end
      end
    end

    with_scenarios %i[accessing_another_account accessing_a_release accessing_its_package] do
      with_token_authentication do
        with_permissions %w[package.read] do
          denies :show
        end

        with_permissions %w[release.package.update] do
          denies :update
        end

        with_wildcard_permissions do
          denies :show, :update
        end

        with_default_permissions do
          denies :show, :update
        end

        without_permissions do
          denies :show, :update
        end
      end
    end
  end

  with_role_authorization :environment do
    within_environment :self do
      with_release_traits %i[packaged] do
        with_scenarios %i[accessing_a_release accessing_its_package] do
          with_token_authentication do
            with_permissions %w[package.read] do
              without_token_permissions { denies :show }

              allows :show
            end

            with_permissions %w[release.package.update] do
              without_token_permissions { denies :update }

              allows :update
            end

            with_wildcard_permissions do
              allows :show, :update
            end

            with_default_permissions do
              allows :show, :update
            end

            without_permissions do
              denies :show, :update
            end
          end
        end
      end
    end

    with_release_traits %i[packaged] do
      with_scenarios %i[accessing_a_release accessing_its_package] do
        with_token_authentication do
          with_permissions %w[package.read] do
            without_token_permissions { denies :show }

            denies :show
          end

          with_permissions %w[release.package.update] do
            without_token_permissions { denies :update }

            denies :update
          end

          with_wildcard_permissions do
            denies :show, :update
          end

          with_default_permissions do
            denies :show, :update
          end

          without_permissions do
            denies :show, :update
          end
        end
      end
    end
  end

  with_role_authorization :product do
    with_release_traits %i[packaged] do
      with_scenarios %i[accessing_its_release accessing_its_package] do
        with_token_authentication do
          with_permissions %w[package.read] do
            without_token_permissions { denies :show }

            allows :show
          end

          with_permissions %w[release.package.update] do
            without_token_permissions { denies :update }

            allows :update
          end

          with_wildcard_permissions do
            allows :show, :update
          end

          with_default_permissions do
            allows :show, :update
          end

          without_permissions do
            denies :show, :update
          end
        end
      end

      with_scenarios %i[accessing_a_release accessing_its_package] do
        with_token_authentication do
          with_permissions %w[package.read] do
            without_token_permissions { denies :show }

            denies :show
          end

          with_permissions %w[release.package.update] do
            without_token_permissions { denies :update }

            denies :update
          end

          with_wildcard_permissions do
            denies :show, :update
          end

          with_default_permissions do
            denies :show, :update
          end

          without_permissions do
            denies :show, :update
          end
        end
      end
    end
  end

  with_role_authorization :license do
    with_release_traits %i[packaged] do
      with_scenarios %i[accessing_its_release accessing_its_package] do
        with_license_authentication do
          with_permissions %w[package.read] do
            allows :show
          end

          with_wildcard_permissions do
            denies :update
            allows :show
          end

          with_default_permissions do
            denies :update
            allows :show
          end

          without_permissions do
            denies :show, :update
          end
        end

        with_token_authentication do
          with_permissions %w[package.read] do
            without_token_permissions { denies :show }

            allows :show
          end

          with_wildcard_permissions do
            denies :update
            allows :show
          end

          with_default_permissions do
            denies :update
            allows :show
          end

          without_permissions do
            denies :show, :update
          end
        end
      end

      with_scenarios %i[accessing_a_release accessing_its_package] do
        with_license_authentication do
          with_permissions %w[package.read] do
            denies :show
          end

          with_wildcard_permissions do
            denies :show, :update
          end

          with_default_permissions do
            denies :show, :update
          end

          without_permissions do
            denies :show, :update
          end
        end

        with_token_authentication do
          with_permissions %w[package.read] do
            without_token_permissions { denies :show }

            denies :show
          end

          with_wildcard_permissions do
            denies :show, :update
          end

          with_default_permissions do
            denies :show, :update
          end

          without_permissions do
            denies :show, :update
          end
        end
      end
    end
  end

  with_role_authorization :user do
    with_bearer_trait :with_licenses do
      with_release_traits %i[packaged] do
        with_scenarios %i[accessing_its_release accessing_its_package] do
          with_token_authentication do
            with_permissions %w[package.read] do
              without_token_permissions { denies :show }

              allows :show
            end

            with_wildcard_permissions do
              denies :update
              allows :show
            end

            with_default_permissions do
              denies :update
              allows :show
            end

            without_permissions do
              denies :show, :update
            end
          end
        end
      end

      with_scenarios %i[accessing_a_release accessing_its_package] do
        with_token_authentication do
          with_permissions %w[package.read] do
            without_token_permissions { denies :show }

            denies :show
          end

          with_wildcard_permissions do
            denies :show, :update
          end

          with_default_permissions do
            denies :show, :update
          end

          without_permissions do
            denies :show, :update
          end
        end
      end
    end
  end

  without_authorization do
    with_release_traits %i[packaged open] do
      with_scenarios %i[accessing_a_release accessing_its_package] do
        without_authentication do
          allows :show
          denies :update
        end
      end
    end

    with_release_traits %i[packaged] do
      with_scenarios %i[accessing_a_release accessing_its_package] do
        without_authentication do
          denies :show, :update
        end
      end
    end
  end
end
