# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe Licenses::UsagePolicy, type: :policy do
  subject { described_class.new(record, account:, environment:, bearer:, token:, license:) }

  with_role_authorization :admin do
    with_scenarios %i[accessing_a_license] do
      with_token_authentication do
        with_permissions %w[license.usage.increment] do
          without_token_permissions { denies :increment }

          allows :increment
        end

        with_permissions %w[license.usage.decrement] do
          without_token_permissions { denies :decrement }

          allows :decrement
        end

        with_permissions %w[license.usage.reset] do
          without_token_permissions { denies :reset }

          allows :reset
        end

        with_wildcard_permissions do
          without_token_permissions do
            denies :increment, :decrement, :reset
          end

          allows :increment, :decrement, :reset
        end

        with_default_permissions do
          without_token_permissions do
            denies :increment, :decrement, :reset
          end

          allows :increment, :decrement, :reset
        end

        without_permissions do
          denies :increment, :decrement, :reset
        end

        within_environment :isolated do
          with_bearer_and_token_trait :in_shared_environment do
            denies :increment, :decrement, :reset
          end

          with_bearer_and_token_trait :in_nil_environment do
            denies :increment, :decrement, :reset
          end

          allows :increment, :decrement, :reset
        end

        within_environment :shared do
          with_bearer_and_token_trait :in_isolated_environment do
            denies :increment, :decrement, :reset
          end

          with_bearer_and_token_trait :in_nil_environment do
            allows :increment, :decrement, :reset
          end

          allows :increment, :decrement, :reset
        end

        within_environment nil do
          with_bearer_and_token_trait :in_isolated_environment do
            denies :increment, :decrement, :reset
          end

          with_bearer_and_token_trait :in_shared_environment do
            denies :increment, :decrement, :reset
          end

          allows :increment, :decrement, :reset
        end
      end
    end

    with_scenarios %i[accessing_another_account accessing_a_license] do
      with_token_authentication do
        with_permissions %w[license.usage.increment] do
          denies :increment
        end

        with_permissions %w[license.usage.decrement] do
          denies :decrement
        end

        with_permissions %w[license.usage.reset] do
          denies :reset
        end

        with_wildcard_permissions do
          denies :increment, :decrement, :reset
        end

        with_default_permissions do
          denies :increment, :decrement, :reset
        end

        without_permissions do
          denies :increment, :decrement, :reset
        end
      end
    end
  end

  with_role_authorization :environment do
    within_environment :self do
      with_scenarios %i[accessing_a_license] do
        with_token_authentication do
          with_permissions %w[license.usage.increment] do
            without_token_permissions { denies :increment }

            allows :increment
          end

          with_permissions %w[license.usage.decrement] do
            without_token_permissions { denies :decrement }

            allows :decrement
          end

          with_permissions %w[license.usage.reset] do
            without_token_permissions { denies :reset }

            allows :reset
          end

          with_wildcard_permissions do
            without_token_permissions do
              denies :increment, :decrement, :reset
            end

            allows :increment, :decrement, :reset
          end

          with_default_permissions do
            without_token_permissions do
              denies :increment, :decrement, :reset
            end

            allows :increment, :decrement, :reset
          end

          without_permissions do
            denies :increment, :decrement, :reset
          end
        end
      end
    end

    with_scenarios %i[accessing_a_license] do
      with_token_authentication do
        with_permissions %w[license.usage.increment] do
          denies :increment
        end

        with_permissions %w[license.usage.decrement] do
          denies :decrement
        end

        with_permissions %w[license.usage.reset] do
          denies :reset
        end

        with_wildcard_permissions do
          denies :increment, :decrement, :reset
        end

        with_default_permissions do
          denies :increment, :decrement, :reset
        end

        without_permissions do
          denies :increment, :decrement, :reset
        end
      end
    end
  end

  with_role_authorization :product do
    with_scenarios %i[accessing_its_license] do
      with_token_authentication do
        with_permissions %w[license.usage.increment] do
          without_token_permissions { denies :increment }

          allows :increment
        end

        with_permissions %w[license.usage.decrement] do
          without_token_permissions { denies :decrement }

          allows :decrement
        end

        with_permissions %w[license.usage.reset] do
          without_token_permissions { denies :reset }

          allows :reset
        end

        with_wildcard_permissions do
          without_token_permissions do
            denies :increment, :decrement, :reset
          end

          allows :increment, :decrement, :reset
        end

        with_default_permissions do
          without_token_permissions do
            denies :increment, :decrement, :reset
          end

          allows :increment, :decrement, :reset
        end

        without_permissions do
          denies :increment, :decrement, :reset
        end
      end
    end

    with_scenarios %i[accessing_a_license] do
      with_token_authentication do
        with_permissions %w[license.usage.increment] do
          denies :increment
        end

        with_permissions %w[license.usage.decrement] do
          denies :decrement
        end

        with_permissions %w[license.usage.reset] do
          denies :reset
        end

        with_wildcard_permissions do
          denies :increment, :decrement, :reset
        end

        with_default_permissions do
          denies :increment, :decrement, :reset
        end

        without_permissions do
          denies :increment, :decrement, :reset
        end
      end
    end
  end

  with_role_authorization :license do
    with_scenarios %i[accessing_itself] do
      with_license_authentication do
        with_permissions %w[license.usage.increment] do
          allows :increment
        end

        with_wildcard_permissions do
          denies :decrement, :reset
          allows :increment
        end

        with_default_permissions do
          denies :decrement, :reset
          allows :increment
        end

        without_permissions do
          denies :increment, :decrement, :reset
        end
      end

      with_token_authentication do
        with_permissions %w[license.usage.increment] do
          without_token_permissions { denies :increment }

          allows :increment
        end

        with_wildcard_permissions do
          without_token_permissions do
            denies :increment, :decrement, :reset
          end

          denies :decrement, :reset
          allows :increment
        end

        with_default_permissions do
          without_token_permissions do
            denies :increment, :decrement, :reset
          end

          denies :decrement, :reset
          allows :increment
        end

        without_permissions do
          denies :increment, :decrement, :reset
        end
      end
    end

    with_scenarios %i[accessing_a_license] do
      with_license_authentication do
        with_permissions %w[license.usage.increment] do
          denies :increment
        end

        with_wildcard_permissions do
          denies :increment, :decrement, :reset
        end

        with_default_permissions do
          denies :increment, :decrement, :reset
        end

        without_permissions do
          denies :increment, :decrement, :reset
        end
      end

      with_token_authentication do
        with_permissions %w[license.usage.increment] do
          denies :increment
        end

        with_wildcard_permissions do
          denies :increment, :decrement, :reset
        end

        with_default_permissions do
          denies :increment, :decrement, :reset
        end

        without_permissions do
          denies :increment, :decrement, :reset
        end
      end
    end
  end

  with_role_authorization :user do
    with_bearer_trait :with_owned_licenses do
      with_scenarios %i[accessing_its_license] do
        with_token_authentication do
          with_permissions %w[license.usage.increment] do
            without_token_permissions { denies :increment }

            allows :increment
          end

          with_wildcard_permissions do
            without_token_permissions do
              denies :increment, :decrement, :reset
            end

            denies :decrement, :reset
            allows :increment
          end

          with_default_permissions do
            without_token_permissions do
              denies :increment, :decrement, :reset
            end

            denies :decrement, :reset
            allows :increment
          end

          without_permissions do
            denies :increment, :decrement, :reset
          end
        end
      end
    end

    with_bearer_trait :with_user_licenses do
      with_scenarios %i[accessing_its_license] do
        with_token_authentication do
          with_permissions %w[license.usage.increment] do
            without_token_permissions { denies :increment }

            denies :increment
          end

          with_wildcard_permissions do
            denies :increment, :decrement, :reset
          end

          with_default_permissions do
            denies :increment, :decrement, :reset
          end

          without_permissions do
            denies :increment, :decrement, :reset
          end
        end
      end
    end

    with_scenarios %i[accessing_a_license] do
      with_token_authentication do
        with_permissions %w[license.usage.increment] do
          denies :increment
        end

        with_wildcard_permissions do
          denies :increment, :decrement, :reset
        end

        with_default_permissions do
          denies :increment, :decrement, :reset
        end

        without_permissions do
          denies :increment, :decrement, :reset
        end
      end
    end
  end

  without_authorization do
    with_scenarios %i[accessing_a_license] do
      without_authentication do
        denies :increment, :decrement, :reset
      end
    end
  end
end
