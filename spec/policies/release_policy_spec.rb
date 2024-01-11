# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe ReleasePolicy, type: :policy do
  subject { described_class.new(record, account:, environment:, bearer:, token:) }

  with_role_authorization :admin do
    with_scenarios %i[accessing_releases] do
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

    with_scenarios %i[accessing_a_release] do
      with_token_authentication do
        with_permissions %w[release.upgrade] do
          without_token_permissions { denies :upgrade }

          allows :upgrade
        end

        with_permissions %w[release.read] do
          without_token_permissions { denies :show }

          allows :show
        end

        with_permissions %w[release.create] do
          without_token_permissions { denies :create }

          allows :create
        end

        with_permissions %w[release.update] do
          without_token_permissions { denies :update }

          allows :update
        end

        with_permissions %w[release.delete] do
          without_token_permissions { denies :destroy }

          allows :destroy
        end

        with_permissions %w[release.upload] do
          without_token_permissions { denies :upload }

          allows :upload
        end

        with_permissions %w[release.publish] do
          without_token_permissions { denies :publish }

          allows :publish
        end

        with_permissions %w[release.yank] do
          without_token_permissions { denies :yank }

          allows :yank
        end

        with_wildcard_permissions do
          without_token_permissions do
            denies :show, :upgrade, :create, :update, :destroy, :upload, :publish, :yank
          end

          allows :show, :upgrade, :create, :update, :destroy, :upload, :publish, :yank
        end

        with_default_permissions do
          without_token_permissions do
            denies :show, :upgrade, :create, :update, :destroy, :upload, :publish, :yank
          end

          allows :show, :upgrade, :create, :update, :destroy, :upload, :publish, :yank
        end

        without_permissions do
          denies :show, :upgrade, :create, :update, :destroy, :upload, :publish, :yank
        end

        within_environment :isolated do
          with_bearer_and_token_trait :in_shared_environment do
            denies :show, :upgrade, :create, :update, :destroy, :upload, :publish, :yank
          end

          with_bearer_and_token_trait :in_nil_environment do
            denies :show, :upgrade, :create, :update, :destroy, :upload, :publish, :yank
          end

          allows :show, :upgrade, :create, :update, :destroy, :upload, :publish, :yank
        end

        within_environment :shared do
          with_bearer_and_token_trait :in_isolated_environment do
            denies :show, :upgrade, :create, :update, :destroy, :upload, :publish, :yank
          end

          with_bearer_and_token_trait :in_nil_environment do
            allows :show, :upgrade, :create, :update, :destroy, :upload, :publish, :yank
          end

          with_release_trait :in_nil_environment do
            denies :create, :update, :destroy, :upload, :publish, :yank
            allows :show, :upgrade
          end

          allows :show, :upgrade, :create, :update, :destroy, :upload, :publish, :yank
        end

        within_environment nil do
          with_bearer_and_token_trait :in_isolated_environment do
            denies :show, :upgrade, :create, :update, :destroy, :upload, :publish, :yank
          end

          with_bearer_and_token_trait :in_shared_environment do
            denies :show, :upgrade, :create, :update, :destroy, :upload, :publish, :yank
          end

          allows :show, :upgrade, :create, :update, :destroy, :upload, :publish, :yank
        end
      end
    end

    with_scenarios %i[accessing_another_account accessing_releases] do
      with_token_authentication do
        with_permissions %w[release.read] do
          denies :index
        end

        with_wildcard_permissions { denies :index }
        with_default_permissions  { denies :index }
        without_permissions       { denies :index }
      end
    end

    with_scenarios %i[accessing_another_account accessing_a_release] do
      with_token_authentication do
        with_permissions %w[release.upgrade] do
          denies :upgrade
        end

        with_permissions %w[release.read] do
          denies :show
        end

        with_permissions %w[release.create] do
          denies :create
        end

        with_permissions %w[release.update] do
          denies :update
        end

        with_permissions %w[release.delete] do
          denies :destroy
        end

        with_permissions %w[release.upload] do
          denies :upload
        end

        with_permissions %w[release.publish] do
          denies :publish
        end

        with_permissions %w[release.yank] do
          denies :yank
        end

        with_wildcard_permissions do
          denies :show, :upgrade, :create, :update, :destroy, :upload, :publish, :yank
        end

        with_default_permissions do
          denies :show, :upgrade, :create, :update, :destroy, :upload, :publish, :yank
        end

        without_permissions do
          denies :show, :upgrade, :create, :update, :destroy, :upload, :publish, :yank
        end
      end
    end
  end

  with_role_authorization :environment do
    within_environment :self do
      with_scenarios %i[accessing_releases] do
        with_token_authentication do
          with_permissions %w[release.read] do
            without_token_permissions { denies :index }

            allows :index
          end

          with_wildcard_permissions { allows :index }
          with_default_permissions  { allows :index }
          without_permissions       { denies :index }

          within_environment :isolated do
            with_bearer_and_token_trait :isolated do
              with_release_trait :in_shared_environment do
                denies :index
              end

              with_release_trait :in_nil_environment do
                denies :index
              end

              allows :index
            end

            with_bearer_and_token_trait :shared do
              denies :index
            end
          end

          within_environment :shared do
            with_bearer_and_token_trait :isolated do
              denies :index
            end

            with_bearer_and_token_trait :shared do
              with_release_trait :in_isolated_environment do
                denies :index
              end

              with_release_trait :in_nil_environment do
                allows :index
              end

              allows :index
            end
          end

          within_environment nil do
            with_bearer_and_token_trait :isolated do
              denies :index
            end

            with_bearer_and_token_trait :shared do
              denies :index
            end
          end
        end
      end

      with_scenarios %i[accessing_a_release] do
        with_token_authentication do
          with_permissions %w[release.upgrade] do
            without_token_permissions { denies :upgrade }

            allows :upgrade
          end

          with_permissions %w[release.read] do
            without_token_permissions { denies :show }

            allows :show
          end

          with_permissions %w[release.create] do
            without_token_permissions { denies :create }

            allows :create
          end

          with_permissions %w[release.update] do
            without_token_permissions { denies :update }

            allows :update
          end

          with_permissions %w[release.delete] do
            without_token_permissions { denies :destroy }

            allows :destroy
          end

          with_permissions %w[release.upload] do
            without_token_permissions { denies :upload }

            allows :upload
          end

          with_permissions %w[release.publish] do
            without_token_permissions { denies :publish }

            allows :publish
          end

          with_permissions %w[release.yank] do
            without_token_permissions { denies :yank }

            allows :yank
          end

          with_wildcard_permissions do
            without_token_permissions do
              denies :show, :upgrade, :create, :update, :destroy, :upload, :publish, :yank
            end

            allows :show, :upgrade, :create, :update, :destroy, :upload, :publish, :yank
          end

          with_default_permissions do
            without_token_permissions do
              denies :show, :upgrade, :create, :update, :destroy, :upload, :publish, :yank
            end

            allows :show, :upgrade, :create, :update, :destroy, :upload, :publish, :yank
          end

          without_permissions do
            denies :show, :upgrade, :create, :update, :destroy, :upload, :publish, :yank
          end

          within_environment :isolated do
            with_bearer_and_token_trait :isolated do
              with_release_trait :in_shared_environment do
                denies :show, :upgrade, :create, :update, :destroy, :upload, :publish, :yank
              end

              with_release_trait :in_nil_environment do
                denies :show, :upgrade, :create, :update, :destroy, :upload, :publish, :yank
              end

              allows :show, :upgrade, :create, :update, :destroy, :upload, :publish, :yank
            end

            with_bearer_and_token_trait :shared do
              denies :show, :upgrade, :create, :update, :destroy, :upload, :publish, :yank
            end
          end

          within_environment :shared do
            with_bearer_and_token_trait :isolated do
              denies :show, :upgrade, :create, :update, :destroy, :upload, :publish, :yank
            end

            with_bearer_and_token_trait :shared do
              with_release_trait :in_isolated_environment do
                denies :show, :upgrade, :create, :update, :destroy, :upload, :publish, :yank
              end

              with_release_trait :in_nil_environment do
                denies :create, :update, :destroy, :upload, :publish, :yank
                allows :show, :upgrade
              end

              allows :show, :upgrade, :create, :update, :destroy, :upload, :publish, :yank
            end
          end

          within_environment nil do
            with_bearer_and_token_trait :isolated do
              denies :show, :upgrade, :create, :update, :destroy, :upload, :publish, :yank
            end

            with_bearer_and_token_trait :shared do
              denies :show, :upgrade, :create, :update, :destroy, :upload, :publish, :yank
            end
          end
        end
      end
    end
  end

  with_role_authorization :product do
    with_scenarios %i[accessing_its_releases] do
      with_token_authentication do
        with_permissions %w[release.read] do
          without_token_permissions { denies :index }

          allows :index
        end

        with_wildcard_permissions { allows :index }
        with_default_permissions  { allows :index }
        without_permissions       { denies :index }
      end
    end

    with_scenarios %i[accessing_its_release] do
      with_token_authentication do
        with_permissions %w[release.upgrade] do
          without_token_permissions { denies :upgrade }

          allows :upgrade
        end

        with_permissions %w[release.read] do
          without_token_permissions { denies :show }

          allows :show
        end

        with_permissions %w[release.create] do
          without_token_permissions { denies :create }

          allows :create
        end

        with_permissions %w[release.update] do
          without_token_permissions { denies :update }

          allows :update
        end

        with_permissions %w[release.delete] do
          without_token_permissions { denies :destroy }

          allows :destroy
        end

        with_permissions %w[release.upload] do
          without_token_permissions { denies :upload }

          allows :upload
        end

        with_permissions %w[release.publish] do
          without_token_permissions { denies :publish }

          allows :publish
        end

        with_permissions %w[release.yank] do
          without_token_permissions { denies :yank }

          allows :yank
        end

        with_wildcard_permissions do
          without_token_permissions do
            denies :show, :upgrade, :create, :update, :destroy, :upload, :publish, :yank
          end

          allows :show, :upgrade, :create, :update, :destroy, :upload, :publish, :yank
        end

        with_default_permissions do
          without_token_permissions do
            denies :show, :upgrade, :create, :update, :destroy, :upload, :publish, :yank
          end

          allows :show, :upgrade, :create, :update, :destroy, :upload, :publish, :yank
        end

        without_permissions do
          denies :show, :upgrade, :create, :update, :destroy, :upload, :publish, :yank
        end
      end
    end

    with_scenarios %i[accessing_releases] do
      with_token_authentication do
        with_permissions %w[release.read] do
          denies :index
        end

        with_wildcard_permissions { denies :index }
        with_default_permissions  { denies :index }
        without_permissions       { denies :index }
      end
    end

    with_scenarios %i[accessing_a_release] do
      with_token_authentication do
        with_permissions %w[release.upgrade] do
          denies :upgrade
        end

        with_permissions %w[release.read] do
          denies :show
        end

        with_permissions %w[release.create] do
          denies :create
        end

        with_permissions %w[release.update] do
          denies :update
        end

        with_permissions %w[release.delete] do
          denies :destroy
        end

        with_permissions %w[release.upload] do
          denies :upload
        end

        with_permissions %w[release.publish] do
          denies :publish
        end

        with_permissions %w[release.yank] do
          denies :yank
        end

        with_wildcard_permissions do
          denies :show, :upgrade, :create, :update, :destroy, :upload, :publish, :yank
        end

        with_default_permissions do
          denies :show, :upgrade, :create, :update, :destroy, :upload, :publish, :yank
        end

        without_permissions do
          denies :show, :upgrade, :create, :update, :destroy, :upload, :publish, :yank
        end
      end
    end
  end

  with_role_authorization :license do
    with_scenarios %i[accessing_its_releases] do
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

    with_scenarios %i[accessing_its_release] do
      with_license_authentication do
        with_release_traits %i[created_last_year] do
          with_bearer_traits %i[expired restrict_access_expiration_strategy] do
            allows :show, :upgrade
          end

          with_bearer_traits %i[expired revoke_access_expiration_strategy] do
            denies :show, :upgrade
          end

          with_bearer_traits %i[expired maintain_access_expiration_strategy] do
            allows :show, :upgrade
          end

          with_bearer_traits %i[expired allow_access_expiration_strategy] do
            allows :show, :upgrade
          end
        end

        with_release_traits %i[with_constraints] do
          with_bearer_traits %i[with_entitlements] do
            allows :show, :upgrade
          end

          denies :show, :upgrade
        end

        with_bearer_traits %i[expired restrict_access_expiration_strategy] do
          denies :show, :upgrade
        end

        with_bearer_traits %i[expired revoke_access_expiration_strategy] do
          denies :show, :upgrade
        end

        with_bearer_traits %i[expired maintain_access_expiration_strategy] do
          denies :show, :upgrade
        end

        with_bearer_traits %i[expired allow_access_expiration_strategy] do
          allows :show, :upgrade
        end

        with_bearer_traits %i[expired] do
          denies :show, :upgrade
        end

        with_permissions %w[release.upgrade] do
          allows :upgrade
        end

        with_permissions %w[release.read] do
          allows :show
        end

        with_wildcard_permissions do
          denies :create, :update, :destroy, :upload, :publish, :yank
          allows :show, :upgrade
        end

        with_default_permissions do
          denies :create, :update, :destroy, :upload, :publish, :yank
          allows :show, :upgrade
        end

        without_permissions do
          denies :show, :upgrade, :create, :update, :destroy, :upload, :publish, :yank
        end
      end

      with_token_authentication do
        with_permissions %w[release.upgrade] do
          without_token_permissions { denies :upgrade }

          allows :upgrade
        end

        with_permissions %w[release.read] do
          without_token_permissions { denies :show }

          allows :show
        end

        with_wildcard_permissions do
          denies :create, :update, :destroy, :upload, :publish, :yank
          allows :show, :upgrade
        end

        with_default_permissions do
          denies :create, :update, :destroy, :upload, :publish, :yank
          allows :show, :upgrade
        end

        without_permissions do
          denies :show, :upgrade, :create, :update, :destroy, :upload, :publish, :yank
        end
      end
    end

    with_scenarios %i[accessing_releases] do
      with_release_traits %i[open] do
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

    with_scenarios %i[accessing_a_release] do
      with_release_traits %i[open] do
        with_license_authentication do
          with_permissions %w[release.read] do
            allows :show
          end

          with_wildcard_permissions do
            denies :create, :update, :destroy
            allows :show
          end

          with_default_permissions do
            denies :create, :update, :destroy
            allows :show
          end

          without_permissions do
            denies :show, :create, :update, :destroy
          end
        end

        with_token_authentication do
          with_permissions %w[release.read] do
            allows :show
          end

          with_wildcard_permissions do
            denies :create, :update, :destroy
            allows :show
          end

          with_default_permissions do
            denies :create, :update, :destroy
            allows :show
          end

          without_permissions do
            denies :show, :create, :update, :destroy
          end
        end
      end

      with_license_authentication do
        with_permissions %w[release.upgrade] do
          denies :upgrade
        end

        with_permissions %w[release.read] do
          denies :show
        end

        with_wildcard_permissions do
          denies :show, :upgrade, :create, :update, :destroy, :upload, :publish, :yank
        end

        with_default_permissions do
          denies :show, :upgrade, :create, :update, :destroy, :upload, :publish, :yank
        end

        without_permissions do
          denies :show, :upgrade, :create, :update, :destroy, :upload, :publish, :yank
        end
      end

      with_token_authentication do
        with_permissions %w[release.upgrade] do
          denies :upgrade
        end

        with_permissions %w[release.read] do
          denies :show
        end

        with_wildcard_permissions do
          denies :show, :upgrade, :create, :update, :destroy, :upload, :publish, :yank
        end

        with_default_permissions do
          denies :show, :upgrade, :create, :update, :destroy, :upload, :publish, :yank
        end

        without_permissions do
          denies :show, :upgrade, :create, :update, :destroy, :upload, :publish, :yank
        end
      end
    end
  end

  with_role_authorization :user do
    with_bearer_trait :with_owned_licenses do
      with_scenarios %i[accessing_its_releases] do
        with_token_authentication do
          with_permissions %w[release.read] do
            allows :index
          end

          with_wildcard_permissions { allows :index }
          with_default_permissions  { allows :index }
          without_permissions       { denies :index }
        end
      end

      with_scenarios %i[accessing_its_release] do
        with_token_authentication do
          with_permissions %w[release.upgrade] do
            allows :upgrade
          end

          with_permissions %w[release.read] do
            allows :show
          end

          with_wildcard_permissions do
            denies :create, :update, :destroy, :upload, :publish, :yank
            allows :show, :upgrade
          end

          with_default_permissions do
            denies :create, :update, :destroy, :upload, :publish, :yank
            allows :show, :upgrade
          end

          without_permissions do
            denies :show, :upgrade, :create, :update, :destroy, :upload, :publish, :yank
          end
        end
      end

      with_scenarios %i[accessing_releases] do
        with_release_traits %i[open] do
          with_token_authentication do
            with_permissions %w[release.read] do
              allows :index
            end

            with_wildcard_permissions { allows :index }
            with_default_permissions  { allows :index }
            without_permissions       { denies :index }
          end
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

      with_scenarios %i[accessing_a_release] do
        with_release_traits %i[open] do
          with_token_authentication do
            with_permissions %w[release.read] do
              allows :show
            end

            with_wildcard_permissions do
              denies :create, :update, :destroy
              allows :show
            end

            with_default_permissions do
              denies :create, :update, :destroy
              allows :show
            end

            without_permissions do
              denies :show, :create, :update, :destroy
            end
          end
        end

        with_token_authentication do
          with_permissions %w[release.upgrade] do
            denies :upgrade
          end

          with_permissions %w[release.read] do
            denies :show
          end

          with_wildcard_permissions do
            denies :show, :upgrade, :create, :update, :destroy, :upload, :publish, :yank
          end

          with_default_permissions do
            denies :show, :upgrade, :create, :update, :destroy, :upload, :publish, :yank
          end

          without_permissions do
            denies :show, :upgrade, :create, :update, :destroy, :upload, :publish, :yank
          end
        end
      end
    end

    with_bearer_trait :with_user_licenses do
      with_scenarios %i[accessing_its_releases] do
        with_token_authentication do
          with_permissions %w[release.read] do
            allows :index
          end

          with_wildcard_permissions { allows :index }
          with_default_permissions  { allows :index }
          without_permissions       { denies :index }
        end
      end

      with_scenarios %i[accessing_its_release] do
        with_token_authentication do
          with_permissions %w[release.upgrade] do
            allows :upgrade
          end

          with_permissions %w[release.read] do
            allows :show
          end

          with_wildcard_permissions do
            denies :create, :update, :destroy, :upload, :publish, :yank
            allows :show, :upgrade
          end

          with_default_permissions do
            denies :create, :update, :destroy, :upload, :publish, :yank
            allows :show, :upgrade
          end

          without_permissions do
            denies :show, :upgrade, :create, :update, :destroy, :upload, :publish, :yank
          end
        end
      end

      with_scenarios %i[accessing_releases] do
        with_release_traits %i[open] do
          with_token_authentication do
            with_permissions %w[release.read] do
              allows :index
            end

            with_wildcard_permissions { allows :index }
            with_default_permissions  { allows :index }
            without_permissions       { denies :index }
          end
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

      with_scenarios %i[accessing_a_release] do
        with_release_traits %i[open] do
          with_token_authentication do
            with_permissions %w[release.read] do
              allows :show
            end

            with_wildcard_permissions do
              denies :create, :update, :destroy
              allows :show
            end

            with_default_permissions do
              denies :create, :update, :destroy
              allows :show
            end

            without_permissions do
              denies :show, :create, :update, :destroy
            end
          end
        end

        with_token_authentication do
          with_permissions %w[release.upgrade] do
            denies :upgrade
          end

          with_permissions %w[release.read] do
            denies :show
          end

          with_wildcard_permissions do
            denies :show, :upgrade, :create, :update, :destroy, :upload, :publish, :yank
          end

          with_default_permissions do
            denies :show, :upgrade, :create, :update, :destroy, :upload, :publish, :yank
          end

          without_permissions do
            denies :show, :upgrade, :create, :update, :destroy, :upload, :publish, :yank
          end
        end
      end
    end

    with_scenarios %i[accessing_its_release] do
      with_token_authentication do
        with_bearer_trait :with_expired_licenses do
          with_release_trait :created_last_year do
            allows :show, :upgrade
          end

          denies :show, :upgrade
        end

        with_release_trait :with_constraints do
          with_bearer_trait :with_entitled_licenses do
            allows :show, :upgrade
          end

          with_bearer_trait :with_owned_licenses do
            denies :show, :upgrade
          end

          with_bearer_trait :with_user_licenses do
            denies :show, :upgrade
          end
        end
      end
    end

    with_scenarios %i[accessing_releases] do
      with_token_authentication do
        with_permissions %w[release.read] do
          denies :index
        end

        with_wildcard_permissions { denies :index }
        with_default_permissions  { denies :index }
        without_permissions       { denies :index }
      end
    end

    with_scenarios %i[accessing_a_release] do
      with_token_authentication do
        with_permissions %w[release.read] do
          denies :show
        end

        with_wildcard_permissions do
          denies :show, :upgrade, :create, :update, :destroy, :upload, :publish, :yank
        end

        with_default_permissions do
          denies :show, :upgrade, :create, :update, :destroy, :upload, :publish, :yank
        end

        without_permissions do
          denies :show, :upgrade, :create, :update, :destroy, :upload, :publish, :yank
        end
      end
    end
  end

  without_authorization do
    with_scenarios %i[accessing_releases] do
      without_authentication do
        denies :index
      end
    end

    with_scenarios %i[accessing_a_release] do
      without_authentication do
        denies :show, :upgrade, :create, :update, :destroy, :upload, :publish, :yank
      end
    end
  end
end
