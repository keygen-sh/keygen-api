# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe Machines::V1x0::ProofPolicy, type: :policy do
  subject { described_class.new(record, account:, environment:, bearer:, token:, machine:) }

  with_role_authorization :admin do
    with_scenarios %i[accessing_a_machine] do
      with_token_authentication do
        with_permissions %w[machine.proofs.generate] do
          without_token_permissions { denies :create }

          allows :create
        end

        with_wildcard_permissions do
          without_token_permissions do
            denies :create
          end

          allows :create
        end

        with_default_permissions do
          without_token_permissions do
            denies :create
          end

          allows :create
        end

        without_permissions do
          denies :create
        end

        within_environment :isolated do
          with_bearer_and_token_trait :in_shared_environment do
            denies :create
          end

          with_bearer_and_token_trait :in_nil_environment do
            denies :create
          end

          allows :create
        end

        within_environment :shared do
          with_bearer_and_token_trait :in_isolated_environment do
            denies :create
          end

          with_bearer_and_token_trait :in_nil_environment do
            allows :create
          end

          allows :create
        end

        within_environment nil do
          with_bearer_and_token_trait :in_isolated_environment do
            denies :create
          end

          with_bearer_and_token_trait :in_shared_environment do
            denies :create
          end

          allows :create
        end
      end
    end

    with_scenarios %i[accessing_another_account accessing_a_machine] do
      with_token_authentication do
        with_permissions %w[machine.proofs.generate] do
          denies :create
        end

        with_wildcard_permissions do
          denies :create
        end

        with_default_permissions do
          denies :create
        end

        without_permissions do
          denies :create
        end
      end
    end
  end

  with_role_authorization :environment do
    within_environment :self do
      with_scenarios %i[accessing_a_machine] do
        with_token_authentication do
          with_permissions %w[machine.proofs.generate] do
            without_token_permissions { denies :create }

            allows :create
          end

          with_wildcard_permissions do
            without_token_permissions do
              denies :create
            end

            allows :create
          end

          with_default_permissions do
            without_token_permissions do
              denies :create
            end

            allows :create
          end

          without_permissions do
            denies :create
          end
        end
      end
    end

    with_scenarios %i[accessing_a_machine] do
      with_token_authentication do
        with_permissions %w[machine.proofs.generate] do
          denies :create
        end

        with_wildcard_permissions do
          denies :create
        end

        with_default_permissions do
          denies :create
        end

        without_permissions do
          denies :create
        end
      end
    end
  end

  with_role_authorization :product do
    with_scenarios %i[accessing_its_machine] do
      with_token_authentication do
        with_permissions %w[machine.proofs.generate] do
          without_token_permissions { denies :create }

          allows :create
        end

        with_wildcard_permissions do
          without_token_permissions do
            denies :create
          end

          allows :create
        end

        with_default_permissions do
          without_token_permissions do
            denies :create
          end

          allows :create
        end

        without_permissions do
          denies :create
        end
      end
    end

    with_scenarios %i[accessing_a_machine] do
      with_token_authentication do
        with_permissions %w[machine.proofs.generate] do
          denies :create
        end

        with_wildcard_permissions do
          denies :create
        end

        with_default_permissions do
          denies :create
        end

        without_permissions do
          denies :create
        end
      end
    end
  end

  with_role_authorization :license do
    with_scenarios %i[accessing_its_machine] do
      with_license_authentication do
        with_permissions %w[machine.proofs.generate] do
          allows :create
        end

        with_wildcard_permissions do
          allows :create
        end

        with_default_permissions do
          allows :create
        end

        without_permissions do
          denies :create
        end
      end

      with_token_authentication do
        with_permissions %w[machine.proofs.generate] do
          without_token_permissions { denies :create }

          allows :create
        end

        with_wildcard_permissions do
          without_token_permissions do
            denies :create
          end

          allows :create
        end

        with_default_permissions do
          without_token_permissions do
            denies :create
          end

          allows :create
        end

        without_permissions do
          denies :create
        end
      end
    end

    with_scenarios %i[accessing_a_machine] do
      with_license_authentication do
        with_permissions %w[machine.proofs.generate] do
          denies :create
        end

        with_wildcard_permissions do
          denies :create
        end

        with_default_permissions do
          denies :create
        end

        without_permissions do
          denies :create
        end
      end

      with_token_authentication do
        with_permissions %w[machine.proofs.generate] do
          denies :create
        end

        with_wildcard_permissions do
          denies :create
        end

        with_default_permissions do
          denies :create
        end

        without_permissions do
          denies :create
        end
      end
    end
  end

  with_role_authorization :user do
    with_bearer_trait :with_owned_licenses do
      with_scenarios %i[accessing_its_machine] do
        with_token_authentication do
          with_permissions %w[machine.proofs.generate] do
            without_token_permissions { denies :create }

            allows :create
          end

          with_wildcard_permissions do
            without_token_permissions do
              denies :create
            end

            allows :create
          end

          with_default_permissions do
            without_token_permissions do
              denies :create
            end

            allows :create
          end

          without_permissions do
            denies :create
          end
        end
      end
    end

    with_bearer_trait :with_user_licenses do
      with_scenarios %i[accessing_its_machine] do
        with_token_authentication do
          with_permissions %w[machine.proofs.generate] do
            denies :create
          end

          with_wildcard_permissions do
            denies :create
          end

          with_default_permissions do
            denies :create
          end

          without_permissions do
            denies :create
          end
        end
      end
    end

    with_scenarios %i[accessing_a_machine] do
      with_token_authentication do
        with_permissions %w[machine.proofs.generate] do
          denies :create
        end

        with_wildcard_permissions do
          denies :create
        end

        with_default_permissions do
          denies :create
        end

        without_permissions do
          denies :create
        end
      end
    end
  end

  without_authorization do
    with_scenarios %i[accessing_a_machine] do
      without_authentication do
        denies :create
      end
    end
  end
end
