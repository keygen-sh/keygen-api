# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe LicensePolicy, type: :policy do
  subject { described_class.new(record, account:, environment:, bearer:, token:) }

  with_role_authorization :admin do
    with_scenarios %i[accessing_licenses] do
      with_token_authentication do
        with_permissions %w[license.read] do
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

    with_scenarios %i[accessing_a_license] do
      with_token_authentication do
        with_permissions %w[license.read] do
          without_token_permissions { denies :show }

          allows :show
        end

        with_permissions %w[license.create] do
          without_token_permissions { denies :create }

          allows :create
        end

        with_permissions %w[license.update] do
          without_token_permissions { denies :update }

          allows :update
        end

        with_permissions %w[license.delete] do
          without_token_permissions { denies :destroy }

          allows :destroy
        end

        with_permissions %w[license.validate] do
          without_token_permissions { denies :validate, :validate_key }

          allows :validate, :validate_key
        end

        with_permissions %w[license.check-out] do
          without_token_permissions { denies :check_out }

          allows :check_out
        end

        with_permissions %w[license.check-in] do
          without_token_permissions { denies :check_in }

          allows :check_in
        end

        with_permissions %w[license.revoke] do
          without_token_permissions { denies :revoke }

          allows :revoke
        end

        with_permissions %w[license.renew] do
          without_token_permissions { denies :renew }

          allows :renew
        end

        with_permissions %w[license.suspend] do
          without_token_permissions { denies :suspend }

          allows :suspend
        end

        with_permissions %w[license.reinstate] do
          without_token_permissions { denies :reinstate }

          allows :reinstate
        end

        with_wildcard_permissions do
          without_token_permissions do
            denies :show, :create, :update, :destroy, :validate, :check_out, :check_in, :revoke, :renew, :suspend, :reinstate
          end

          allows :show, :create, :update, :destroy, :validate, :check_out, :check_in, :revoke, :renew, :suspend, :reinstate
        end

        with_default_permissions do
          without_token_permissions do
            denies :show, :create, :update, :destroy, :validate, :check_out, :check_in, :revoke, :renew, :suspend, :reinstate
          end

          allows :show, :create, :update, :destroy, :validate, :check_out, :check_in, :revoke, :renew, :suspend, :reinstate
        end

        without_permissions do
          denies :show, :create, :update, :destroy, :validate, :check_out, :check_in, :revoke, :renew, :suspend, :reinstate
        end

        within_environment :isolated do
          with_bearer_and_token_trait :in_shared_environment do
            denies :show, :create, :update, :destroy, :validate, :check_out, :check_in, :revoke, :renew, :suspend, :reinstate
          end

          with_bearer_and_token_trait :in_nil_environment do
            denies :show, :create, :update, :destroy, :validate, :check_out, :check_in, :revoke, :renew, :suspend, :reinstate
          end

          allows :show, :create, :update, :destroy, :validate, :check_out, :check_in, :revoke, :renew, :suspend, :reinstate
        end

        within_environment :shared do
          with_bearer_and_token_trait :in_isolated_environment do
            denies :show, :create, :update, :destroy, :validate, :check_out, :check_in, :revoke, :renew, :suspend, :reinstate
          end

          with_bearer_and_token_trait :in_nil_environment do
            allows :show, :create, :update, :destroy, :validate, :check_out, :check_in, :revoke, :renew, :suspend, :reinstate
          end

          with_license_trait :in_nil_environment do
            denies :create, :update, :destroy, :check_out, :check_in, :revoke, :renew, :suspend, :reinstate
            allows :show, :validate
          end

          allows :show, :create, :update, :destroy, :validate, :check_out, :check_in, :revoke, :renew, :suspend, :reinstate
        end

        within_environment nil do
          with_bearer_and_token_trait :in_isolated_environment do
            denies :show, :create, :update, :destroy, :validate, :check_out, :check_in, :revoke, :renew, :suspend, :reinstate
          end

          with_bearer_and_token_trait :in_shared_environment do
            denies :show, :create, :update, :destroy, :validate, :check_out, :check_in, :revoke, :renew, :suspend, :reinstate
          end

          allows :show, :create, :update, :destroy, :validate, :check_out, :check_in, :revoke, :renew, :suspend, :reinstate
        end
      end
    end

    with_scenarios %i[accessing_another_account accessing_licenses] do
      with_token_authentication do
        with_permissions %w[license.read] do
          denies :index
        end

        with_wildcard_permissions { denies :index }
        with_default_permissions  { denies :index }
        without_permissions       { denies :index }
      end
    end

    with_scenarios %i[accessing_another_account accessing_a_license] do
      with_token_authentication do
        with_permissions %w[license.read] do
          denies :show
        end

        with_permissions %w[license.create] do
          denies :create
        end

        with_permissions %w[license.update] do
          denies :update
        end

        with_permissions %w[license.delete] do
          denies :destroy
        end

        with_permissions %w[license.validate] do
          denies :validate, :validate_key
        end

        with_permissions %w[license.check-out] do
          denies :check_out
        end

        with_permissions %w[license.check-in] do
          denies :check_in
        end

        with_permissions %w[license.revoke] do
          denies :revoke
        end

        with_permissions %w[license.renew] do
          denies :renew
        end

        with_permissions %w[license.suspend] do
          denies :suspend
        end

        with_permissions %w[license.reinstate] do
          denies :reinstate
        end

        with_wildcard_permissions do
          denies :show, :create, :update, :destroy, :validate, :check_out, :check_in, :revoke, :renew, :suspend, :reinstate
        end

        with_default_permissions do
          denies :show, :create, :update, :destroy, :validate, :check_out, :check_in, :revoke, :renew, :suspend, :reinstate
        end

        without_permissions do
          denies :show, :create, :update, :destroy, :validate, :check_out, :check_in, :revoke, :renew, :suspend, :reinstate
        end
      end
    end
  end

  with_role_authorization :environment do
    within_environment :self do
      with_scenarios %i[accessing_licenses] do
        with_token_authentication do
          with_permissions %w[license.read] do
            without_token_permissions { denies :index }

            allows :index
          end

          with_wildcard_permissions { allows :index }
          with_default_permissions  { allows :index }
          without_permissions       { denies :index }

          within_environment :isolated do
            with_bearer_and_token_trait :isolated do
              with_license_trait :in_shared_environment do
                denies :index
              end

              with_license_trait :in_nil_environment do
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
              with_license_trait :in_isolated_environment do
                denies :index
              end

              with_license_trait :in_nil_environment do
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

      with_scenarios %i[accessing_a_license] do
        with_token_authentication do
          with_permissions %w[license.read] do
            without_token_permissions { denies :show }

            allows :show
          end

          with_permissions %w[license.create] do
            without_token_permissions { denies :create }

            allows :create
          end

          with_permissions %w[license.update] do
            without_token_permissions { denies :update }

            allows :update
          end

          with_permissions %w[license.delete] do
            without_token_permissions { denies :destroy }

            allows :destroy
          end

          with_permissions %w[license.validate] do
            without_token_permissions { denies :validate, :validate_key }

            allows :validate, :validate_key
          end

          with_permissions %w[license.check-out] do
            without_token_permissions { denies :check_out }

            allows :check_out
          end

          with_permissions %w[license.check-in] do
            without_token_permissions { denies :check_in }

            allows :check_in
          end

          with_permissions %w[license.revoke] do
            without_token_permissions { denies :revoke }

            allows :revoke
          end

          with_permissions %w[license.renew] do
            without_token_permissions { denies :renew }

            allows :renew
          end

          with_permissions %w[license.suspend] do
            without_token_permissions { denies :suspend }

            allows :suspend
          end

          with_permissions %w[license.reinstate] do
            without_token_permissions { denies :reinstate }

            allows :reinstate
          end

          with_wildcard_permissions do
            without_token_permissions do
              denies :show, :create, :update, :destroy, :validate, :check_out, :check_in, :revoke, :renew, :suspend, :reinstate
            end

            allows :show, :create, :update, :destroy, :validate, :check_out, :check_in, :revoke, :renew, :suspend, :reinstate
          end

          with_default_permissions do
            without_token_permissions do
              denies :show, :create, :update, :destroy, :validate, :check_out, :check_in, :revoke, :renew, :suspend, :reinstate
            end

            allows :show, :create, :update, :destroy, :validate, :check_out, :check_in, :revoke, :renew, :suspend, :reinstate
          end

          without_permissions do
            denies :show, :create, :update, :destroy, :validate, :check_out, :check_in, :revoke, :renew, :suspend, :reinstate
          end

          within_environment :isolated do
            with_bearer_and_token_trait :isolated do
              with_license_trait :in_shared_environment do
                denies :show, :create, :update, :destroy, :validate, :check_out, :check_in, :revoke, :renew, :suspend, :reinstate
              end

              with_license_trait :in_nil_environment do
                denies :show, :create, :update, :destroy, :validate, :check_out, :check_in, :revoke, :renew, :suspend, :reinstate
              end

              allows :show, :create, :update, :destroy, :validate, :check_out, :check_in, :revoke, :renew, :suspend, :reinstate
            end

            with_bearer_and_token_trait :shared do
              denies :show, :create, :update, :destroy, :validate, :check_out, :check_in, :revoke, :renew, :suspend, :reinstate
            end
          end

          within_environment :shared do
            with_bearer_and_token_trait :isolated do
              denies :show, :create, :update, :destroy, :validate, :check_out, :check_in, :revoke, :renew, :suspend, :reinstate
            end

            with_bearer_and_token_trait :shared do
              with_license_trait :in_isolated_environment do
                denies :show, :create, :update, :destroy, :validate, :check_out, :check_in, :revoke, :renew, :suspend, :reinstate
              end

              with_license_trait :in_nil_environment do
                denies :create, :update, :destroy, :check_out, :check_in, :revoke, :renew, :suspend, :reinstate
                allows :show, :validate
              end

              allows :show, :create, :update, :destroy, :validate, :check_out, :check_in, :revoke, :renew, :suspend, :reinstate
            end
          end

          within_environment nil do
            with_bearer_and_token_trait :isolated do
              denies :show, :create, :update, :destroy, :validate, :check_out, :check_in, :revoke, :renew, :suspend, :reinstate
            end

            with_bearer_and_token_trait :shared do
              denies :show, :create, :update, :destroy, :validate, :check_out, :check_in, :revoke, :renew, :suspend, :reinstate
            end
          end
        end
      end
    end
  end

  with_role_authorization :product do
    with_scenarios %i[accessing_its_licenses] do
      with_token_authentication do
        with_permissions %w[license.read] do
          without_token_permissions { denies :index }

          allows :index
        end

        with_wildcard_permissions { allows :index }
        with_default_permissions  { allows :index }
        without_permissions       { denies :index }
      end
    end

    with_scenarios %i[accessing_its_license] do
      with_token_authentication do
        with_permissions %w[license.read] do
          without_token_permissions { denies :show }

          allows :show
        end

        with_permissions %w[license.create] do
          without_token_permissions { denies :create }

          allows :create
        end

        with_permissions %w[license.update] do
          without_token_permissions { denies :update }

          allows :update
        end

        with_permissions %w[license.delete] do
          without_token_permissions { denies :destroy }

          allows :destroy
        end

        with_permissions %w[license.validate] do
          without_token_permissions { denies :validate, :validate_key }

          allows :validate, :validate_key
        end

        with_permissions %w[license.check-out] do
          without_token_permissions { denies :check_out }

          allows :check_out
        end

        with_permissions %w[license.check-in] do
          without_token_permissions { denies :check_in }

          allows :check_in
        end

        with_permissions %w[license.revoke] do
          without_token_permissions { denies :revoke }

          allows :revoke
        end

        with_permissions %w[license.renew] do
          without_token_permissions { denies :renew }

          allows :renew
        end

        with_permissions %w[license.suspend] do
          without_token_permissions { denies :suspend }

          allows :suspend
        end

        with_permissions %w[license.reinstate] do
          without_token_permissions { denies :reinstate }

          allows :reinstate
        end

        with_wildcard_permissions do
          without_token_permissions do
            denies :show, :create, :update, :destroy, :validate, :check_out, :check_in, :revoke, :renew, :suspend, :reinstate
          end

          allows :show, :create, :update, :destroy, :validate, :check_out, :check_in, :revoke, :renew, :suspend, :reinstate
        end

        with_default_permissions do
          without_token_permissions do
            denies :show, :create, :update, :destroy, :validate, :check_out, :check_in, :revoke, :renew, :suspend, :reinstate
          end

          allows :show, :create, :update, :destroy, :validate, :check_out, :check_in, :revoke, :renew, :suspend, :reinstate
        end

        without_permissions do
          denies :show, :create, :update, :destroy, :validate, :check_out, :check_in, :revoke, :renew, :suspend, :reinstate
        end
      end
    end

    with_scenarios %i[accessing_licenses] do
      with_token_authentication do
        with_permissions %w[license.read] do
          denies :index
        end

        with_wildcard_permissions { denies :index }
        with_default_permissions  { denies :index }
        without_permissions       { denies :index }
      end
    end

    with_scenarios %i[accessing_a_license] do
      with_token_authentication do
        with_permissions %w[license.read] do
          denies :show
        end

        with_permissions %w[license.create] do
          denies :create
        end

        with_permissions %w[license.update] do
          denies :update
        end

        with_permissions %w[license.delete] do
          denies :destroy
        end

        with_permissions %w[license.validate] do
          denies :validate, :validate_key
        end

        with_permissions %w[license.check-out] do
          denies :check_out
        end

        with_permissions %w[license.check-in] do
          denies :check_in
        end

        with_permissions %w[license.revoke] do
          denies :revoke
        end

        with_permissions %w[license.renew] do
          denies :renew
        end

        with_permissions %w[license.suspend] do
          denies :suspend
        end

        with_permissions %w[license.reinstate] do
          denies :reinstate
        end

        with_wildcard_permissions do
          denies :show, :create, :update, :destroy, :validate, :check_out, :check_in, :revoke, :renew, :suspend, :reinstate
        end

        with_default_permissions do
          denies :show, :create, :update, :destroy, :validate, :check_out, :check_in, :revoke, :renew, :suspend, :reinstate
        end

        without_permissions do
          denies :show, :create, :update, :destroy, :validate, :check_out, :check_in, :revoke, :renew, :suspend, :reinstate
        end
      end
    end
  end

  with_role_authorization :license do
    with_scenarios %i[accessing_itself] do
      with_license_authentication do
        with_permissions %w[license.read] do
          allows :show
        end

        with_permissions %w[license.validate] do
          allows :validate, :validate_key
        end

        with_permissions %w[license.check-out] do
          allows :check_out
        end

        with_permissions %w[license.check-in] do
          allows :check_in
        end

        with_wildcard_permissions do
          denies :create, :update, :destroy, :revoke, :renew, :suspend, :reinstate
          allows :show, :validate, :check_out, :check_in
        end

        with_default_permissions do
          denies :create, :update, :destroy, :revoke, :renew, :suspend, :reinstate
          allows :show, :validate, :check_out, :check_in
        end

        without_permissions do
          denies :show, :create, :update, :destroy, :check_out, :check_in, :revoke, :renew, :suspend, :reinstate
        end
      end

      with_token_authentication do
        with_permissions %w[license.read] do
          without_token_permissions { denies :show }

          allows :show
        end

        with_permissions %w[license.validate] do
          without_token_permissions { denies :validate, :validate_key }

          allows :validate, :validate_key
        end

        with_permissions %w[license.check-out] do
          without_token_permissions { denies :check_out }

          allows :check_out
        end

        with_permissions %w[license.check-in] do
          without_token_permissions { denies :check_in }

          allows :check_in
        end

        with_wildcard_permissions do
          without_token_permissions do
            denies :show, :create, :update, :destroy, :validate, :check_out, :check_in, :revoke, :renew, :suspend, :reinstate
          end

          denies :create, :update, :destroy, :revoke, :renew, :suspend, :reinstate
          allows :show, :validate, :check_out, :check_in
        end

        with_default_permissions do
          without_token_permissions do
            denies :show, :create, :update, :destroy, :validate, :check_out, :check_in, :revoke, :renew, :suspend, :reinstate
          end

          denies :create, :update, :destroy, :revoke, :renew, :suspend, :reinstate
          allows :show, :validate, :check_out, :check_in
        end

        without_permissions do
          denies :show, :create, :update, :destroy, :validate, :check_out, :check_in, :revoke, :renew, :suspend, :reinstate
        end
      end
    end

    with_scenarios %i[accessing_licenses] do
      with_license_authentication do
        with_permissions %w[license.read] do
          denies :index
        end

        with_wildcard_permissions { denies :index }
        with_default_permissions  { denies :index }
        without_permissions       { denies :index }
      end

      with_token_authentication do
        with_permissions %w[license.read] do
          denies :index
        end

        with_wildcard_permissions { denies :index }
        with_default_permissions  { denies :index }
        without_permissions       { denies :index }
      end
    end

    with_scenarios %i[accessing_a_license] do
      with_license_authentication do
        with_permissions %w[license.read] do
          denies :show
        end

        with_permissions %w[license.validate] do
          denies :validate, :validate_key
        end

        with_permissions %w[license.check-out] do
          denies :check_out
        end

        with_permissions %w[license.check-in] do
          denies :check_in
        end

        with_wildcard_permissions do
          denies :show, :create, :update, :destroy, :validate, :check_out, :check_in, :revoke, :renew, :suspend, :reinstate
        end

        with_default_permissions do
          denies :show, :create, :update, :destroy, :validate, :check_out, :check_in, :revoke, :renew, :suspend, :reinstate
        end

        without_permissions do
          denies :show, :create, :update, :destroy, :validate, :check_out, :check_in, :revoke, :renew, :suspend, :reinstate
        end
      end

      with_token_authentication do
        with_permissions %w[license.read] do
          denies :show
        end

        with_permissions %w[license.validate] do
          denies :validate, :validate_key
        end

        with_permissions %w[license.check-out] do
          denies :check_out
        end

        with_permissions %w[license.check-in] do
          denies :check_in
        end

        with_wildcard_permissions do
          denies :show, :create, :update, :destroy, :validate, :check_out, :check_in, :revoke, :renew, :suspend, :reinstate
        end

        with_default_permissions do
          denies :show, :create, :update, :destroy, :validate, :check_out, :check_in, :revoke, :renew, :suspend, :reinstate
        end

        without_permissions do
          denies :show, :create, :update, :destroy, :validate, :check_out, :check_in, :revoke, :renew, :suspend, :reinstate
        end
      end
    end
  end

  with_role_authorization :user do
    with_bearer_trait :with_licenses do
      with_scenarios %i[accessing_its_licenses] do
        with_token_authentication do
          with_permissions %w[license.read] do
            allows :index
          end

          with_wildcard_permissions { allows :index }
          with_default_permissions  { allows :index }
          without_permissions       { denies :index }
        end
      end

      with_scenarios %i[accessing_its_license] do
        with_token_authentication do
          with_permissions %w[license.read] do
            without_token_permissions { denies :show }

            allows :show
          end

          with_permissions %w[license.create] do
            without_token_permissions { denies :create }

            allows :create
          end

          with_permissions %w[license.delete] do
            without_token_permissions { denies :destroy }

            allows :destroy
          end

          with_permissions %w[license.validate] do
            without_token_permissions { denies :validate, :validate_key }

            allows :validate, :validate_key
          end

          with_permissions %w[license.check-out] do
            without_token_permissions { denies :check_out }

            allows :check_out
          end

          with_permissions %w[license.check-in] do
            without_token_permissions { denies :check_in }

            allows :check_in
          end

          with_permissions %w[license.revoke] do
            without_token_permissions { denies :revoke }

            allows :revoke
          end

          with_permissions %w[license.renew] do
            without_token_permissions { denies :renew }

            allows :renew
          end

          with_wildcard_permissions do
            without_token_permissions do
              denies :show, :create, :update, :destroy, :validate, :check_out, :check_in, :revoke, :renew, :suspend, :reinstate
            end

            allows :show, :create, :destroy, :validate, :check_out, :check_in, :revoke, :renew
            denies :update, :suspend, :reinstate
          end

          with_default_permissions do
            without_token_permissions do
              denies :show, :create, :update, :destroy, :validate, :check_out, :check_in, :revoke, :renew, :suspend, :reinstate
            end

            allows :show, :create, :destroy, :validate, :check_out, :check_in, :revoke, :renew
            denies :update, :suspend, :reinstate
          end

          without_permissions do
            denies :show, :create, :update, :destroy, :validate, :check_out, :check_in, :revoke, :renew, :suspend, :reinstate
          end
        end
      end

      with_scenarios %i[accessing_licenses] do
        with_token_authentication do
          with_permissions %w[license.read] do
            denies :index
          end

          with_wildcard_permissions { denies :index }
          with_default_permissions  { denies :index }
          without_permissions       { denies :index }
        end
      end

      with_scenarios %i[accessing_a_license] do
        with_token_authentication do
          with_permissions %w[license.read] do
            denies :show
          end

          with_permissions %w[license.validate] do
            denies :validate, :validate_key
          end

          with_permissions %w[license.check-out] do
            denies :check_out
          end

          with_permissions %w[license.check-in] do
            denies :check_in
          end

          with_permissions %w[license.revoke] do
            denies :revoke
          end

          with_permissions %w[license.renew] do
            denies :renew
          end

          with_wildcard_permissions do
            denies :show, :create, :update, :destroy, :validate, :check_out, :check_in, :revoke, :renew, :suspend, :reinstate
          end

          with_default_permissions do
            denies :show, :create, :update, :destroy, :validate, :check_out, :check_in, :revoke, :renew, :suspend, :reinstate
          end

          without_permissions do
            denies :show, :create, :update, :destroy, :validate, :check_out, :check_in, :revoke, :renew, :suspend, :reinstate
          end
        end
      end
    end

    with_scenarios %i[accessing_licenses] do
      with_token_authentication do
        with_permissions %w[license.read] do
          denies :index
        end

        with_wildcard_permissions { denies :index }
        with_default_permissions  { denies :index }
        without_permissions       { denies :index }
      end
    end

    with_scenarios %i[accessing_a_license] do
      with_token_authentication do
        with_permissions %w[license.read] do
          denies :show
        end

        with_permissions %w[license.create] do
          denies :create
        end

        with_permissions %w[license.delete] do
          denies :destroy
        end

        with_permissions %w[license.validate] do
          denies :validate, :validate_key
        end

        with_permissions %w[license.check-out] do
          denies :check_out
        end

        with_permissions %w[license.check-in] do
          denies :check_in
        end

        with_permissions %w[license.revoke] do
          denies :revoke
        end

        with_permissions %w[license.renew] do
          denies :renew
        end

        with_wildcard_permissions do
          denies :show, :create, :update, :destroy, :validate, :check_out, :check_in, :revoke, :renew, :suspend, :reinstate
        end

        with_default_permissions do
          denies :show, :create, :update, :destroy, :validate, :check_out, :check_in, :revoke, :renew, :suspend, :reinstate
        end

        without_permissions do
          denies :show, :create, :update, :destroy, :validate, :check_out, :check_in, :revoke, :renew, :suspend, :reinstate
        end
      end
    end
  end

  without_authorization do
    with_scenarios %i[accessing_licenses] do
      without_authentication do
        denies :index
      end
    end

    with_scenarios %i[accessing_a_license] do
      without_authentication do
        denies :show, :create, :update, :destroy, :validate, :check_out, :check_in, :revoke, :renew, :suspend, :reinstate
        allows :validate_key
      end
    end
  end
end
