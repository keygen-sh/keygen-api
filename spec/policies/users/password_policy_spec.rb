# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe Users::PasswordPolicy, type: :policy do
  subject { described_class.new(record, account:, environment:, bearer:, token:, user:) }

  with_role_authorization :admin do
    with_scenarios %i[accessing_itself] do
      with_token_authentication do
        with_permissions %w[user.password.update] do
          without_token_permissions { denies :update }

          allows :update
        end

        with_permissions %w[user.password.reset] do
          without_token_permissions { denies :reset }

          allows :reset
        end

        with_wildcard_permissions do
          without_token_permissions { denies :update, :reset }

          allows :update, :reset
        end

        with_default_permissions do
          without_token_permissions { denies :update, :reset }

          allows :update, :reset
        end

        without_permissions do
          denies :update, :reset
        end

        within_environment :isolated do
          allows :update, :reset
        end

        within_environment :shared do
          allows :update, :reset
        end

        within_environment nil do
          allows :update, :reset
        end
      end
    end

    with_scenarios %i[accessing_a_user] do
      with_token_authentication do
        with_permissions %w[user.password.update] do
          denies :update
        end

        with_permissions %w[user.password.reset] do
          denies :reset
        end

        with_wildcard_permissions do
          denies :update, :reset
        end

        with_default_permissions do
          denies :update, :reset
        end

        without_permissions do
          denies :update, :reset
        end
      end
    end

    with_scenarios %i[accessing_another_account accessing_a_user] do
      with_token_authentication do
        with_permissions %w[user.password.update] do
          denies :update
        end

        with_permissions %w[user.password.reset] do
          denies :reset
        end

        with_wildcard_permissions do
          denies :update, :reset
        end

        with_default_permissions do
          denies :update, :reset
        end

        without_permissions do
          denies :update, :reset
        end
      end
    end
  end

  with_role_authorization :environment do
    within_environment :self do
      with_scenarios %i[accessing_a_user] do
        with_token_authentication do
          with_wildcard_permissions do
            denies :update, :reset
          end

          with_default_permissions do
            denies :update, :reset
          end

          without_permissions do
            denies :update, :reset
          end
        end
      end
    end

    with_scenarios %i[accessing_a_user] do
      with_token_authentication do
        with_wildcard_permissions do
          denies :update, :reset
        end

        with_default_permissions do
          denies :update, :reset
        end

        without_permissions do
          denies :update, :reset
        end
      end
    end
  end

  with_role_authorization :product do
    with_scenarios %i[accessing_its_user] do
      with_token_authentication do
        with_wildcard_permissions do
          denies :update, :reset
        end

        with_default_permissions do
          denies :update, :reset
        end

        without_permissions do
          denies :update, :reset
        end
      end
    end

    with_scenarios %i[accessing_a_user] do
      with_token_authentication do
        with_wildcard_permissions do
          denies :update, :reset
        end

        with_default_permissions do
          denies :update, :reset
        end

        without_permissions do
          denies :update, :reset
        end
      end
    end
  end

  with_role_authorization :license do
    with_bearer_trait :with_owner do
      with_scenarios %i[accessing_its_owner] do
        with_license_authentication do
          with_wildcard_permissions do
            denies :update, :reset
          end

          with_default_permissions do
            denies :update, :reset
          end

          without_permissions do
            denies :update, :reset
          end
        end

        with_token_authentication do
          with_wildcard_permissions do
            denies :update, :reset
          end

          with_default_permissions do
            denies :update, :reset
          end

          without_permissions do
            denies :update, :reset
          end
        end
      end
    end

    with_scenarios %i[accessing_a_user] do
      with_license_authentication do
        with_wildcard_permissions do
          denies :update, :reset
        end

        with_default_permissions do
          denies :update, :reset
        end

        without_permissions do
          denies :update, :reset
        end
      end

      with_token_authentication do
        with_wildcard_permissions do
          denies :update, :reset
        end

        with_default_permissions do
          denies :update, :reset
        end

        without_permissions do
          denies :update, :reset
        end
      end
    end
  end

  with_role_authorization :user do
    with_scenarios %i[accessing_itself] do
      with_token_authentication do
        with_permissions %w[user.password.update] do
          without_token_permissions { denies :update }

          allows :update
        end

        with_permissions %w[user.password.reset] do
          without_token_permissions { denies :reset }

          allows :reset
        end

        with_wildcard_permissions do
          without_token_permissions { denies :update, :reset }

          allows :update, :reset
        end

        with_default_permissions do
          without_token_permissions { denies :update, :reset }

          allows :update, :reset
        end

        without_permissions do
          denies :update, :reset
        end

        with_bearer_trait :passwordless do
          without_account_protection { allows :reset }
          with_account_protection    { denies :reset }
        end
      end
    end

    with_scenarios %i[accessing_a_user] do
      with_token_authentication do
        with_permissions %w[user.password.update] do
          denies :update
        end

        with_permissions %w[user.password.reset] do
          denies :reset
        end

        with_wildcard_permissions do
          denies :update, :reset
        end

        with_default_permissions do
          denies :update, :reset
        end

        without_permissions do
          denies :update, :reset
        end
      end
    end
  end

  without_authorization do
    with_scenarios %i[accessing_a_user] do
      without_authentication do
        denies :update
        allows :reset
      end
    end
  end
end
