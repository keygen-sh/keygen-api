# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe KeyPolicy, type: :policy do
  subject { described_class.new(record, account:, environment:, bearer:, token:) }

  with_role_authorization :admin do
    with_scenarios %i[accessing_keys] do
      with_token_authentication do
        with_permissions %w[key.read] do
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

    with_scenarios %i[accessing_a_key] do
      with_token_authentication do
        with_permissions %w[key.read] do
          without_token_permissions { denies :show }

          allows :show
        end

        with_permissions %w[key.create] do
          without_token_permissions { denies :create }

          allows :create
        end

        with_permissions %w[key.update] do
          without_token_permissions { denies :update }

          allows :update
        end

        with_permissions %w[key.delete] do
          without_token_permissions { denies :destroy }

          allows :destroy
        end

        with_wildcard_permissions do
          without_token_permissions { denies :show, :create, :update, :destroy }

          allows :show, :create, :update, :destroy
        end

        with_default_permissions do
          without_token_permissions { denies :show, :create, :update, :destroy }

          allows :show, :create, :update, :destroy
        end

        without_permissions do
          denies :show, :create, :update, :destroy
        end

        within_environment :isolated do
          with_bearer_and_token_trait :in_shared_environment do
            denies :show, :create, :update, :destroy
          end

          with_bearer_and_token_trait :in_nil_environment do
            denies :show, :create, :update, :destroy
          end

          allows :show, :create, :update, :destroy
        end

        within_environment :shared do
          with_bearer_and_token_trait :in_isolated_environment do
            denies :show, :create, :update, :destroy
          end

          with_bearer_and_token_trait :in_nil_environment do
            allows :show, :create, :update, :destroy
          end

          allows :show, :create, :update, :destroy
        end

        within_environment nil do
          with_bearer_and_token_trait :in_isolated_environment do
            denies :show, :create, :update, :destroy
          end

          with_bearer_and_token_trait :in_shared_environment do
            denies :show, :create, :update, :destroy
          end

          allows :show, :create, :update, :destroy
        end
      end
    end

    with_scenarios %i[accessing_another_account accessing_keys] do
      with_token_authentication do
        with_permissions %w[key.read] do
          denies :index
        end

        with_wildcard_permissions { denies :index }
        with_default_permissions  { denies :index }
        without_permissions       { denies :index }
      end
    end

    with_scenarios %i[accessing_another_account accessing_a_key] do
      with_token_authentication do
        with_permissions %w[key.read] do
          denies :show
        end

        with_permissions %w[key.create] do
          denies :create
        end

        with_permissions %w[key.update] do
          denies :update
        end

        with_permissions %w[key.delete] do
          denies :destroy
        end

        with_wildcard_permissions do
          denies :show, :create, :update, :destroy
        end

        with_default_permissions do
          denies :show, :create, :update, :destroy
        end

        without_permissions do
          denies :show, :create, :update, :destroy
        end
      end
    end
  end

  with_role_authorization :environment do
    within_environment do
      with_scenarios %i[accessing_keys] do
        with_token_authentication do
          with_permissions %w[key.read] do
            without_token_permissions { denies :index }

            allows :index
          end

          with_wildcard_permissions { allows :index }
          with_default_permissions  { allows :index }
          without_permissions       { denies :index }

          within_environment :isolated do
            with_bearer_and_token_trait :isolated do
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

      with_scenarios %i[accessing_a_key] do
        with_token_authentication do
          with_permissions %w[key.read] do
            without_token_permissions { denies :show }

            allows :show
          end

          with_permissions %w[key.create] do
            without_token_permissions { denies :create }

            allows :create
          end

          with_permissions %w[key.update] do
            without_token_permissions { denies :update }

            allows :update
          end

          with_permissions %w[key.delete] do
            without_token_permissions { denies :destroy }

            allows :destroy
          end

          with_wildcard_permissions do
            without_token_permissions { denies :show, :create, :update, :destroy }

            allows :show, :create, :update, :destroy
          end

          with_default_permissions do
            without_token_permissions { denies :show, :create, :update, :destroy }

            allows :show, :create, :update, :destroy
          end

          without_permissions do
            denies :show, :create, :update, :destroy
          end

          within_environment :isolated do
            with_bearer_and_token_trait :isolated do
              allows :show, :create, :update, :destroy
            end

            with_bearer_and_token_trait :shared do
              denies :show, :create, :update, :destroy
            end
          end

          within_environment :shared do
            with_bearer_and_token_trait :isolated do
              denies :show, :create, :update, :destroy
            end

            with_bearer_and_token_trait :shared do
              allows :show, :create, :update, :destroy
            end
          end

          within_environment nil do
            with_bearer_and_token_trait :isolated do
              denies :show, :create, :update, :destroy
            end

            with_bearer_and_token_trait :shared do
              denies :show, :create, :update, :destroy
            end
          end
        end
      end
    end
  end

  with_role_authorization :product do
    with_scenarios %i[accessing_its_keys] do
      with_token_authentication do
        with_permissions %w[key.read] do
          without_token_permissions { denies :index }

          allows :index
        end

        with_wildcard_permissions { allows :index }
        with_default_permissions  { allows :index }
        without_permissions       { denies :index }
      end
    end

    with_scenarios %i[accessing_its_key] do
      with_token_authentication do
        with_permissions %w[key.read] do
          without_token_permissions { denies :show }

          allows :show
        end

        with_permissions %w[key.create] do
          without_token_permissions { denies :create }

          allows :create
        end

        with_permissions %w[key.update] do
          without_token_permissions { denies :update }

          allows :update
        end

        with_permissions %w[key.delete] do
          without_token_permissions { denies :destroy }

          allows :destroy
        end

        with_wildcard_permissions do
          without_token_permissions { denies :show, :create, :update, :destroy }

          allows :show, :create, :update, :destroy
        end

        with_default_permissions do
          without_token_permissions { denies :show, :create, :update, :destroy }

          allows :show, :create, :update, :destroy
        end

        without_permissions do
          denies :show, :create, :update, :destroy
        end
      end
    end

    with_scenarios %i[accessing_keys] do
      with_token_authentication do
        with_permissions %w[key.read] do
          denies :index
        end

        with_wildcard_permissions { denies :index }
        with_default_permissions  { denies :index }
        without_permissions       { denies :index }
      end
    end

    with_scenarios %i[accessing_a_key] do
      with_token_authentication do
        with_permissions %w[key.read] do
          denies :show
        end

        with_permissions %w[key.create] do
          denies :create
        end

        with_permissions %w[key.update] do
          denies :update
        end

        with_permissions %w[key.delete] do
          denies :destroy
        end

        with_wildcard_permissions do
          denies :show, :create, :update, :destroy
        end

        with_default_permissions do
          denies :show, :create, :update, :destroy
        end

        without_permissions do
          denies :show, :create, :update, :destroy
        end
      end
    end
  end

  with_role_authorization :license do
    with_scenarios %i[accessing_keys] do
      with_license_authentication do
        with_wildcard_permissions { denies :index }
        with_default_permissions  { denies :index }
        without_permissions       { denies :index }
      end

      with_token_authentication do
        with_wildcard_permissions { denies :index }
        with_default_permissions  { denies :index }
        without_permissions       { denies :index }
      end
    end

    with_scenarios %i[accessing_a_key] do
      with_license_authentication do
        with_wildcard_permissions do
          denies :show, :create, :update, :destroy
        end

        with_default_permissions do
          denies :show, :create, :update, :destroy
        end

        without_permissions do
          denies :show, :create, :update, :destroy
        end
      end

      with_token_authentication do
        with_wildcard_permissions do
          denies :show, :create, :update, :destroy
        end

        with_default_permissions do
          denies :show, :create, :update, :destroy
        end

        without_permissions do
          denies :show, :create, :update, :destroy
        end
      end
    end
  end

  with_role_authorization :user do
    with_scenarios %i[accessing_keys] do
      with_token_authentication do
        with_wildcard_permissions { denies :index }
        with_default_permissions  { denies :index }
        without_permissions       { denies :index }
      end
    end

    with_scenarios %i[accessing_a_key] do
      with_token_authentication do
        with_wildcard_permissions do
          denies :show, :create, :update, :destroy
        end

        with_default_permissions do
          denies :show, :create, :update, :destroy
        end

        without_permissions do
          denies :show, :create, :update, :destroy
        end
      end
    end
  end

  without_authorization do
    with_scenarios %i[accessing_keys] do
      without_authentication do
        denies :index
      end
    end

    with_scenarios %i[accessing_a_key] do
      without_authentication do
        denies :show, :create, :update, :destroy
      end
    end
  end
end
