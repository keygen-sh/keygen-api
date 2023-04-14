# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe Licenses::ProductPolicy, type: :policy do
  subject { described_class.new(record, account:, environment:, bearer:, token:, license:) }

  with_role_authorization :admin do
    with_scenarios %i[accessing_a_license accessing_its_product] do
      with_token_authentication do
        with_permissions %w[product.read] do
          without_token_permissions { denies :show }

          allows :show
        end

        with_wildcard_permissions do
          without_token_permissions do
            denies :show
          end

          allows :show
        end

        with_default_permissions do
          without_token_permissions do
            denies :show
          end

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

    with_scenarios %i[accessing_another_account accessing_a_license accessing_its_product] do
      with_token_authentication do
        with_permissions %w[product.read] do
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

  with_role_authorization :environment do
    within_environment :current do
      with_scenarios %i[accessing_a_license accessing_its_product] do
        with_token_authentication do
          with_permissions %w[product.read] do
            without_token_permissions { denies :show }

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
      end
    end

    with_scenarios %i[accessing_a_license accessing_its_product] do
      with_token_authentication do
        with_permissions %w[product.read] do
          without_token_permissions { denies :show }

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
    with_scenarios %i[accessing_its_license accessing_its_product] do
      with_token_authentication do
        with_permissions %w[product.read] do
          without_token_permissions { denies :show }

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
    end

    with_scenarios %i[accessing_a_license accessing_its_product] do
      with_token_authentication do
        with_permissions %w[product.read] do
          without_token_permissions { denies :show }

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
    with_scenarios %i[accessing_itself accessing_its_product] do
      with_license_authentication do
        with_permissions %w[product.read] do
          allows :show
        end

        with_wildcard_permissions do
          allows :show
        end

        with_default_permissions do
          denies :show
        end

        without_permissions do
          denies :show
        end
      end

      with_token_authentication do
        with_permissions %w[product.read] do
          without_token_permissions { denies :show }

          allows :show
        end

        with_wildcard_permissions do
          allows :show
        end

        with_default_permissions do
          denies :show
        end

        without_permissions do
          denies :show
        end
      end
    end

    with_scenarios %i[accessing_a_license accessing_its_product] do
      with_license_authentication do
        with_permissions %w[product.read] do
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
        with_permissions %w[product.read] do
          without_token_permissions { denies :show }

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
      with_scenarios %i[accessing_its_license accessing_its_product] do
        with_token_authentication do
          with_permissions %w[product.read] do
            without_token_permissions { denies :show }

            allows :show
          end

          with_wildcard_permissions do
            allows :show
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

    with_scenarios %i[accessing_a_license accessing_its_product] do
      with_token_authentication do
        with_permissions %w[product.read] do
          without_token_permissions { denies :show }

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
    with_scenarios %i[accessing_a_license accessing_its_product] do
      without_authentication do
        denies :show
      end
    end
  end
end
